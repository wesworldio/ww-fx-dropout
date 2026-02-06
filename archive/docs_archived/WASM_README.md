# WesWorld FX WASM Core

This directory contains the WebAssembly (WASM) core for WesWorld FX face filters. The WASM module provides high-performance, cross-platform filter processing that works identically in browsers, mobile devices, and can be compiled to native binaries for desktop applications.

## Architecture

```
└── Shared C++ core (filters.cpp, image_processing.cpp)
    ├── Compiled to WebAssembly (for browser/mobile)
    └── Compiled to native binary (for desktop: Windows/macOS/Linux)
```

## Features

- ✅ **MIT Licensed** - Open source, free to use
- ✅ **Cross-Platform** - Browser, mobile, Windows, macOS, Linux
- ✅ **High Performance** - Near-native speed with WASM
- ✅ **Code Reuse** - Same core for web and desktop
- ✅ **Mobile Optimized** - Works on iOS and Android browsers

## Building

### Prerequisites

1. **Emscripten SDK** (for WASM compilation)
   ```bash
   # Install Emscripten
   git clone https://github.com/emscripten-core/emsdk.git
   cd emsdk
   ./emsdk install latest
   ./emsdk activate latest
   source ./emsdk_env.sh
   ```

2. **CMake** (3.15 or later)
   ```bash
   # macOS
   brew install cmake
   
   # Linux
   sudo apt-get install cmake
   
   # Windows
   # Download from https://cmake.org/download/
   ```

### Build WASM Module

```bash
cd wasm
chmod +x build.sh
./build.sh
```

This will:
1. Compile C++ code to WebAssembly
2. Generate JavaScript bindings
3. Output files to `static/wasm/` directory

### Build Native Binary (Desktop)

For desktop applications, compile the same C++ code to native:

```bash
cd wasm
mkdir -p build-native
cd build-native
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

## Usage

### In Browser (JavaScript)

```javascript
// Load WASM module
const wwfx = new WWFXWasm();
await wwfx.init('wasm/wwfx_module.wasm');

// Process canvas frame
const canvas = document.getElementById('canvas');
const faceRect = { x: 100, y: 100, width: 200, height: 200 };
wwfx.processFrame(canvas, canvas, WWFXWasm.FilterType.BULGE, faceRect);
```

### In Desktop App (Native)

Link the compiled library and use the C++ API directly:

```cpp
#include "filters.h"

wwfx::ImageBuffer* image = wwfx::allocate_image_buffer(1280, 720, 3);
// ... load image data ...

wwfx::FaceRect face = {100, 100, 200, 200, 1.0f};
wwfx::apply_filter(image, wwfx::FilterType::BULGE, &face, 0);
```

## Filter Types

All filters from the Python implementation are available:

- **Color Filters**: BLACK_WHITE, SEPIA, NEGATIVE, VINTAGE, etc.
- **Distortion Filters**: BULGE, SWIRL, FISHEYE, PINCH, etc.
- **Artistic Filters**: SKETCH, CARTOON, PIXELATE, etc.
- **Special Effects**: GLOW, SOLARIZE, EDGE_DETECT, etc.

See `include/filters.h` for the complete list.

## Performance

On modern hardware (2020+):
- **Desktop Browser**: 60+ FPS at 1280x720
- **Mobile Browser**: 30-60 FPS at 640x480
- **Native Desktop**: 60+ FPS at 1920x1080

## Mobile Support

The WASM module works on:
- ✅ iOS Safari (12.2+)
- ✅ Android Chrome (57+)
- ✅ Mobile Firefox
- ✅ Mobile Edge

For best mobile performance:
- Use lower resolution (640x480 or 854x480)
- Limit filter complexity
- Use requestAnimationFrame for smooth rendering

## License

MIT License - See LICENSE file in project root.

## Contributing

Contributions welcome! The core is written in C++17 and follows standard practices:
- Use `clang-format` for code formatting
- Add tests for new filters
- Document performance characteristics
- Ensure mobile compatibility

