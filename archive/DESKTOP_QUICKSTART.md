# WesWorld FX Desktop - Quick Start Guide

## 🚀 Getting Started

### 1. Install Dependencies

**macOS/Linux:**
```bash
cd /Users/wes/Sites/wesworld/ww-fx-dropout
./electron/install.sh
```

**Windows:**
```cmd
cd C:\path\to\ww-fx-dropout
electron\install.bat
```

Or manually:
```bash
npm install
```

### 2. Run the App

```bash
npm start
```

The desktop app will launch with optimized performance settings.

### 3. Build Installers

**For macOS:**
```bash
npm run build:mac
```
Output: `dist/WesWorld FX-1.0.0.dmg`

**For Windows:**
```bash
npm run build:win
```
Output: `dist/WesWorld FX Setup 1.0.0.exe`

**For Both:**
```bash
npm run build:all
```

## 🎯 Performance Improvements

The desktop app provides **significantly better FPS** than Chrome browser:

### Why Desktop is Faster

1. **No Browser Overhead** - No extensions, no background tabs
2. **Hardware Acceleration** - Full GPU access without browser limits
3. **Higher Frame Rates** - Can maintain 60+ FPS consistently
4. **Direct Camera Access** - Lower latency video streaming
5. **Memory Optimization** - Better memory management for WASM
6. **No Throttling** - No background tab throttling

### Expected Performance

| Environment | Typical FPS | Peak FPS |
|------------|------------|----------|
| Chrome Browser | 30-45 FPS | 50 FPS |
| Desktop App | 50-60 FPS | 60+ FPS |

### Optimizations Applied

- **GPU Acceleration**: `--enable-gpu-rasterization`
- **Zero-Copy Video**: `--enable-zero-copy`
- **Unlimited FPS**: `--disable-frame-rate-limit`
- **Hardware Video Decode**: Enabled
- **Canvas Desynchronized Mode**: Lower latency
- **High-Performance WebGL**: Optimized contexts

## 🛠️ Development

Run in development mode with DevTools:
```bash
npm run dev
```

## 📝 Notes

- First launch will request camera permissions
- Built apps are in the `dist/` folder
- Icon files can be added to `build/` directory (see `build/README.md`)
- App works offline - no internet required after installation

## 🐛 Troubleshooting

### "Camera not found"
- Grant camera permissions in system settings
- Restart the app
- Check if camera works in other apps

### "Low FPS still"
- Update graphics drivers
- Close other camera apps
- Check Activity Monitor/Task Manager for CPU usage
- Try lowering camera resolution in app settings

### "Build failed"
- Ensure Node.js 16+ is installed
- Run: `rm -rf node_modules && npm install`
- Check that you have write permissions to `dist/` folder

## 📚 Documentation

- [Electron README](electron/README.md) - Full desktop app documentation
- [Build Icons Guide](build/README.md) - How to create custom app icons
- [Main README](README.md) - Project overview
- [Performance Tips](PERFORMANCE_FIXES.md) - Additional optimizations

## ⚙️ System Requirements

- **macOS**: 10.13 or later (High Sierra+)
- **Windows**: Windows 10 or later
- **RAM**: 4GB minimum, 8GB recommended
- **Camera**: Built-in or USB webcam
- **Graphics**: Hardware with GPU acceleration support
