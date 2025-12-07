# WASM Migration Guide

This document describes the migration to WebAssembly (WASM) for cross-platform support.

## Overview

WesWorld FX now uses a WASM-based core that provides:
- **MIT Licensed** - Open source, free for anyone to use
- **Cross-Platform** - Works on browser, mobile, Windows, macOS, Linux
- **High Performance** - Near-native speed with WebAssembly
- **Code Reuse** - Same C++ core compiled to WASM (web) and native (desktop)

## Architecture

```
└── wasm/ (C++ core)
    ├── src/ (C++ source files)
    │   ├── filters.cpp (Filter algorithms)
    │   ├── image_processing.cpp (Image utilities)
    │   └── wasm_bindings.cpp (Emscripten bindings)
    ├── include/ (Header files)
    ├── js/ (JavaScript wrapper)
    └── build.sh (Build script)
    
└── static/wasm/ (Compiled output)
    ├── wwfx_module.js (Emscripten JS loader)
    └── wwfx_module.wasm (WASM binary)
```

## Building the WASM Module

### Prerequisites

1. **Emscripten SDK**
   ```bash
   git clone https://github.com/emscripten-core/emsdk.git
   cd emsdk
   ./emsdk install latest
   ./emsdk activate latest
   source ./emsdk_env.sh
   ```

2. **CMake** (3.15+)
   - macOS: `brew install cmake`
   - Linux: `sudo apt-get install cmake`
   - Windows: Download from https://cmake.org/download/

### Build Steps

```bash
cd wasm
./build.sh
```

This will:
1. Compile C++ code to WebAssembly
2. Generate JavaScript bindings
3. Output to `static/wasm/` directory

## Using WASM in standalone.html

### Option 1: Use standalone-wasm.html (Recommended)

The new `standalone-wasm.html` file uses:
- MediaPipe WASM for face detection (better than face-api.js)
- WASM filters for processing (when built)
- JavaScript fallback for compatibility
- Mobile-optimized UI

Simply open `standalone-wasm.html` in a browser.

### Option 2: Update existing standalone.html

1. Add WASM module loader:
   ```html
   <script src="static/js/wwfx-wasm.js"></script>
   <script src="static/wasm/wwfx_module.js"></script>
   ```

2. Initialize WASM:
   ```javascript
   const wwfx = new WWFXWasm();
   await wwfx.init('static/wasm/wwfx_module.wasm');
   ```

3. Replace filter calls:
   ```javascript
   // Old: FilterImplementations.applyBlackWhite(data)
   // New:
   wwfx.processFrame(inputCanvas, outputCanvas, 
                     WWFXWasm.FilterType.BLACK_WHITE, 
                     faceRect, frameCount);
   ```

## Mobile Support

The WASM module works on:
- ✅ iOS Safari 12.2+
- ✅ Android Chrome 57+
- ✅ Mobile Firefox
- ✅ Mobile Edge

### Mobile Optimizations

1. **Lower Resolution**: Use 640x480 or 854x480 for mobile
2. **Touch Targets**: Minimum 44px height (iOS guidelines)
3. **Performance**: Limit filter complexity on mobile
4. **Battery**: Use `requestAnimationFrame` for smooth rendering

## Desktop Native Build

The same C++ code can be compiled to native binaries:

```bash
cd wasm
mkdir build-native
cd build-native
cmake .. -DCMAKE_BUILD_TYPE=Release
make -j$(nproc)
```

This creates a native library that can be linked into desktop applications (Electron, Tauri, Qt, etc.).

## Performance

Expected performance on modern hardware (2020+):

| Platform | Resolution | FPS |
|----------|-----------|-----|
| Desktop Browser | 1280x720 | 60+ |
| Mobile Browser | 640x480 | 30-60 |
| Native Desktop | 1920x1080 | 60+ |

## Filter Implementation Status

### ✅ Implemented in WASM
- BLACK_WHITE
- SEPIA
- NEGATIVE
- VINTAGE
- RED_TINT, BLUE_TINT, GREEN_TINT
- POSTERIZE
- THERMAL
- PIXELATE
- BULGE
- SWIRL

### 🚧 In Progress
- All other filters from Python implementation
- Face mask overlay
- Animated filters (pulse, shake, etc.)

### 📝 To Implement
- Complex distortion filters (fisheye, pinch, etc.)
- Artistic filters (sketch, cartoon, etc.)
- Special effects (glow, solarize, etc.)

## Migration Checklist

- [x] Create MIT license
- [x] Create C++ core structure
- [x] Set up Emscripten build
- [x] Create JavaScript bindings
- [x] Create WASM loader
- [x] Integrate MediaPipe WASM
- [x] Add mobile support
- [x] Create build scripts
- [ ] Port all filters to C++
- [ ] Update standalone.html
- [ ] Add native desktop build
- [ ] Performance testing
- [ ] Documentation

## Troubleshooting

### WASM not loading
- Check browser console for errors
- Verify WASM files are in `static/wasm/`
- Ensure server serves `.wasm` files with correct MIME type

### Performance issues
- Reduce resolution
- Use simpler filters
- Check browser DevTools Performance tab

### Mobile not working
- Check WebAssembly support: `typeof WebAssembly !== 'undefined'`
- Test on HTTPS (required for camera access)
- Check browser compatibility

## License

MIT License - See LICENSE file. This means:
- ✅ Free to use
- ✅ Free to modify
- ✅ Free to distribute
- ✅ Free for commercial use
- ✅ No warranty

## Contributing

Contributions welcome! Areas that need help:
- Porting remaining filters to C++
- Performance optimization
- Mobile testing
- Documentation
- Native desktop builds

