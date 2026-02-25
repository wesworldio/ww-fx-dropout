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
    // Grid overlay pipelines (filter-specific)
    private var gridPipelines: [FilterType: MTLComputePipelineState] = [:]
    private var customGridPipeline: MTLComputePipelineState?
    private var defaultGridPipeline: MTLComputePipelineState?
    private var simpleGridPipeline: MTLComputePipelineState?
    
    // Current filter
    var currentFilter: FilterType = .none
    
    // Grid overlay toggle
    var showGrid: Bool = false
    
    // Texture pool for reuse
    private var textureDescriptor: MTLTextureDescriptor?
    
    init(device: MTLDevice) {
        self.device = device
        
        guard let queue = device.makeCommandQueue() else {
            print("ERROR: Failed to create command queue")
            // Initialize with dummy values to allow object creation
            self.commandQueue = device.makeCommandQueue()!
            
            var dummyCache: CVMetalTextureCache?
            CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &dummyCache)
            self.textureCache = dummyCache!
            
            return
        }
        self.commandQueue = queue
        
        // Create texture cache
        var cache: CVMetalTextureCache?
        CVMetalTextureCacheCreate(kCFAllocatorDefault, nil, device, nil, &cache)
        guard let textureCache = cache else {
            print("ERROR: Failed to create texture cache")
            self.textureCache = cache!
            return
        }
        self.textureCache = textureCache
        
        setupFilterPipelines()
    }
    
    private func setupFilterPipelines() {
        // Try to load precompiled metallib first
        let bundleShaderPath = Bundle.main.path(forResource: "Shaders", ofType: "metallib")
        var library: MTLLibrary?
        
        // Try bundle metallib
        if let bundleShaderPath = bundleShaderPath {
            let libraryURL = URL(fileURLWithPath: bundleShaderPath)
            do {
                let libraryData = try Data(contentsOf: libraryURL)
                library = try libraryData.withUnsafeBytes { buffer -> MTLLibrary in
                    try device.makeLibrary(data: DispatchData(bytes: UnsafeRawBufferPointer(buffer)))
                }
                print("✓ FilterProcessor loaded metallib from bundle")
            } catch {
                print("⚠ Failed to load precompiled metallib: \(error)")
            }
        }
        
        // Fallback to runtime compilation
        if library == nil {
            let fileManager = FileManager.default
            let possiblePaths = [
                "\(fileManager.currentDirectoryPath)/WesWorldFX/Metal/Shaders.metal",
                "\(fileManager.currentDirectoryPath)/macos-native/WesWorldFX/Metal/Shaders.metal",
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
            
            if let shaderSource = shaderSource {
                do {
                    library = try device.makeLibrary(source: shaderSource, options: nil)
                    print("✓ FilterProcessor compiled shader library")
                } catch {
                    print("ERROR: Failed to compile shaders: \(error)")
                }
            } else {
                print("ERROR: No shader source found")
            }
        }
        
        // Use default library if all else fails
        if library == nil {
            print("⚠ Using default Metal library")
            library = device.makeDefaultLibrary()
        }
        
        guard let library = library else {
            print("ERROR: Could not load any shader library - filters will not work")
            return
        }
        
        // Create compute pipeline for each filter
        for filter in FilterType.allCases {
            let functionName = filter.metalFunctionName
            guard !functionName.isEmpty else {
                continue
            }
            if let function = library.makeFunction(name: functionName) {
                do {
                    let pipeline = try device.makeComputePipelineState(function: function)
                    filterPipelines[filter] = pipeline
                } catch {
                    print("⚠ Failed to create pipeline for \(filter): \(error)")
                }
            } else {
                print("⚠ Could not find function '\(functionName)' in library")
            }
        }

        // Create grid overlay pipelines (filter-specific)
        let gridPipelineMappings: [FilterType: String] = [
            // Ripple effects
            .complexRipple: "draw_grid_overlay_complex_ripple",
            .complexRippleV1: "draw_grid_overlay_complex_ripple_v1",
            .waterRipple: "draw_grid_overlay_water_ripple",
            .multiRipple: "draw_grid_overlay_multi_ripple",
            .multiRippleV1: "draw_grid_overlay_multi_ripple_v1",
            .gentleRipple: "draw_grid_overlay_gentle_ripple",

            // Eye & face effects
            // .bulgeEyes: "draw_grid_overlay_bulge_eyes",
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
                    gridPipelines[presetFilter] = try device.makeComputePipelineState(function: gridFunction)
                } catch {
                    print("Failed to create grid pipeline for \(presetFilter): \(error)")
                }
            }
        }
        
        // Grid overlay for custom bulge filters
        if let customGridFunction = library.makeFunction(name: "draw_grid_overlay_custom_bulge") {
            do {
                customGridPipeline = try device.makeComputePipelineState(function: customGridFunction)
                print("✓ Custom bulge grid pipeline created successfully")
            } catch {
                print("Failed to create custom bulge grid pipeline: \(error)")
            }
        }
        
        // Default grid pipeline for other filters (bulge_eyes style)
        if let defaultGridFunction = library.makeFunction(name: "draw_grid_overlay") {
            do {
                defaultGridPipeline = try device.makeComputePipelineState(function: defaultGridFunction)
                print("✓ Default grid pipeline created successfully")
            } catch {
                print("Failed to create default grid pipeline: \(error)")
            }
        }
        
        // Simple universal grid overlay for any filter that doesn't have a specific grid overlay
        if let simpleGridFunction = library.makeFunction(name: "draw_simple_grid_overlay") {
            do {
                simpleGridPipeline = try device.makeComputePipelineState(function: simpleGridFunction)
                print("✓ Simple grid overlay pipeline created successfully")
            } catch {
                print("Failed to create simple grid overlay pipeline: \(error)")
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
                // Use the custom bulge pipeline
                pipeline = customBulgePipeline
            } else {
                pipeline = filterPipelines[currentFilter]
            }
            
            guard let pipeline = pipeline else {
                computeEncoder.endEncoding()
                print("FilterProcessor: Pipeline not found for filter \(currentFilter)")
                return sourceTexture
            }
            
            computeEncoder.setComputePipelineState(pipeline)
            computeEncoder.setTexture(sourceTexture, index: 0)
            computeEncoder.setTexture(processingTexture, index: 1)
            
            // No custom bulge points in native app build
        
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
                gridPipeline = customGridPipeline
            } else {
                gridPipeline = gridPipelines[currentFilter] ?? defaultGridPipeline ?? simpleGridPipeline
            }
            
            guard let gridPipeline = gridPipeline else {
                print("FilterProcessor: No grid pipeline available for filter")
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
                print("FilterProcessor: Failed to create grid command buffer or encoder")
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
            
            // No custom bulge points in native app build
            
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
    
    // MARK: - Filter Processing

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
        
        // Create output texture - if this fails, must end encoder before returning
        guard let outputTexture = createOutputTexture(matching: texture) else {
            computeEncoder.endEncoding()
            print("FilterProcessor: Failed to create output texture for custom bulge")
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