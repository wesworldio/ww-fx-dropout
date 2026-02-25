#include <emscripten/bind.h>
#include <emscripten/val.h>
#include "filters.h"
#include "image_processing.h"
#include <vector>

using namespace emscripten;
using namespace wwfx;

// Wrapper class for ImageBuffer to work with Emscripten
class WasmImageBuffer {
public:
    ImageBuffer* buffer;
    
    WasmImageBuffer(size_t width, size_t height, size_t channels) {
        buffer = allocate_image_buffer(width, height, channels);
    }
    
    ~WasmImageBuffer() {
        if (buffer) {
            free_image_buffer(buffer);
        }
    }
    
    void setData(val data) {
        if (!buffer) return;
        
        std::vector<uint8_t> vec = vecFromJSArray<uint8_t>(data);
        size_t size = buffer->width * buffer->height * buffer->channels;
        if (vec.size() >= size) {
            std::memcpy(buffer->data, vec.data(), size);
        }
    }
    
    val getData() {
        if (!buffer) return val::undefined();
        
        size_t size = buffer->width * buffer->height * buffer->channels;
        return val(typed_memory_view(size, buffer->data));
    }
    
    size_t getWidth() const { return buffer ? buffer->width : 0; }
    size_t getHeight() const { return buffer ? buffer->height : 0; }
    size_t getChannels() const { return buffer ? buffer->channels : 0; }
};

// FaceRect wrapper
class WasmFaceRect {
public:
    FaceRect rect;
    
    WasmFaceRect(float x, float y, float width, float height, float confidence = 1.0f) {
        rect.x = x;
        rect.y = y;
        rect.width = width;
        rect.height = height;
        rect.confidence = confidence;
    }
    
    float getX() const { return rect.x; }
    float getY() const { return rect.y; }
    float getWidth() const { return rect.width; }
    float getHeight() const { return rect.height; }
    float getConfidence() const { return rect.confidence; }
};

// Apply filter to image
int wasm_apply_filter(WasmImageBuffer* image, int filter_type, WasmFaceRect* face, int frame_count) {
    if (!image || !image->buffer) return -1;
    
    FaceRect* face_ptr = face ? &face->rect : nullptr;
    return apply_filter(image->buffer, static_cast<FilterType>(filter_type), face_ptr, frame_count);
}

// Apply face mask
int wasm_apply_face_mask(WasmImageBuffer* image, WasmFaceRect* face, val mask_data, size_t mask_width, size_t mask_height) {
    if (!image || !image->buffer || !face) return -1;
    
    std::vector<uint8_t> vec = vecFromJSArray<uint8_t>(mask_data);
    if (vec.size() < mask_width * mask_height * 4) return -2;
    
    return apply_face_mask(image->buffer, &face->rect, vec.data(), mask_width, mask_height);
}

// Get filter count
size_t wasm_get_filter_count() {
    return get_filter_count();
}

// Emscripten bindings
EMSCRIPTEN_BINDINGS(wwfx_wasm) {
    class_<WasmImageBuffer>("ImageBuffer")
        .constructor<size_t, size_t, size_t>()
        .function("setData", &WasmImageBuffer::setData)
        .function("getData", &WasmImageBuffer::getData)
        .property("width", &WasmImageBuffer::getWidth)
        .property("height", &WasmImageBuffer::getHeight)
        .property("channels", &WasmImageBuffer::getChannels);
    
    class_<WasmFaceRect>("FaceRect")
        .constructor<float, float, float, float, float>()
        .property("x", &WasmFaceRect::getX)
        .property("y", &WasmFaceRect::getY)
        .property("width", &WasmFaceRect::getWidth)
        .property("height", &WasmFaceRect::getHeight)
        .property("confidence", &WasmFaceRect::getConfidence);
    
    function("applyFilter", &wasm_apply_filter, allow_raw_pointers());
    function("applyFaceMask", &wasm_apply_face_mask, allow_raw_pointers());
    function("getFilterCount", &wasm_get_filter_count);
    
    // Filter type enum
    enum_<FilterType>("FilterType")
        .value("NONE", FilterType::NONE)
        .value("BLACK_WHITE", FilterType::BLACK_WHITE)
        .value("SEPIA", FilterType::SEPIA)
        .value("NEGATIVE", FilterType::NEGATIVE)
        .value("VINTAGE", FilterType::VINTAGE)
        .value("RED_TINT", FilterType::RED_TINT)
        .value("BLUE_TINT", FilterType::BLUE_TINT)
        .value("GREEN_TINT", FilterType::GREEN_TINT)
        .value("POSTERIZE", FilterType::POSTERIZE)
        .value("THERMAL", FilterType::THERMAL)
        .value("PIXELATE", FilterType::PIXELATE)
        .value("BULGE", FilterType::BULGE)
        .value("SWIRL", FilterType::SWIRL);
    
    register_vector<uint8_t>("VectorUint8");
}

