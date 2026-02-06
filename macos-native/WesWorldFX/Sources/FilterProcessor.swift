//
//  FilterProcessor.swift
//  WesWorld FX
//
//  Metal-accelerated filter processing using compute shaders
//

import Metal
import CoreVideo
import Accelerate
import simd

class FilterProcessor {
    
    private let device: MTLDevice
    private let commandQueue: MTLCommandQueue
    private let textureCache: CVMetalTextureCache
    
    // Compute pipeline states for each filter
    private var filterPipelines: [FilterType: MTLComputePipelineState] = [:]
        // Custom bulge pipeline (shared for all custom filters)
    private var customBulgePipeline: MTLComputePipelineState?
        // Grid overlay pipelines (filter-specific)
    private var gridPipelines: [FilterType: MTLComputePipelineState] = [:]
    private var defaultGridPipeline: MTLComputePipelineState?
    
    // Current filter
    var currentFilter: FilterType = .preset(.bulgeEyes)
    
    // Grid overlay toggle
    var showGrid: Bool = true
    
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
        // Load shader source from file system
        let fileManager = FileManager.default
        let currentDir = fileManager.currentDirectoryPath
        let possiblePaths = [
            "\(currentDir)/WesWorldFX/Metal/Shaders.metal",
            "\(currentDir)/macos-native/WesWorldFX/Metal/Shaders.metal",
            "/Users/wes/Sites/wesworld/ww-fx-dropout/macos-native/WesWorldFX/Metal/Shaders.metal"
        ]
        
        var shaderSource: String?
        for path in possiblePaths {
            if fileManager.fileExists(atPath: path) {
                if let source = try? String(contentsOfFile: path, encoding: .utf8) {
                    shaderSource = source
                    print("✓ FilterProcessor loaded shaders from: \(path)")
                    break
                }
            }
        }
        
        guard let shaderSource = shaderSource,
              let library = try? device.makeLibrary(source: shaderSource, options: nil) else {
            fatalError("Failed to create shader library")
        }
        
        // Create compute pipeline for each preset filter
        for presetFilter in PresetFilter.allCases {
            let functionName = presetFilter.metalFunctionName
            if let function = library.makeFunction(name: functionName) {
                do {
                    let pipeline = try device.makeComputePipelineState(function: function)
                    filterPipelines[.preset(presetFilter)] = pipeline
                } catch {
                    print("Failed to create pipeline for \(presetFilter): \(error)")
                }
            }
        }
        
        // Create pipeline for custom bulge filter
        if let customBulgeFunction = library.makeFunction(name: "custom_bulge") {
            do {
                customBulgePipeline = try device.makeComputePipelineState(function: customBulgeFunction)
                print("✓ Custom bulge pipeline created successfully")
            } catch {
                print("Failed to create custom bulge pipeline: \(error)")
            }
        } else {
            print("⚠️ Warning: custom_bulge shader function not found")
        }
        
        // Create grid overlay pipelines (filter-specific for preset filters)
        let gridPipelineMappings: [PresetFilter: String] = [
            // Ripple effects
            .complexRipple: "draw_grid_overlay_complex_ripple",
            .complexRippleV1: "draw_grid_overlay_complex_ripple_v1",
            .waterRipple: "draw_grid_overlay_water_ripple",
            .multiRipple: "draw_grid_overlay_multi_ripple",
            .multiRippleV1: "draw_grid_overlay_multi_ripple_v1",
            .gentleRipple: "draw_grid_overlay_gentle_ripple",

            // Eye & face effects
            .bulgeEyes: "draw_grid_overlay_bulge_eyes",
            .pinchCheeks: "draw_grid_overlay_pinch_cheeks",
            .elasticFace: "draw_grid_overlay_elastic_face",
            .smushFace: "draw_grid_overlay_smush_face",
            .squishFace: "draw_grid_overlay_squish_face",
            .squishFaceV1: "draw_grid_overlay_squish_face_v1",
            .stretchFace: "draw_grid_overlay_stretch_face",
            .stretchFaceV1: "draw_grid_overlay_stretch_face_v1",
            .warpFace: "draw_grid_overlay_warp_face",
            .warpFaceV1: "draw_grid_overlay_warp_face_v1",
            .wobbleFace: "draw_grid_overlay_wobble_face",

            // Distortion effects
            .funhouseMirror: "draw_grid_overlay_funhouse_mirror",
            .pincushion: "draw_grid_overlay_pincushion",
            .radialWobble: "draw_grid_overlay_radial_wobble",
            .ultimateDistortion: "draw_grid_overlay_ultimate_distortion",
            .lensDistortion: "draw_grid_overlay_lens_distortion",
            .lensDistortionV1: "draw_grid_overlay_lens_distortion_v1",
            .radialSqueeze: "draw_grid_overlay_radial_squeeze",
            .radialSqueezeV1: "draw_grid_overlay_radial_squeeze_v1",

            // Squeeze & stretch
            .squeezeHorizontal: "draw_grid_overlay_squeeze_horizontal",
            .squeezeHorizontalV1: "draw_grid_overlay_squeeze_horizontal_v1",
            .squeezeVertical: "draw_grid_overlay_squeeze_vertical",
            .squeezeVerticalV1: "draw_grid_overlay_squeeze_vertical_v1",
            .elasticStretch: "draw_grid_overlay_elastic_stretch",
            .elasticStretchV1: "draw_grid_overlay_elastic_stretch_v1",
            .funnySquash: "draw_grid_overlay_funny_squash",
            .funnyStretch: "draw_grid_overlay_funny_stretch",
            .funnyStretchV1: "draw_grid_overlay_funny_stretch_v1",

            // Other
            .upsideDown: "draw_grid_overlay_upside_down",
            .upsideDownV1: "draw_grid_overlay_upside_down_v1",
            .waveDistortion: "draw_grid_overlay_wave_distortion",
            .waveDistortionV1: "draw_grid_overlay_wave_distortion_v1"
        ]
        
        for (presetFilter, functionName) in gridPipelineMappings {
            if let gridFunction = library.makeFunction(name: functionName) {
                do {
                    gridPipelines[.preset(presetFilter)] = try device.makeComputePipelineState(function: gridFunction)
                } catch {
                    print("Failed to create grid pipeline for \(presetFilter): \(error)")
                }
            }
        }
        
        // Grid overlay for custom bulge filters
        if let customGridFunction = library.makeFunction(name: "draw_grid_overlay_custom_bulge") {
            do {
                let pipeline = try device.makeComputePipelineState(function: customGridFunction)
                gridPipelines[.custom(UUID())] = pipeline
            } catch {
                print("Failed to create custom bulge grid pipeline: \(error)")
            }
        }
        
        // Default grid pipeline for other filters (bulge_eyes style)
        if let defaultGridFunction = library.makeFunction(name: "draw_grid_overlay") {
            do {
                defaultGridPipeline = try device.makeComputePipelineState(function: defaultGridFunction)
            } catch {
                print("Failed to create default grid pipeline: \(error)")
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
            textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
                pixelFormat: sourceTexture.pixelFormat,
                width: sourceTexture.width,
                height: sourceTexture.height,
                mipmapped: false
            )
        }
        
        // Use source as starting point
        var processingTexture = sourceTexture
        
        // Apply filter using Metal compute shader (if not none)
        if currentFilter != .none {
            // Create output texture
            guard let outputTexture = createOutputTexture(matching: sourceTexture) else {
                print("FilterProcessor: Failed to create output texture")
                return sourceTexture
            }
            
            processingTexture = outputTexture
        } else {
            // For none filter, create a copy texture to apply grid on
            guard let copyTexture = createOutputTexture(matching: sourceTexture) else {
                return sourceTexture
            }
            
            // Copy source to output
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let blitEncoder = commandBuffer.makeBlitCommandEncoder() else {
                return sourceTexture
            }
            
            blitEncoder.copy(from: sourceTexture, to: copyTexture)
            blitEncoder.endEncoding()
            commandBuffer.commit()
            commandBuffer.waitUntilCompleted()
            
            processingTexture = copyTexture
        }
        
        // Execute compute shader for filter (if not none)
        if currentFilter != .none {
            guard let commandBuffer = commandQueue.makeCommandBuffer(),
                  let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
                print("FilterProcessor: Failed to create command buffer or encoder")
                return sourceTexture
            }
            
            // Get pipeline based on filter type
            var pipeline: MTLComputePipelineState? = nil
            if case .custom = currentFilter {
                // Use the custom bulge pipeline (stored with placeholder UUID)
                pipeline = filterPipelines[.custom(UUID())]
            } else {
                pipeline = filterPipelines[currentFilter]
            }
            
            guard let pipeline = pipeline else {
                return sourceTexture
            }
            
            computeEncoder.setComputePipelineState(pipeline)
            computeEncoder.setTexture(sourceTexture, index: 0)
            computeEncoder.setTexture(processingTexture, index: 1)
            
            // If custom bulge filter, set buffer with bulge points
            if case .custom(let filterId) = currentFilter,
               let customFilter = BulgeFilterManager.shared.getFilter(byId: filterId) {
                // Convert BulgePoint Swift structs to Metal-compatible format
                var metalPoints = customFilter.points.map { point in
                    // Create Metal-compatible struct (must match Metal shader)
                    return (point.x, point.y, point.radius, point.strength)
                }
                
                if !metalPoints.isEmpty {
                    computeEncoder.setBytes(&metalPoints, 
                                          length: metalPoints.count * MemoryLayout<(Float, Float, Float, Float)>.stride, 
                                          index: 0)
                    var pointCount = UInt32(metalPoints.count)
                    computeEncoder.setBytes(&pointCount, 
                                          length: MemoryLayout<UInt32>.size, 
                                          index: 1)
                }
            }
        
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
        }
        
        // Apply grid overlay to show filter deformation (when enabled)
        if showGrid {
            // Select the appropriate grid pipeline based on current filter
            var gridPipeline: MTLComputePipelineState? = nil
            if case .custom = currentFilter {
                gridPipeline = gridPipelines[.custom(UUID())]
            } else {
                gridPipeline = gridPipelines[currentFilter] ?? defaultGridPipeline
            }
            
            guard let gridPipeline = gridPipeline else {
                return processingTexture
            }
            
            guard let gridTexture = createOutputTexture(matching: processingTexture) else {
                return processingTexture
            }

            // Prefill gridTexture with the processed image
            if let blitCommandBuffer = commandQueue.makeCommandBuffer(),
               let blitEncoder = blitCommandBuffer.makeBlitCommandEncoder() {
                blitEncoder.copy(from: processingTexture, to: gridTexture)
                blitEncoder.endEncoding()
                blitCommandBuffer.commit()
                blitCommandBuffer.waitUntilCompleted()
            }

            guard let gridCommandBuffer = commandQueue.makeCommandBuffer(),
                  let gridEncoder = gridCommandBuffer.makeComputeCommandEncoder() else {
                return processingTexture
            }

            let threadGroupSize = MTLSize(width: 16, height: 16, depth: 1)
            let threadGroups = MTLSize(
                width: (sourceTexture.width + threadGroupSize.width - 1) / threadGroupSize.width,
                height: (sourceTexture.height + threadGroupSize.height - 1) / threadGroupSize.height,
                depth: 1
            )

            gridEncoder.setComputePipelineState(gridPipeline)
            gridEncoder.setTexture(processingTexture, index: 0)
            gridEncoder.setTexture(gridTexture, index: 1)
            
            // If custom bulge filter, pass bulge points to grid shader
            if case .custom(let filterId) = currentFilter,
               let customFilter = BulgeFilterManager.shared.getFilter(byId: filterId) {
                var metalPoints = customFilter.points.map { point in
                    return (point.x, point.y, point.radius, point.strength)
                }
                
                if !metalPoints.isEmpty {
                    gridEncoder.setBytes(&metalPoints, 
                                       length: metalPoints.count * MemoryLayout<(Float, Float, Float, Float)>.stride, 
                                       index: 0)
                    var pointCount = UInt32(metalPoints.count)
                    gridEncoder.setBytes(&pointCount, 
                                       length: MemoryLayout<UInt32>.size, 
                                       index: 1)
                }
            }
            
            gridEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
            gridEncoder.endEncoding()

            gridCommandBuffer.commit()
            gridCommandBuffer.waitUntilCompleted()

            return gridTexture
        }
        
        return processingTexture
    }
    
    private func createTexture(from pixelBuffer: CVPixelBuffer) -> MTLTexture? {
        let width = CVPixelBufferGetWidth(pixelBuffer)
        let height = CVPixelBufferGetHeight(pixelBuffer)
        let pixelFormat = CVPixelBufferGetPixelFormatType(pixelBuffer)
        
        // Try to get the best matching Metal pixel format
        var metalFormat: MTLPixelFormat = .bgra8Unorm
        
        switch pixelFormat {
        case kCVPixelFormatType_32BGRA:
            metalFormat = .bgra8Unorm
        case kCVPixelFormatType_32ARGB:
            metalFormat = .rgba8Unorm
        case kCVPixelFormatType_420YpCbCr8BiPlanarFullRange,
             kCVPixelFormatType_420YpCbCr8BiPlanarVideoRange:
            // For YUV, we need a separate conversion - for now use BGRA fallback
            metalFormat = .bgra8Unorm
        default:
            print("⚠️  Unknown pixel format: \(pixelFormat), trying BGRA")
            metalFormat = .bgra8Unorm
        }
        
        var textureRef: CVMetalTexture?
        let status = CVMetalTextureCacheCreateTextureFromImage(
            kCFAllocatorDefault,
            textureCache,
            pixelBuffer,
            nil,
            metalFormat,
            width,
            height,
            0,
            &textureRef
        )
        
        guard status == kCVReturnSuccess, let cvTexture = textureRef else {
            print("❌ Failed to create Metal texture from pixel buffer. Status: \(status), Format: \(pixelFormat)")
            return nil
        }
        
        guard let texture = CVMetalTextureGetTexture(cvTexture) else {
            print("❌ Failed to get texture from CVMetalTexture")
            return nil
        }
        
        return texture
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
    
    // MARK: - Custom Filter Processing
    
    /// Set the current filter type for processing
    public func setCurrentFilter(_ filter: FilterType) {
        currentFilter = filter
    }
    
    /// Process a texture with a custom bulge filter for live preview (non-blocking)
    /// - Parameters:
    ///   - texture: Source texture to process
    ///   - filter: Custom bulge filter with points
    /// - Returns: Processed texture with bulge effect applied
    public func processCustomBulgeAsync(_ texture: MTLTexture, with filter: CustomBulgeFilter) -> MTLTexture? {
        // Check pipeline first - don't create Metal objects if we can't process
        guard let pipeline = customBulgePipeline else {
            print("FilterProcessor: Custom bulge pipeline not available")
            return texture
        }
        
        guard let commandBuffer = commandQueue.makeCommandBuffer(),
              let computeEncoder = commandBuffer.makeComputeCommandEncoder() else {
            print("FilterProcessor: Failed to create command buffer or encoder")
            return texture
        }
        
        // Create output texture
        guard let outputTexture = createOutputTexture(matching: texture) else {
            return texture
        }
        
        // Setup compute shader
        computeEncoder.setComputePipelineState(pipeline)
        computeEncoder.setTexture(texture, index: 0)
        computeEncoder.setTexture(outputTexture, index: 1)
        
        // Prepare bulge points data for GPU
        var pointCount = UInt32(filter.points.count)
        computeEncoder.setBytes(&pointCount, length: MemoryLayout<UInt32>.size, index: 0)
        
        // Prepare point data as simple tuples (x, y, radius, strength)
        var bulgeData: [(Float, Float, Float, Float)] = []
        for point in filter.points {
            bulgeData.append((point.x, point.y, point.radius, point.strength))
        }
        
        // Pass bulge points (max 16 points)
        let maxPoints = min(bulgeData.count, 16)
        if maxPoints > 0 {
            computeEncoder.setBytes(bulgeData, length: maxPoints * MemoryLayout<(Float, Float, Float, Float)>.stride, index: 1)
        }
        
        // Dispatch threads
        let threadGroupSize = MTLSizeMake(16, 16, 1)
        let threadGroups = MTLSizeMake(
            (texture.width + threadGroupSize.width - 1) / threadGroupSize.width,
            (texture.height + threadGroupSize.height - 1) / threadGroupSize.height,
            1
        )
        
        computeEncoder.dispatchThreadgroups(threadGroups, threadsPerThreadgroup: threadGroupSize)
        computeEncoder.endEncoding()
        
        // Commit WITHOUT waiting - let it process in background
        commandBuffer.commit()
        // Don't call waitUntilCompleted() - this blocks the main thread!
        
        return outputTexture
    }
    
    /// Check if custom bulge processing is available
    public func isCustomBulgeAvailable() -> Bool {
        return customBulgePipeline != nil
    }
}