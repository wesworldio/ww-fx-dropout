//
//  MetalRenderer.swift
//  WesWorld FX
//
//  Metal-accelerated rendering for maximum FPS
//

import MetalKit

class MetalRenderer: NSObject, MTKViewDelegate {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private var currentTexture: MTLTexture?
    private let textureCache: CVMetalTextureCache
    
    // Render pipeline
    private var pipelineState: MTLRenderPipelineState!
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
    }
    
    private func setupPipeline(view: MTKView) {
        // Load shader source from bundle or filesystem
        var shaderSource: String?

        if let shaderURL = Bundle.main.url(forResource: "Shaders", withExtension: "metal"),
           let source = try? String(contentsOf: shaderURL, encoding: .utf8) {
            shaderSource = source
            print("✓ MetalRenderer loaded shaders from bundle: \(shaderURL.path)")
        } else {
            let fileManager = FileManager.default
            let currentDir = fileManager.currentDirectoryPath
            let possiblePaths = [
                "\(currentDir)/WesWorldFX/Metal/Shaders.metal",
                "\(currentDir)/macos-native/WesWorldFX/Metal/Shaders.metal",
                "/Users/wes/Sites/wesworld/ww-fx-dropout/macos-native/WesWorldFX/Metal/Shaders.metal"
            ]

            for path in possiblePaths {
                if fileManager.fileExists(atPath: path),
                   let source = try? String(contentsOfFile: path, encoding: .utf8) {
                    shaderSource = source
                    print("✓ MetalRenderer loaded shaders from: \(path)")
                    break
                }
            }
        }

        guard let shaderSource = shaderSource else {
            fatalError("Failed to load shader source file")
        }
        
        print("Loaded shader source, length: \(shaderSource.count)")
        
        // Create shader library from source
        do {
            let library = try device.makeLibrary(source: shaderSource, options: nil)
            print("Shader library created successfully")
            
            guard let vertexFunction = library.makeFunction(name: "vertexShader"),
                  let fragmentFunction = library.makeFunction(name: "fragmentShader") else {
                fatalError("Failed to find shader functions")
            }
            
            // Create pipeline descriptor
            let pipelineDescriptor = MTLRenderPipelineDescriptor()
            pipelineDescriptor.vertexFunction = vertexFunction
            pipelineDescriptor.fragmentFunction = fragmentFunction
            pipelineDescriptor.colorAttachments[0].pixelFormat = view.colorPixelFormat
            
            pipelineState = try device.makeRenderPipelineState(descriptor: pipelineDescriptor)
        } catch {
            print("METAL SHADER ERROR: \(error)")
            fatalError("Failed to create pipeline: \(error)")
        }
    }
    
    private func setupVertexBuffer() {
        let size = vertices.count * MemoryLayout<Float>.size
        vertexBuffer = device.makeBuffer(bytes: vertices, length: size, options: [])
    }
    
    func updateTexture(_ texture: MTLTexture) {
        if currentTexture == nil {
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
        
        guard let texture = currentTexture else {
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
        renderEncoder.setRenderPipelineState(pipelineState)
        renderEncoder.setVertexBuffer(vertexBuffer, offset: 0, index: 0)
        renderEncoder.setFragmentTexture(texture, index: 0)
        renderEncoder.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        renderEncoder.endEncoding()
        
        commandBuffer.present(drawable)
        commandBuffer.commit()
    }
}
