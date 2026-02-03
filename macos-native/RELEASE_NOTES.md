# WesWorld FX v2.0.0 - Native macOS Edition

🎉 **Major Release: Native macOS App with Metal GPU Acceleration**

## What's New
- 🚀 **Native Swift/Metal Implementation** - Completely rewritten for macOS using Metal compute shaders
- ⚡ **60+ FPS Performance** - Massive performance improvement from web/WASM's 15-25 FPS
- 🎨 **44 Distortion Filters** - All filters from dropout.json scene config
- 📷 **Camera Selector** - Support for USB cameras with easy switching
- ⌨️ **Keyboard Controls** - Tab (menu), Space (random), i (cycle cameras), arrows (browse)
- 💻 **GPU-Accelerated Processing** - Real-time Metal compute shaders at 720p

## Installation
1. Download `WesWorld-FX-2.0.0-mac-arm64.dmg`
2. Open the DMG file
3. Drag WesWorldFX.app to your Applications folder
4. Launch and grant camera permissions

## System Requirements
- macOS 13.0 or later
- Apple Silicon (M1/M2/M3/M4) or Intel Mac with Metal support
- Camera (built-in or USB)

## Keyboard Shortcuts
- **Tab** - Toggle menu
- **Space** - Random filter
- **i** - Cycle cameras
- **↑↓** - Browse filters
- **Click** - Next filter

## Technical Details
- Swift 5.9+ with Metal compute shaders
- AVFoundation camera capture at 720p
- Zero-copy CVPixelBuffer→MTLTexture pipeline
- Real-time GPU processing with 44 distortion algorithms

---

Built with ❤️ by WesWorld
