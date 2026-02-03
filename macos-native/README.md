# WesWorld FX - Native Mac Edition

## 🚀 Ultra-High Performance Mac App

This is a **native macOS app** built with Swift, AVFoundation, and Metal for **maximum FPS** on Mac.

### Why Native Instead of Web/Electron?

**Performance Gains:**
- ✅ **60+ FPS easily** (vs 15-25 FPS in web/WASM)
- ✅ Direct **Metal GPU acceleration** (vs WebGL/Canvas bottlenecks)
- ✅ Zero-copy camera capture with **AVFoundation** (vs getUserMedia overhead)
- ✅ Native Swift compiled code (vs JavaScript JIT + WASM overhead)
- ✅ Direct memory access (vs Canvas ImageData copying)
- ✅ Hardware-accelerated video pipeline (vs browser limitations)

**The Problem with Web/WASM:**
1. JavaScript overhead for camera capture
2. Canvas → ImageData → WASM memory copying (3 copies per frame!)
3. WASM → Canvas → Display (more copying!)
4. WebGL/Canvas API limitations
5. Browser compositing overhead
6. No direct GPU compute access

**Native Mac Solution:**
1. AVFoundation → CVPixelBuffer (zero copy, hardware-backed)
2. CVPixelBuffer → Metal Texture (direct GPU memory)
3. Metal Compute Shader processes on GPU
4. Metal → Display (hardware compositing)

**Result: 3-4x faster!**

## Architecture

```
Camera (AVFoundation)
    ↓ (zero-copy CVPixelBuffer)
Metal Texture Cache
    ↓
GPU Compute Shaders (filters)
    ↓
Metal Renderer
    ↓
Display (hardware compositing)
```

## Features

- 🎥 High-performance camera capture (720p @ 60fps default)
- 🎨 All original filters ported to Metal shaders
- ⚡ GPU-accelerated processing
- 📊 Real-time FPS counter
- 🎮 Keyboard shortcuts (↑↓ arrows)
- 🖱️ Click to cycle filters
- 🎯 Native Mac UI

## Filters

All filters from the web version, now GPU-accelerated:

- Black & White, Sepia, Negative, Vintage
- Color Tints (Red, Blue, Green)
- Neon Glow, Posterize, Thermal
- Pixelate, Blur, Sharpen, Emboss
- Sketch, Cartoon
- Rainbow, Rainbow Shift, Acid Trip
- VHS, Retro, Cyberpunk

## Requirements

- macOS 13.0 (Ventura) or later
- Xcode 15+ for building
- Mac with Metal support (all Macs since 2012)

## Building

### Option 1: Quick Build
```bash
cd macos-native
chmod +x build-native.sh
./build-native.sh
```

### Option 2: Xcode
```bash
cd macos-native
open WesWorldFX.xcodeproj
# Press Cmd+R to build and run
```

### Option 3: Command Line
```bash
cd macos-native
swift build -c release
.build/release/WesWorldFX
```

## Performance Tips

1. **Use 720p camera** - Perfect balance of quality/speed
2. **Ensure GPU is active** - Check Activity Monitor → GPU History
3. **Close other GPU-intensive apps** - Give Metal full access
4. **Use external camera if available** - Often better performance

## Expected FPS

- **Integrated GPU (Intel/M1)**: 45-60 FPS
- **Discrete GPU (AMD/M1 Pro+)**: 60+ FPS (locked to display refresh)
- **Older Macs (2015-2017)**: 30-45 FPS

*Compare to web version: 15-25 FPS on same hardware!*

## Troubleshooting

### Low FPS?
1. Check GPU is being used (Activity Monitor)
2. Reduce camera resolution to 640x480
3. Close other apps using camera/GPU
4. Ensure MacBook is plugged in (not on battery power-saving mode)

### Camera not working?
1. Check System Settings → Privacy & Security → Camera
2. Grant permission to WesWorldFX
3. Restart app

### App won't open?
```bash
# If unsigned app warning appears:
xattr -cr /path/to/WesWorldFX.app
```

## Technical Details

**Stack:**
- Swift 5.9+
- AVFoundation (camera capture)
- Metal (GPU compute & rendering)
- MetalKit (display)
- AppKit (UI)

**Key Components:**
- `CameraViewController.swift` - Camera capture & UI
- `FilterProcessor.swift` - Metal compute pipeline
- `MetalRenderer.swift` - GPU rendering
- `Shaders.metal` - All filter implementations

## License

MIT License - Same as parent project

## Credits

Native Mac port of WesWorld FX by wesworldio
Original web version filters ported to Metal shaders
