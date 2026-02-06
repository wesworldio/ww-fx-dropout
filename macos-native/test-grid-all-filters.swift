#!/usr/bin/env swift
//
//  Test Grid Visualizations for All Filters
//  Generates grid overlay images for each filter on a black background
//

import Foundation
import Metal
import MetalKit
import CoreGraphics
import ImageIO
import UniformTypeIdentifiers

// Filter definitions
enum FilterType: String, CaseIterable {
    case none = "None (Original)"
    case bulgeEyes = "Bulge Eyes"
    case funhouseMirror = "Funhouse Mirror"
    case funnySquash = "Funny Squash"
    case pinchCheeks = "Pinch Cheeks"
    case pincushion = "Pincushion"
    case radialWobble = "Radial Wobble"
    case ultimateDistortion = "Ultimate Distortion"
    case waterRipple = "Water Ripple"
    case wobbleFace = "Wobble Face"
    case complexRipple = "Complex Ripple"
    case complexRippleV1 = "Complex Ripple V1"
    case elasticFace = "Elastic Face"
    case elasticStretch = "Elastic Stretch"
    case elasticStretchV1 = "Elastic Stretch V1"
    case funnyStretch = "Funny Stretch"
    case funnyStretchV1 = "Funny Stretch V1"
    case gentleRipple = "Gentle Ripple"
    case lensDistortion = "Lens Distortion"
    case lensDistortionV1 = "Lens Distortion V1"
    case multiRipple = "Multi Ripple"
    case multiRippleV1 = "Multi Ripple V1"
    case radialSqueeze = "Radial Squeeze"
    case radialSqueezeV1 = "Radial Squeeze V1"
    case smushFace = "Smush Face"
    case squeezeHorizontal = "Squeeze Horizontal"
    case squeezeHorizontalV1 = "Squeeze Horizontal V1"
    case squeezeVertical = "Squeeze Vertical"
    case squeezeVerticalV1 = "Squeeze Vertical V1"
    case squishFace = "Squish Face"
    case squishFaceV1 = "Squish Face V1"
    case stretchFace = "Stretch Face"
    case stretchFaceV1 = "Stretch Face V1"
    case upsideDown = "Upside Down"
    case upsideDownV1 = "Upside Down V1"
    case warpFace = "Warp Face"
    case warpFaceV1 = "Warp Face V1"
    case waveDistortion = "Wave Distortion"
    case waveDistortionV1 = "Wave Distortion V1"
    
    var shaderName: String {
        switch self {
        case .none: return "none"
        case .bulgeEyes: return "bulge_eyes"
        case .funhouseMirror: return "funhouse_mirror"
        case .funnySquash: return "funny_squash"
        case .pinchCheeks: return "pinch_cheeks"
        case .pincushion: return "pincushion"
        case .radialWobble: return "radial_wobble"
        case .ultimateDistortion: return "ultimate_distortion"
        case .waterRipple: return "water_ripple"
        case .wobbleFace: return "wobble_face"
        case .complexRipple: return "complex_ripple"
        case .complexRippleV1: return "complex_ripple_v1"
        case .elasticFace: return "elastic_face"
        case .elasticStretch: return "elastic_stretch"
        case .elasticStretchV1: return "elastic_stretch_v1"
        case .funnyStretch: return "funny_stretch"
        case .funnyStretchV1: return "funny_stretch_v1"
        case .gentleRipple: return "gentle_ripple"
        case .lensDistortion: return "lens_distortion"
        case .lensDistortionV1: return "lens_distortion_v1"
        case .multiRipple: return "multi_ripple"
        case .multiRippleV1: return "multi_ripple_v1"
        case .radialSqueeze: return "radial_squeeze"
        case .radialSqueezeV1: return "radial_squeeze_v1"
        case .smushFace: return "smush_face"
        case .squeezeHorizontal: return "squeeze_horizontal"
        case .squeezeHorizontalV1: return "squeeze_horizontal_v1"
        case .squeezeVertical: return "squeeze_vertical"
        case .squeezeVerticalV1: return "squeeze_vertical_v1"
        case .squishFace: return "squish_face"
        case .squishFaceV1: return "squish_face_v1"
        case .stretchFace: return "stretch_face"
        case .stretchFaceV1: return "stretch_face_v1"
        case .upsideDown: return "upside_down"
        case .upsideDownV1: return "upside_down_v1"
        case .warpFace: return "warp_face"
        case .warpFaceV1: return "warp_face_v1"
        case .waveDistortion: return "wave_distortion"
        case .waveDistortionV1: return "wave_distortion_v1"
        }
    }
}

print("🔬 Testing Grid Visualizations for All Filters")
print(String(repeating: "=", count: 60))

// Setup Metal
guard let device = MTLCreateSystemDefaultDevice() else {
    print("❌ Failed to create Metal device")
    exit(1)
}

guard let commandQueue = device.makeCommandQueue() else {
    print("❌ Failed to create command queue")
    exit(1)
}

// Load shader library
let libraryPath = "/Users/wes/Sites/wesworld/ww-fx-dropout/macos-native/Shaders.metallib"
let libraryURL = URL(fileURLWithPath: libraryPath)
guard let library = try? device.makeLibrary(URL: libraryURL) else {
    print("❌ Failed to load shader library from \(libraryPath)")
    exit(1)
}

print("✓ Metal device initialized")
print("✓ Shader library loaded")

// Create output directory
let outputDir = "/Users/wes/Sites/wesworld/ww-fx-dropout/filter-grid-test-output"
let fileManager = FileManager.default
try? fileManager.createDirectory(atPath: outputDir, withIntermediateDirectories: true)

print("✓ Output directory: \(outputDir)")
print()

// Image dimensions
let width = 1280
let height = 720

// Create black input texture
let textureDescriptor = MTLTextureDescriptor.texture2DDescriptor(
    pixelFormat: .bgra8Unorm,
    width: width,
    height: height,
    mipmapped: false
)
textureDescriptor.usage = [.shaderRead, .shaderWrite]

guard let blackTexture = device.makeTexture(descriptor: textureDescriptor) else {
    print("❌ Failed to create black texture")
    exit(1)
}

// Fill with black
let blackPixels = [UInt8](repeating: 0, count: width * height * 4)
blackTexture.replace(region: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0,
                     withBytes: blackPixels,
                     bytesPerRow: width * 4)

// Setup grid overlay pipelines
var gridPipelines: [FilterType: MTLComputePipelineState] = [:]
var defaultGridPipeline: MTLComputePipelineState?

// Try to load filter-specific grid shaders for ALL filters
let gridMappings: [(FilterType, String)] = [
    (.complexRipple, "draw_grid_overlay_complex_ripple"),
    (.complexRippleV1, "draw_grid_overlay_complex_ripple_v1"),
    (.waterRipple, "draw_grid_overlay_water_ripple"),
    (.multiRipple, "draw_grid_overlay_multi_ripple"),
    (.multiRippleV1, "draw_grid_overlay_multi_ripple_v1"),
    (.gentleRipple, "draw_grid_overlay_gentle_ripple"),
    (.bulgeEyes, "draw_grid_overlay_bulge_eyes"),
    (.pinchCheeks, "draw_grid_overlay_pinch_cheeks"),
    (.elasticFace, "draw_grid_overlay_elastic_face"),
    (.smushFace, "draw_grid_overlay_smush_face"),
    (.squishFace, "draw_grid_overlay_squish_face"),
    (.squishFaceV1, "draw_grid_overlay_squish_face_v1"),
    (.stretchFace, "draw_grid_overlay_stretch_face"),
    (.stretchFaceV1, "draw_grid_overlay_stretch_face_v1"),
    (.warpFace, "draw_grid_overlay_warp_face"),
    (.warpFaceV1, "draw_grid_overlay_warp_face_v1"),
    (.wobbleFace, "draw_grid_overlay_wobble_face"),
    (.funhouseMirror, "draw_grid_overlay_funhouse_mirror"),
    (.pincushion, "draw_grid_overlay_pincushion"),
    (.radialWobble, "draw_grid_overlay_radial_wobble"),
    (.ultimateDistortion, "draw_grid_overlay_ultimate_distortion"),
    (.lensDistortion, "draw_grid_overlay_lens_distortion"),
    (.lensDistortionV1, "draw_grid_overlay_lens_distortion_v1"),
    (.radialSqueeze, "draw_grid_overlay_radial_squeeze"),
    (.radialSqueezeV1, "draw_grid_overlay_radial_squeeze_v1"),
    (.squeezeHorizontal, "draw_grid_overlay_squeeze_horizontal"),
    (.squeezeHorizontalV1, "draw_grid_overlay_squeeze_horizontal_v1"),
    (.squeezeVertical, "draw_grid_overlay_squeeze_vertical"),
    (.squeezeVerticalV1, "draw_grid_overlay_squeeze_vertical_v1"),
    (.elasticStretch, "draw_grid_overlay_elastic_stretch"),
    (.elasticStretchV1, "draw_grid_overlay_elastic_stretch_v1"),
    (.funnySquash, "draw_grid_overlay_funny_squash"),
    (.funnyStretch, "draw_grid_overlay_funny_stretch"),
    (.funnyStretchV1, "draw_grid_overlay_funny_stretch_v1"),
    (.upsideDown, "draw_grid_overlay_upside_down"),
    (.upsideDownV1, "draw_grid_overlay_upside_down_v1"),
    (.waveDistortion, "draw_grid_overlay_wave_distortion"),
    (.waveDistortionV1, "draw_grid_overlay_wave_distortion_v1")
]

for (filterType, functionName) in gridMappings {
    if let function = library.makeFunction(name: functionName),
       let pipeline = try? device.makeComputePipelineState(function: function) {
        gridPipelines[filterType] = pipeline
        print("✓ Loaded grid shader: \(functionName)")
    }
}

// Load default grid overlay
if let function = library.makeFunction(name: "draw_grid_overlay"),
   let pipeline = try? device.makeComputePipelineState(function: function) {
    defaultGridPipeline = pipeline
    print("✓ Loaded default grid shader")
}

print()
print("Processing filters...")
print(String(repeating: "-", count: 60))

var successCount = 0
var failCount = 0

// Test each filter
for filter in FilterType.allCases {
    let filterName = filter.rawValue
    let filename = filterName.replacingOccurrences(of: " ", with: "_")
        .replacingOccurrences(of: "(", with: "")
        .replacingOccurrences(of: ")", with: "")
        .lowercased()
    
    // Skip "None" filter
    if filter == .none {
        print("⊘ \(filterName) - Skipped")
        continue
    }
    
    // Create output texture
    guard let outputTexture = device.makeTexture(descriptor: textureDescriptor) else {
        print("❌ \(filterName) - Failed to create output texture")
        failCount += 1
        continue
    }
    
    // Get the appropriate grid pipeline
    let gridPipeline = gridPipelines[filter] ?? defaultGridPipeline
    
    guard let pipeline = gridPipeline else {
        print("❌ \(filterName) - No grid pipeline available")
        failCount += 1
        continue
    }
    
    // Create command buffer and encoder
    guard let commandBuffer = commandQueue.makeCommandBuffer(),
          let encoder = commandBuffer.makeComputeCommandEncoder() else {
        print("❌ \(filterName) - Failed to create command buffer/encoder")
        failCount += 1
        continue
    }
    
    // Setup grid overlay
    encoder.setComputePipelineState(pipeline)
    encoder.setTexture(blackTexture, index: 0)
    encoder.setTexture(outputTexture, index: 1)
    
    // Grid parameters
    var gridSpacing: Float = 40.0
    var gridThickness: Float = 2.0
    var intensity: Float = 1.0
    var centerX: Float = Float(width) / 2.0
    var centerY: Float = Float(height) / 2.0
    
    encoder.setBytes(&gridSpacing, length: MemoryLayout<Float>.size, index: 0)
    encoder.setBytes(&gridThickness, length: MemoryLayout<Float>.size, index: 1)
    encoder.setBytes(&intensity, length: MemoryLayout<Float>.size, index: 2)
    encoder.setBytes(&centerX, length: MemoryLayout<Float>.size, index: 3)
    encoder.setBytes(&centerY, length: MemoryLayout<Float>.size, index: 4)
    
    // Dispatch
    let threadsPerGroup = MTLSize(width: 16, height: 16, depth: 1)
    let threadgroups = MTLSize(
        width: (width + threadsPerGroup.width - 1) / threadsPerGroup.width,
        height: (height + threadsPerGroup.height - 1) / threadsPerGroup.height,
        depth: 1
    )
    encoder.dispatchThreadgroups(threadgroups, threadsPerThreadgroup: threadsPerGroup)
    encoder.endEncoding()
    
    commandBuffer.commit()
    commandBuffer.waitUntilCompleted()
    
    // Save output to PNG
    let outputPath = "\(outputDir)/\(filename).png"
    if savePNG(texture: outputTexture, to: outputPath) {
        print("✓ \(filterName) -> \(filename).png")
        successCount += 1
    } else {
        print("❌ \(filterName) - Failed to save PNG")
        failCount += 1
    }
}

print(String(repeating: "-", count: 60))
print()
print("✅ Test Complete!")
print("   Success: \(successCount)")
print("   Failed: \(failCount)")
print("   Output: \(outputDir)")
print()

// Helper function to save texture as PNG
func savePNG(texture: MTLTexture, to path: String) -> Bool {
    let width = texture.width
    let height = texture.height
    let rowBytes = width * 4
    let imageBytes = rowBytes * height
    
    var imageData = [UInt8](repeating: 0, count: imageBytes)
    texture.getBytes(&imageData,
                     bytesPerRow: rowBytes,
                     from: MTLRegionMake2D(0, 0, width, height),
                     mipmapLevel: 0)
    
    // Create CGImage
    guard let dataProvider = CGDataProvider(data: Data(imageData) as CFData) else {
        return false
    }
    
    let colorSpace = CGColorSpaceCreateDeviceRGB()
    let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedFirst.rawValue | CGBitmapInfo.byteOrder32Little.rawValue)
    
    guard let cgImage = CGImage(
        width: width,
        height: height,
        bitsPerComponent: 8,
        bitsPerPixel: 32,
        bytesPerRow: rowBytes,
        space: colorSpace,
        bitmapInfo: bitmapInfo,
        provider: dataProvider,
        decode: nil,
        shouldInterpolate: false,
        intent: .defaultIntent
    ) else {
        return false
    }
    
    // Save as PNG
    let url = URL(fileURLWithPath: path)
    guard let destination = CGImageDestinationCreateWithURL(url as CFURL, UTType.png.identifier as CFString, 1, nil) else {
        return false
    }
    
    CGImageDestinationAddImage(destination, cgImage, nil)
    return CGImageDestinationFinalize(destination)
}
