#include "image_processing.h"
#include <cstring>
#include <cmath>

namespace wwfx {

uint8_t get_pixel(const ImageBuffer* image, int x, int y, int channel) {
    if (!image || !image->data) return 0;
    
    x = clamp_int(x, 0, static_cast<int>(image->width) - 1);
    y = clamp_int(y, 0, static_cast<int>(image->height) - 1);
    
    if (channel < 0 || channel >= static_cast<int>(image->channels)) return 0;
    
    size_t index = (y * image->width + x) * image->channels + channel;
    return image->data[index];
}

void set_pixel(ImageBuffer* image, int x, int y, int channel, uint8_t value) {
    if (!image || !image->data) return;
    
    x = clamp_int(x, 0, static_cast<int>(image->width) - 1);
    y = clamp_int(y, 0, static_cast<int>(image->height) - 1);
    
    if (channel < 0 || channel >= static_cast<int>(image->channels)) return;
    
    size_t index = (y * image->width + x) * image->channels + channel;
    image->data[index] = value;
}

uint8_t bilinear_interpolate(const ImageBuffer* image, float x, float y, int channel) {
    if (!image || !image->data) return 0;
    
    // Clamp coordinates
    x = clamp(x, 0.0f, static_cast<float>(image->width) - 1.0f);
    y = clamp(y, 0.0f, static_cast<float>(image->height) - 1.0f);
    
    int x1 = static_cast<int>(x);
    int y1 = static_cast<int>(y);
    int x2 = x1 + 1;
    int y2 = y1 + 1;
    
    // Clamp to image bounds
    x2 = clamp_int(x2, 0, static_cast<int>(image->width) - 1);
    y2 = clamp_int(y2, 0, static_cast<int>(image->height) - 1);
    
    float fx = x - x1;
    float fy = y - y1;
    
    // Get four corner pixels
    uint8_t p11 = get_pixel(image, x1, y1, channel);
    uint8_t p21 = get_pixel(image, x2, y1, channel);
    uint8_t p12 = get_pixel(image, x1, y2, channel);
    uint8_t p22 = get_pixel(image, x2, y2, channel);
    
    // Bilinear interpolation
    float result = p11 * (1.0f - fx) * (1.0f - fy) +
                   p21 * fx * (1.0f - fy) +
                   p12 * (1.0f - fx) * fy +
                   p22 * fx * fy;
    
    return static_cast<uint8_t>(clamp(result, 0.0f, 255.0f));
}

ImageBuffer* create_image_copy(const ImageBuffer* src) {
    if (!src || !src->data) return nullptr;
    
    ImageBuffer* dst = allocate_image_buffer(src->width, src->height, src->channels);
    if (!dst) return nullptr;
    
    size_t size = src->width * src->height * src->channels;
    std::memcpy(dst->data, src->data, size);
    
    return dst;
}

ImageBuffer* allocate_image_buffer(size_t width, size_t height, size_t channels) {
    ImageBuffer* image = new ImageBuffer;
    if (!image) return nullptr;
    
    image->width = width;
    image->height = height;
    image->channels = channels;
    
    size_t size = width * height * channels;
    image->data = new uint8_t[size];
    
    if (!image->data) {
        delete image;
        return nullptr;
    }
    
    return image;
}

void free_image_buffer(ImageBuffer* image) {
    if (!image) return;
    
    if (image->data) {
        delete[] image->data;
        image->data = nullptr;
    }
    
    delete image;
}

} // namespace wwfx

