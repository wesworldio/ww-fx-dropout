#include "filters.h"
#include "image_processing.h"
#include <cmath>
#include <algorithm>
#include <cstring>

namespace wwfx {

// Helper to get pixel index
inline size_t pixel_index(const ImageBuffer* img, int x, int y, int c) {
    return (y * img->width + x) * img->channels + c;
}

// Color filters
void apply_black_white(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            uint8_t r = image->data[idx];
            uint8_t g = image->data[idx + 1];
            uint8_t b = image->data[idx + 2];
            uint8_t gray = rgb_to_gray(r, g, b);
            image->data[idx] = gray;
            image->data[idx + 1] = gray;
            image->data[idx + 2] = gray;
        }
    }
}

void apply_sepia(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            float r = image->data[idx];
            float g = image->data[idx + 1];
            float b = image->data[idx + 2];
            
            image->data[idx] = static_cast<uint8_t>(clamp(0.393f * r + 0.769f * g + 0.189f * b, 0.0f, 255.0f));
            image->data[idx + 1] = static_cast<uint8_t>(clamp(0.349f * r + 0.686f * g + 0.168f * b, 0.0f, 255.0f));
            image->data[idx + 2] = static_cast<uint8_t>(clamp(0.272f * r + 0.534f * g + 0.131f * b, 0.0f, 255.0f));
        }
    }
}

void apply_negative(ImageBuffer* image) {
    for (size_t i = 0; i < image->width * image->height * image->channels; ++i) {
        if (i % image->channels != 3) { // Skip alpha channel if present
            image->data[i] = 255 - image->data[i];
        }
    }
}

void apply_vintage(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            image->data[idx] = static_cast<uint8_t>(clamp(image->data[idx] * 0.9f + 20.0f, 0.0f, 255.0f));
            image->data[idx + 1] = static_cast<uint8_t>(clamp(image->data[idx + 1] * 0.85f + 15.0f, 0.0f, 255.0f));
            image->data[idx + 2] = static_cast<uint8_t>(clamp(image->data[idx + 2] * 0.8f + 10.0f, 0.0f, 255.0f));
        }
    }
}

void apply_red_tint(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            image->data[idx] = static_cast<uint8_t>(clamp(image->data[idx] * 1.5f, 0.0f, 255.0f));
        }
    }
}

void apply_blue_tint(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            image->data[idx + 2] = static_cast<uint8_t>(clamp(image->data[idx + 2] * 1.5f, 0.0f, 255.0f));
        }
    }
}

void apply_green_tint(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            image->data[idx + 1] = static_cast<uint8_t>(clamp(image->data[idx + 1] * 1.5f, 0.0f, 255.0f));
        }
    }
}

void apply_posterize(ImageBuffer* image) {
    const int levels = 4;
    const float step = 256.0f / levels;
    
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            image->data[idx] = static_cast<uint8_t>(std::floor(image->data[idx] / step) * step);
            image->data[idx + 1] = static_cast<uint8_t>(std::floor(image->data[idx + 1] / step) * step);
            image->data[idx + 2] = static_cast<uint8_t>(std::floor(image->data[idx + 2] / step) * step);
        }
    }
}

void apply_thermal(ImageBuffer* image) {
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            size_t idx = pixel_index(image, x, y, 0);
            float gray = (image->data[idx] + image->data[idx + 1] + image->data[idx + 2]) / 3.0f;
            
            if (gray < 85.0f) {
                image->data[idx] = 0;
                image->data[idx + 1] = 0;
                image->data[idx + 2] = static_cast<uint8_t>(gray * 3.0f);
            } else if (gray < 170.0f) {
                image->data[idx] = static_cast<uint8_t>((gray - 85.0f) * 3.0f);
                image->data[idx + 1] = 255;
                image->data[idx + 2] = 255;
            } else {
                image->data[idx] = 255;
                image->data[idx + 1] = static_cast<uint8_t>(255.0f - (gray - 170.0f) * 3.0f);
                image->data[idx + 2] = 0;
            }
        }
    }
}

void apply_pixelate(ImageBuffer* image) {
    const int pixel_size = 10;
    
    for (int y = 0; y < static_cast<int>(image->height); y += pixel_size) {
        for (int x = 0; x < static_cast<int>(image->width); x += pixel_size) {
            float r = 0, g = 0, b = 0;
            int count = 0;
            
            for (int dy = 0; dy < pixel_size && y + dy < static_cast<int>(image->height); ++dy) {
                for (int dx = 0; dx < pixel_size && x + dx < static_cast<int>(image->width); ++dx) {
                    size_t idx = pixel_index(image, x + dx, y + dy, 0);
                    r += image->data[idx];
                    g += image->data[idx + 1];
                    b += image->data[idx + 2];
                    ++count;
                }
            }
            
            if (count > 0) {
                r /= count;
                g /= count;
                b /= count;
                
                for (int dy = 0; dy < pixel_size && y + dy < static_cast<int>(image->height); ++dy) {
                    for (int dx = 0; dx < pixel_size && x + dx < static_cast<int>(image->width); ++dx) {
                        size_t idx = pixel_index(image, x + dx, y + dy, 0);
                        image->data[idx] = static_cast<uint8_t>(r);
                        image->data[idx + 1] = static_cast<uint8_t>(g);
                        image->data[idx + 2] = static_cast<uint8_t>(b);
                    }
                }
            }
        }
    }
}

// Distortion filters using remapping
void apply_bulge(ImageBuffer* image, const FaceRect* face) {
    ImageBuffer* temp = create_image_copy(image);
    if (!temp) return;
    
    float center_x = image->width / 2.0f;
    float center_y = image->height / 2.0f;
    float radius = std::min(image->width, image->height) / 2.0f;
    float strength = 0.5f;
    
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            float dx = x - center_x;
            float dy = y - center_y;
            float dist_sq = dx * dx + dy * dy;
            float max_dist_sq = radius * radius;
            
            if (dist_sq < max_dist_sq) {
                float dist = std::sqrt(dist_sq);
                float factor = 1.0f - (dist / radius) * strength;
                factor = clamp(factor, 0.0f, 1.0f);
                
                float new_x = center_x + dx * factor;
                float new_y = center_y + dy * factor;
                
                for (int c = 0; c < static_cast<int>(image->channels); ++c) {
                    uint8_t val = bilinear_interpolate(temp, new_x, new_y, c);
                    set_pixel(image, x, y, c, val);
                }
            } else {
                // Copy original pixel
                for (int c = 0; c < static_cast<int>(image->channels); ++c) {
                    uint8_t val = get_pixel(temp, x, y, c);
                    set_pixel(image, x, y, c, val);
                }
            }
        }
    }
    
    free_image_buffer(temp);
}

void apply_swirl(ImageBuffer* image, const FaceRect* face) {
    ImageBuffer* temp = create_image_copy(image);
    if (!temp) return;
    
    float center_x = image->width / 2.0f;
    float center_y = image->height / 2.0f;
    float radius = std::min(image->width, image->height) / 2.0f;
    float swirl_strength = 2.0f;
    
    for (size_t y = 0; y < image->height; ++y) {
        for (size_t x = 0; x < image->width; ++x) {
            float dx = x - center_x;
            float dy = y - center_y;
            float dist = std::sqrt(dx * dx + dy * dy);
            
            if (dist < radius) {
                float angle = std::atan2(dy, dx);
                float max_angle = swirl_strength * (1.0f - clamp(dist / radius, 0.0f, 1.0f));
                float new_angle = angle + max_angle;
                
                float new_x = center_x + dist * std::cos(new_angle);
                float new_y = center_y + dist * std::sin(new_angle);
                
                for (int c = 0; c < static_cast<int>(image->channels); ++c) {
                    uint8_t val = bilinear_interpolate(temp, new_x, new_y, c);
                    set_pixel(image, x, y, c, val);
                }
            } else {
                for (int c = 0; c < static_cast<int>(image->channels); ++c) {
                    uint8_t val = get_pixel(temp, x, y, c);
                    set_pixel(image, x, y, c, val);
                }
            }
        }
    }
    
    free_image_buffer(temp);
}

// Main filter dispatcher
int apply_filter(ImageBuffer* image, FilterType filter_type, const FaceRect* face, int frame_count) {
    if (!image || !image->data) return -1;
    
    switch (filter_type) {
        case FilterType::NONE:
            return 0;
            
        case FilterType::BLACK_WHITE:
            apply_black_white(image);
            break;
            
        case FilterType::SEPIA:
            apply_sepia(image);
            break;
            
        case FilterType::NEGATIVE:
            apply_negative(image);
            break;
            
        case FilterType::VINTAGE:
            apply_vintage(image);
            break;
            
        case FilterType::RED_TINT:
            apply_red_tint(image);
            break;
            
        case FilterType::BLUE_TINT:
            apply_blue_tint(image);
            break;
            
        case FilterType::GREEN_TINT:
            apply_green_tint(image);
            break;
            
        case FilterType::POSTERIZE:
            apply_posterize(image);
            break;
            
        case FilterType::THERMAL:
            apply_thermal(image);
            break;
            
        case FilterType::PIXELATE:
            apply_pixelate(image);
            break;
            
        case FilterType::BULGE:
            apply_bulge(image, face);
            break;
            
        case FilterType::SWIRL:
            apply_swirl(image, face);
            break;
            
        default:
            // For filters not yet implemented, return error
            return -2;
    }
    
    return 0;
}

int apply_face_mask(ImageBuffer* image, const FaceRect* face, 
                    const uint8_t* mask_data, size_t mask_width, size_t mask_height) {
    if (!image || !image->data || !face || !mask_data) return -1;
    
    // Calculate mask position and size based on face
    float scale_x = face->width / mask_width;
    float scale_y = face->height / mask_height;
    float scale = std::max(scale_x, scale_y) * 1.6f; // Scale up for coverage
    
    size_t mask_w = static_cast<size_t>(mask_width * scale);
    size_t mask_h = static_cast<size_t>(mask_height * scale);
    
    int x = static_cast<int>(face->x - (mask_w - face->width) / 2.0f);
    int y = static_cast<int>(face->y - (mask_h - face->height) / 2.0f);
    
    // Blend mask onto image
    for (size_t my = 0; my < mask_h && y + static_cast<int>(my) < static_cast<int>(image->height); ++my) {
        for (size_t mx = 0; mx < mask_w && x + static_cast<int>(mx) < static_cast<int>(image->width); ++mx) {
            if (x + static_cast<int>(mx) < 0 || y + static_cast<int>(my) < 0) continue;
            
            // Sample from mask (simple nearest neighbor for now)
            size_t mask_src_x = (mx * mask_width) / mask_w;
            size_t mask_src_y = (my * mask_height) / mask_h;
            size_t mask_idx = (mask_src_y * mask_width + mask_src_x) * 4; // RGBA
            
            if (mask_idx + 3 >= mask_width * mask_height * 4) continue;
            
            float alpha = mask_data[mask_idx + 3] / 255.0f;
            
            size_t img_x = x + mx;
            size_t img_y = y + my;
            size_t img_idx = pixel_index(image, img_x, img_y, 0);
            
            if (img_idx + 2 < image->width * image->height * image->channels) {
                image->data[img_idx] = static_cast<uint8_t>(
                    mask_data[mask_idx] * alpha + image->data[img_idx] * (1.0f - alpha));
                image->data[img_idx + 1] = static_cast<uint8_t>(
                    mask_data[mask_idx + 1] * alpha + image->data[img_idx + 1] * (1.0f - alpha));
                image->data[img_idx + 2] = static_cast<uint8_t>(
                    mask_data[mask_idx + 2] * alpha + image->data[img_idx + 2] * (1.0f - alpha));
            }
        }
    }
    
    return 0;
}

const char* get_filter_name(FilterType type) {
    // Return filter name string - implementation would map enum to string
    return "unknown";
}

size_t get_filter_count() {
    return static_cast<size_t>(FilterType::PUZZLE) + 1;
}

} // namespace wwfx

