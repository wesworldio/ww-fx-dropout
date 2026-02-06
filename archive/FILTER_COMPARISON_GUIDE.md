# Filter Comparison Guide - V1 (Original) vs V2 (Adjusted)

This document helps you compare the original and adjusted filter versions.

## How to Test

In the filter dropdown, you'll now see both versions of each adjusted filter:
- **Standard names** (e.g., "upside_down") = V2 (NEW - adjusted version)
- **Names with "_v1" suffix** (e.g., "upside_down_v1") = V1 (ORIGINAL - before adjustments)

## Filters That Were Increased (Too Little → More Dramatic)

### 1. Upside Down
- **upside_down_v1**: Original simple flip
- **upside_down**: Now includes wave distortion for more dramatic effect

### 2. Radial Squeeze
- **radial_squeeze_v1**: strength = 0.5
- **radial_squeeze**: strength = 1.2 ⬆️ (140% increase)

### 3. Elastic Stretch
- **elastic_stretch_v1**: strength = 0.6
- **elastic_stretch**: strength = 1.3 ⬆️ (117% increase)

### 4. Lens Distortion
- **lens_distortion_v1**: k1 = 0.3, k2 = 0.1
- **lens_distortion**: k1 = 0.7, k2 = 0.3 ⬆️ (133% increase)

### 5. Squeeze Horizontal
- **squeeze_horizontal_v1**: strength = 0.4
- **squeeze_horizontal**: strength = 0.9 ⬆️ (125% increase)

### 6. Squeeze Vertical
- **squeeze_vertical_v1**: strength = 0.4
- **squeeze_vertical**: strength = 0.9 ⬆️ (125% increase)

### 7. Squish Face
- **squish_face_v1**: strength = 0.3
- **squish_face**: strength = 0.7 ⬆️ (133% increase)

### 8. Stretch Face
- **stretch_face_v1**: strength = 0.4
- **stretch_face**: strength = 0.9 ⬆️ (125% increase)

### 9. Warp Face
- **warp_face_v1**: strength = 0.2, amplitudes = 15
- **warp_face**: strength = 0.5, amplitudes = 30 ⬆️ (150% increase)

### 10. Funny Stretch
- **funny_stretch_v1**: strength = 0.35
- **funny_stretch**: strength = 0.8 ⬆️ (129% increase)

## Filters That Were Decreased (Too Much → More Subtle)

### 1. Multi Ripple
- **multi_ripple_v1**: ripple amplitudes = 15, 10, 8
- **multi_ripple**: ripple amplitudes = 8, 5, 4 ⬇️ (47-50% reduction)

### 2. Wave Distortion
- **wave_distortion_v1**: wave amplitudes = 20, 20
- **wave_distortion**: wave amplitudes = 10, 10 ⬇️ (50% reduction)

### 3. Complex Ripple
- **complex_ripple_v1**: ripple amplitudes = 18, 8
- **complex_ripple**: ripple amplitudes = 10, 5 ⬇️ (44-38% reduction)

## Testing Workflow

1. Open the app in your browser
2. Start the camera/select a video source
3. Select a scene that uses these filters (e.g., "dropout")
4. For each filter, test both versions:
   - Select the standard version (V2 - adjusted)
   - Take note of the effect intensity
   - Select the V1 version
   - Compare the difference

## Filters That Were NOT Changed (Already "Great" or "Good")

These filters remain unchanged and don't have V1 versions:
- ultimate_distortion ✓
- water_ripple ✓
- pincushion ✓
- radial_wobble ✓
- funhouse_mirror ✓
- pinch_cheeks ✓
- bulge_eyes ✓
- funny_squash ✓
- wobble_face ✓

## Feedback Collection

When testing, note for each filter:
- Is the V2 (adjusted) version now at the right intensity?
- Are there any that need further adjustment?
- Which version do you prefer for each effect?
