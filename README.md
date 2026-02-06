# WesWorld FX - macOS Native Edition

![Example Output](examples/2025-11-27-02.28.37.gif)

Creative custom face filters with distortion effects for macOS. Ultra-high-performance native app with **60+ FPS** on Mac using Metal GPU acceleration.

- ✅ **Open Heart Source** - Do what you want, but don't be a jerk
- ✅ **60+ FPS Performance** - Native macOS with Metal GPU acceleration
- ✅ **Hardware Acceleration** - Direct Metal compute shaders
- ✅ **Zero-Copy Processing** - AVFoundation to Metal pipeline
- ✅ **OBS Integration** - Works seamlessly with OBS virtual camera

## Get Started

### Quick Start (macOS Native App)
The fastest way to get started - builds a native macOS app with optimal performance:

```bash
# Initial setup (creates Xcode project)
make setup

# Build and run
make run

# Or just build for release
make release
```

**Performance:** 60+ FPS native rendering with full GPU acceleration

See [macos-native/README.md](macos-native/README.md) for detailed native app documentation.

## Features

### Native macOS App Features
- **60+ FPS performance** with Metal GPU acceleration
- **Hardware-accelerated processing** with zero-copy pipeline
- **Real-time filter adjustments** with responsive UI
- **95+ creative filters** including distortion and color effects
- **OBS integration** via virtual camera
- **Works offline** - no internet required
- **Optimized for Apple Silicon and Intel Macs**

## Installation

### Prerequisites
- macOS 11.0 or later
- Xcode Command Line Tools (for building)
- Apple Silicon or Intel Mac

### Setup and Build

**Initial setup (creates Xcode project):**
```bash
make setup
```

**Build the app:**
```bash
make build      # Debug build
make release    # Release build (optimized)
```

**Run the app:**
```bash
make run        # Build and run
```

**Open in Xcode for development:**
```bash
make xcode
```


## Filter Examples

The app includes **95+ professional filters** organized by type:

### Filter Categories

- **Distortion Filters** (50+): Bulge, Stretch, Swirl, Fisheye, Pinch, Wave, Mirror, Twirl, Ripple, Sphere, Tunnel, and many more
- **Color & Style Filters** (40+): Black & White, Sepia, Vintage, Neon Glow, Pixelate, Blur, Sharpen, Emboss, and more
- **Special Effects**: SAM REICH tattoo tracking, Face masks, and more

See [macos-native/README.md](macos-native/README.md) for detailed filter documentation and examples.

## OBS Integration

The macOS native app works seamlessly with OBS using the virtual camera feature:

1. **Start the filter app:**
   ```bash
   make run
   ```

2. **In OBS:**
   - Go to **Tools → Start Virtual Camera**
   - Add a new **Video Capture Device** source
   - Select the WesWorld FX virtual camera
   - The filtered video will appear in OBS

3. **Switch filters in real-time** using the native app UI

This provides **60+ FPS** performance directly in OBS with no latency overhead.

## Performance

### Native macOS Performance
- **60+ FPS** on modern Macs (compared to 15-25 FPS in browsers)
- **Metal GPU acceleration** for all filter processing
- **Zero-copy camera pipeline** with AVFoundation
- **Direct memory access** for efficient processing
- **Hardware-accelerated rendering** with native compositing

### Why Native is Better Than Web/WASM
1. **3-4x faster** than JavaScript/Canvas-based filters
2. **Zero memory copying** from camera to GPU
3. **Direct GPU compute** access via Metal
4. **Native Swift compilation** vs JavaScript JIT overhead
5. **Hardware-backed pixel buffers** vs Canvas limitations

See [macos-native/PERFORMANCE_COMPARISON.md](macos-native/PERFORMANCE_COMPARISON.md) for detailed benchmarks.

## Documentation

- **[macos-native/README.md](macos-native/README.md)** - Full native app documentation
- **[macos-native/SETUP_GUIDE.md](macos-native/SETUP_GUIDE.md)** - Detailed setup instructions
- **[docs/README.md](docs/README.md)** - General documentation
- **[RELEASE_STATUS.md](RELEASE_STATUS.md)** - Current release information

