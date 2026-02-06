# WesWorld FX v2.1.3 - Stability & Performance Update

## 🔧 Bug Fixes & Improvements

### Critical Fixes
• **Fixed thread-safety crash** in MetalRenderer texture access - Resolved a critical race condition that could cause app crashes during filter changes
• **Enhanced stability** with proper synchronization for Metal texture operations

### Filter Additions
• Added **36 favorite filter variations** (4 variations for each of 9 favorite filters)
• Added **42 elastic/stretch/bulge distortion filters** for creative effects
• Fixed Metal shader output in radial_wobble_v3

### Developer Improvements  
• Added comprehensive diagnostic logging system
• Enhanced debug menu with system info and log access
• Improved version display (now shows v2.1.3, Build 220)

## 📦 Installation

1. Download `WesWorld-FX-2.1.3-mac-arm64.dmg`
2. Open the DMG file
3. Drag WesWorldFX.app to your Applications folder
4. Launch and grant camera permissions when prompted

## 💻 System Requirements

• macOS 13.0 or later
• Apple Silicon (M1/M2/M3/M4) or Intel Mac with Metal support
• Camera (built-in or USB)

## ⌨️ Keyboard Shortcuts

• **Tab** - Toggle menu
• **Space** - Random filter
• **i** - Cycle cameras
• **↑↓** - Browse filters
• **Click** - Next filter

## 🔍 What's New in This Release

This update focuses on stability and performance improvements:

**Stability Enhancements:**
- Fixed a critical threading issue that could cause crashes when rapidly switching filters
- Improved Metal texture handling with proper locking mechanisms

**Filter Expansion:**
- 78 new filter variations added for more creative options
- Enhanced elastic and stretch effects

**Developer Experience:**
- New diagnostic logging system for better troubleshooting
- Debug menu for accessing system information and logs
- Improved version tracking and build information

## 🚀 Technical Details

• Swift 5.9+ with Metal compute shaders
• AVFoundation camera capture at 1080p
• Zero-copy CVPixelBuffer→MTLTexture pipeline
• Real-time GPU processing with 120+ distortion filters
• Thread-safe rendering engine

## 🐛 Known Issues

None at this time. If you encounter any issues, please use the Debug menu to access logs and report them on GitHub.

---

Built with ❤️ by WesWorld
