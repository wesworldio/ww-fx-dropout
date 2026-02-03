//
//  FilterProcessor.swift
//  WesWorld FX
//
//  Metal-accelerated filter processing using compute shaders
//

import Metal
import CoreVideo
import Accelerate

class FilterProcessor {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureCache: CVMetalTextureCache
    
    // Compute pipeline states for each filter
    private var filterPipelines: [FilterType: MTLComputePipelineState] = [:]
    
    // Current filter
    var currentFilter: FilterType = .none
    
    // Texture pool for reuse
    private var textureDescriptor: MTLTextureDescriptor?
    
    init(device: MTLDevice) {
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
        
        setupFilterPipelines()
    }
    
    private func setupFilterPipelines() {
        // Load shader source from bundle
        guard let shaderURL = Bundle.main.url(forResource: "Shaders", withExtension: "metal"),
              let shaderSource = try? String(contentsOf: shaderURL, encoding: .utf8),
              let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            fatalError("Failed to create shader library")
        }
        
        // Create compute pipeline for each filter
        for filterType in FilterType.allCases {
            if filterType == .none { continue }
            
            let functionName = filterType.metalFunctionName
            if let function = library.makeFunction(name: functionName) {
                do {
                    let pipeline = try device.makeComputePipelineState(function: function)
                    filterPipelines[filterType] = pipeline
                } catch {
                    print("Failed to create pipeline for \(filterType): \(error)")
                }
            }
        }
    }
    
    func processFrame(pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        // Convert CVPixelBuffer to Metal texture
        guard let sourceTexture = createTexture(from: pixelBuffer) else {
            print("FilterProcessor: Failed to create texture from pixel buffer")
            return nil
        }
        
        // Log first frame
        if textureDescriptor == nil {
            print("FilterProcessor: First frame processing, texture size: \(sourceTexture.width)x\(sourceTexture.height)")
        }
        
        // If no filter, return source texture
        if currentFilter == .none {
            return sourceTexture
        }
        
        // Apply filter using Metal compute shader
        guard let pipeline = filterPipelines[currentFilter] else {
            print("FilterProcessor: No pipeline for filter \(currentFilter)")
            return sourceTexture
        }
        
        // Create output texture
        guard let outputTexture = createOutputTexture(matching: sourceTexture) else {
            print("FilterProcessor: Failed to create output texture")
            return sourceTexture
        }
        
        // Execute compute shader
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("FilterProcessor: Failed to create command buffer or encoder")
            return sourceTexture
        }
        
        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setTexture(sourceTexture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        // Calculate thread groups
        let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
        let threadGroups = MTLSize(
            width: (sourceTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            height: (sourceTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            depth: 1
        )
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        commandBuffer.commit()
        commandBuffer.waitUntilCompleted()
        
        return outputTexture
    }
    
    private func createTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        
        var textureRef: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            .bgra8Unorm,
            width,
            height,
            0,
            &textureRef
        )
        
        guard status == kCVReturnSuccess, let cvTexture = textureRef else {
            return nil
        }
        
        return CVMetalTextureGetTexture(cvTexture)
    }
    
    private func createOutputTexture(matching sourceTexture: MTLTexture) -> MTLTexture? {
        let descriptor = MTLTextureDescriptor.texture2DDescriptor(
            pixelFormat: sourceTexture.pixelFormat,
            width: sourceTexture.width,
            height: sourceTexture.height,
            mipmapped: false
        )
        descriptor.usage = [.shaderWrite, .shaderRead]
        
        return device.makeTexture(descriptor: descriptor)
    }
}

