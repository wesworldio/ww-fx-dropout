#ifndef WWFX_FILTERS_H
#define WWFX_FILTERS_H

#include <cstdint>
#include <cstddef>

namespace wwfx {

// Image buffer structure
struct ImageBuffer {
    uint8_t* data;
    size_t width;
    size_t height;
    size_t channels; // 3 for RGB, 4 for RGBA
};

// Face detection result
struct FaceRect {
    float x;
    float y;
    float width;
    float height;
    float confidence;
};

// Filter types enum
enum class FilterType {
    NONE = 0,
    BLACK_WHITE,
    SEPIA,
    NEGATIVE,
    VINTAGE,
    NEON_GLOW,
    RED_TINT,
    BLUE_TINT,
    GREEN_TINT,
    POSTERIZE,
    THERMAL,
    PIXELATE,
    BLUR,
    SHARPEN,
    EMBOSS,
    SKETCH,
    CARTOON,
    RAINBOW,
    RAINBOW_SHIFT,
    ACID_TRIP,
    VHS,
    RETRO,
    CYBERPUNK,
    ANIME,
    GLOW,
    SOLARIZE,
    EDGE_DETECT,
    HALFTONE,
    BULGE,
    STRETCH,
    SWIRL,
    FISHEYE,
    PINCH,
    WAVE,
    MIRROR,
    TWIRL,
    RIPPLE,
    SPHERE,
    TUNNEL,
    WATER_RIPPLE,
    RADIAL_BLUR,
    CYLINDER,
    BARREL,
    PINCUSHION,
    WHIRLPOOL,
    RADIAL_ZOOM,
    CONCAVE,
    CONVEX,
    SPIRAL,
    RADIAL_STRETCH,
    RADIAL_COMPRESS,
    VERTICAL_WAVE,
    HORIZONTAL_WAVE,
    SKEW_HORIZONTAL,
    SKEW_VERTICAL,
    ROTATE_ZOOM,
    RADIAL_WAVE,
    ZOOM_IN,
    ZOOM_OUT,
    ROTATE,
    ROTATE_45,
    ROTATE_90,
    FLIP_HORIZONTAL,
    FLIP_VERTICAL,
    FLIP_BOTH,
    QUAD_MIRROR,
    TILE,
    RADIAL_TILE,
    ZOOM_BLUR,
    MELT,
    KALEIDOSCOPE,
    GLITCH,
    DOUBLE_VISION,
    FAST_ZOOM_IN,
    FAST_ZOOM_OUT,
    SHAKE,
    PULSE,
    SPIRAL_ZOOM,
    EXTREME_CLOSEUP,
    PUZZLE
};

// Apply filter to image buffer
// Returns 0 on success, non-zero on error
int apply_filter(ImageBuffer* image, FilterType filter_type, const FaceRect* face, int frame_count);

// Apply face mask overlay
// mask_data: RGBA image data for the mask
// mask_width, mask_height: dimensions of mask image
// Returns 0 on success
int apply_face_mask(ImageBuffer* image, const FaceRect* face, 
                    const uint8_t* mask_data, size_t mask_width, size_t mask_height);

// Get filter name from type
const char* get_filter_name(FilterType type);

// Get number of available filters
size_t get_filter_count();

} // namespace wwfx

#endif // WWFX_FILTERS_H

