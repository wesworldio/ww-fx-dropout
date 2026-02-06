//
//  FilterType.swift
//  WesWorld FX
//
//  Filter definitions matching the original web app
//

import Foundation

public enum FilterType: Equatable, Hashable {
    case none
    case preset(PresetFilter)
    case custom(UUID) // Custom bulge filter by ID
    
    var displayName: String {
        switch self {
        case .none:
            return "None (Original)"
        case .preset(let preset):
            return preset.rawValue
        case .custom(let id):
            if let filter = BulgeFilterManager.shared.getFilter(byId: id) {
                return "💎 \(filter.name)"
            }
            return "Custom Filter"
        }
    }
    
    var metalFunctionName: String {
        switch self {
        case .none:
            return ""
        case .preset(let preset):
            return preset.metalFunctionName
        case .custom:
            return "custom_bulge"
        }
    }
    
    var isCustom: Bool {
        if case .custom = self { return true }
        return false
    }
    
    // Helper to get all available filters (presets + custom)
    public static func allAvailableFilters() -> [FilterType] {
        var filters: [FilterType] = [.none]
        filters.append(contentsOf: PresetFilter.allCases.map { .preset($0) })
        filters.append(contentsOf: BulgeFilterManager.shared.getAllFilters().map { .custom($0.id) })
        return filters
    }
    
    // Hashable conformance
    public func hash(into hasher: inout Hasher) {
        switch self {
        case .none:
            hasher.combine(0)
        case .preset(let preset):
            hasher.combine(1)
            hasher.combine(preset)
        case .custom(let id):
            hasher.combine(2)
            hasher.combine(id)
        }
    }
    
    public static func == (lhs: FilterType, rhs: FilterType) -> Bool {
        switch (lhs, rhs) {
        case (.none, .none):
            return true
        case (.preset(let lhsPreset), .preset(let rhsPreset)):
            return lhsPreset == rhsPreset
        case (.custom(let lhsId), .custom(let rhsId)):
            return lhsId == rhsId
        default:
            return false
        }
    }
}

public enum PresetFilter: String, CaseIterable {
    // Favorites
    case bulgeEyes = "Bulge Eyes"
    case funhouseMirror = "Funhouse Mirror"
    case funnySquash = "Funny Squash"
    case pinchCheeks = "Pinch Cheeks"
    case pincushion = "Pincushion"
    case radialWobble = "Radial Wobble"
    case ultimateDistortion = "Ultimate Distortion"
    case waterRipple = "Water Ripple"
    case wobbleFace = "Wobble Face"
    
    // Distortion
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
    
    var metalFunctionName: String {
        switch self {
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
