#ifndef WWFX_IMAGE_PROCESSING_H
#define WWFX_IMAGE_PROCESSING_H

#include <cstdint>
#include <cstddef>
#include "filters.h"

namespace wwfx {

// Utility functions for image processing

// Clamp value to range [min, max]
inline float clamp(float value, float min_val, float max_val) {
    if (value < min_val) return min_val;
    if (value > max_val) return max_val;
    return value;
}

// Clamp integer value
inline int clamp_int(int value, int min_val, int max_val) {
    if (value < min_val) return min_val;
    if (value > max_val) return max_val;
    return value;
}

// Convert RGB to grayscale
inline uint8_t rgb_to_gray(uint8_t r, uint8_t g, uint8_t b) {
    return static_cast<uint8_t>(0.299f * r + 0.587f * g + 0.114f * b);
}

// Bilinear interpolation for remapping
uint8_t bilinear_interpolate(const ImageBuffer* image, float x, float y, int channel);

// Get pixel value with bounds checking
uint8_t get_pixel(const ImageBuffer* image, int x, int y, int channel);

// Set pixel value with bounds checking
void set_pixel(ImageBuffer* image, int x, int y, int channel, uint8_t value);

// Create a copy of image buffer
ImageBuffer* create_image_copy(const ImageBuffer* src);

// Free image buffer
void free_image_buffer(ImageBuffer* image);

// Allocate new image buffer
ImageBuffer* allocate_image_buffer(size_t width, size_t height, size_t channels);

} // namespace wwfx

#endif // WWFX_IMAGE_PROCESSING_H

