//
//  MetalRenderer.swift
//  WesWorld FX
//
//  Metal-accelerated rendering for maximum FPS
//

import MetalKit
import Dispatch

class MetalRenderer: NSObject, MTKViewDelegate {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var currentTexture: MTLTexture?
    private let textureCache: CVMetalTextureCache
    private let textureLock = NSLock()
    
    // Performance tracking
    private var frameCount: Int = 0
    private var lastLogTime: Date = Date()
    
    // Render pipeline
        private var pipelineState: MTLRenderPipelineState?
    private var vertexBuffer: MTLBuffer!
    
    // Vertices for fullscreen quad
    private let vertices: [Float] = [
        // Positions    // TexCoords
        -1.0,  1.0,     0.0, 0.0,  // Top-left
        -1.0, -1.0,     0.0, 1.0,  // Bottom-left
         1.0, -1.0,     1.0, 1.0,  // Bottom-right
         
        -1.0,  1.0,     0.0, 0.0,  // Top-left
         1.0, -1.0,     1.0, 1.0,  // Bottom-right
         1.0,  1.0,     1.0, 0.0,  // Top-right
    ]
    
    init(device: MTLDevice, view: MTKView) {
        self.device = device
        
        guard let queue = device.makeCommandQueue() else {
            fatalError("Failed to create command queue")
        }
        self.commandQueue = queue
        
        // Create texture cache
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        guard let textureCache = cache else {
            fatalError("Failed to create texture cache")
        }
        self.textureCache = textureCache
        
        super.init()
        
        setupPipeline(view: view)
        setupVertexBuffer()
        
        if pipelineState != nil {
            print("✓ MetalRenderer initialized successfully")
        } else {
            print("⚠ MetalRenderer: Failed to initialize render pipeline")
        }
    }
    
    private func setupPipeline(view: MTKView) {
        // Load shader library from precompiled metallib file
        // Try multiple paths for shader library
        let shaderPaths = [
            Bundle.main.path(forResource: "Shaders", ofType: "metallib"),  // In app bundle
            Bundle.main.url(forResource: "Shaders", withExtension: "metallib")?.path,  // Alternative
            "/Users/wes/Sites/wesworld/ww-fx-dropout/macos-native/WesWorldFX.app/Contents/Resources/Shaders.metallib"  // Direct path
        ].compactMap { $0 }
        
        var library: MTLLibrary?
        
        // Try bundle first
        if let bundleShaderPath = shaderPaths.first {
            let libraryURL = URL(fileURLWithPath: bundleShaderPath)
            do {
                let libraryData = try Data(contentsOf: libraryURL)
                // Use dispatch_data for Metal library loading
                let dispatchData = libraryData.withUnsafeBytes { buffer -> DispatchData in
                    return DispatchData(bytes: UnsafeRawBufferPointer(buffer))
                }
                library = try device.makeLibrary(data: dispatchData)
                print("✓ Shaders loaded successfully")
            } catch {
                print("⚠ Failed to load precompiled shaders: \(error)")
            }
        }
        
        // Fall back to default library if needed
        if library == nil {
            print("⚠ Using default Metal library")
            library = device.makeDefaultLibrary()
        }
        
        guard let library = library else {
            print("ERROR: Failed to load shader library - cannot render")
            return
        }
        
        print("Shader library loaded successfully")
        
        guard let vertexFunction = library.makeFunction(name: "vertexShader"),
              let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
            print("ERROR: Failed to find shader functions in library")
            print("  vertexShader found: \(library.makeFunction(name: "vertexShader") != nil)")
            print("  fragmentShader found: \(library.makeFunction(name: "fragmentShader") != nil)")
            print("  Available functions: \(library.functionNames)")
            return
        }
        
        // Create pipeline descriptor
        let pipelineDescriptor = MTLRenderPipelineDescriptor()
        pipelineDescriptor.vertexFunction = vertexFunction
        pipelineDescriptor.fragmentFunction = fragmentFunction
        pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
        
        do {
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
            print("✓ Pipeline state created successfully")
        } catch {
            print("ERROR: Failed to create render pipeline: \(error)")
        }
    }
    
    private func setupVertexBuffer() {
        let size = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: size, options: [])
    }
    
    func updateTexture(_ texture: MTLTexture) {
        textureLock.lock()
        defer { textureLock.unlock() }
        
        if currentTexture == nil {
            DiagnosticLogger.shared.logCameraStatus(
                status: "First texture received",
                details: [
                    "Resolution": "\(texture.width)x\(texture.height)",
                    "Format": "\(texture.pixelFormat)"
                ]
            )
            print("MetalRenderer: First texture received! Size: \(texture.width)x\(texture.height)")
        }
        currentTexture = texture
    }
    
    // MARK: - MTKViewDelegate
    
    func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        // Handle resize if needed
    }
    
    func draw(in view: MTKView) {
        guard let drawable = view.currentDrawable,
              let renderPassDescriptor = view.currentRenderPassDescriptor else {
            return
        }
        
        textureLock.lock()
        let textureToRender = currentTexture
        textureLock.unlock()
        
        guard let texture = textureToRender else {
            // No texture yet, just clear the screen
            if let commandBuffer = commandQueue.makeCommandBuffer(),
               let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) {
                renderEncoder.endEncoding()
                commandBuffer.present(drawable)
                commandBuffer.commit()
            }
            return
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let renderEncoder = commandBuffer.makeRenderCommandEncoder(descriptor: renderPassDescriptor) else {
            return
        }
        
        // Draw textured quad
        // Draw textured quad - only if pipeline state is available
        if let pipelineState = pipelineState {
            renderEncoder.setRenderPipelineState(pipelineState)
            renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
            renderEncoder.setFragmentTexture(texture, index: 0)
            renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        } else {
            print("WARNING: Pipeline state not available, skipping render")
        }
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
        
        // Log performance metrics every 5 seconds
        frameCount += 1
        let elapsed = Date().timeIntervalSince(lastLogTime)
        if elapsed >= 5.0 {
            let fps = Double(frameCount) / elapsed
            DiagnosticLogger.shared.logPerformance(
                operation: "Frame Render",
                duration: (1000.0 / fps),
                details: [
                    "FPS": String(format: "%.1f", fps),
                    "Frames": frameCount,
                    "Texture": "\(texture.width)x\(texture.height)"
                ]
            )
            frameCount = 0
            lastLogTime = Date()
        }
    }
}
