# WesWorld FX Desktop App

High-performance desktop application for WesWorld FX face filters. Provides better FPS and camera performance compared to web browsers.

## Features

- **Cross-platform**: Works on both Windows and macOS
- **Better Performance**: Hardware-accelerated rendering with optimized GPU usage
- **Higher FPS**: Reduced frame rate limiting and background throttling
- **Native Camera Access**: Direct hardware access for better video quality
- **Optimized WebAssembly**: Faster WASM execution in desktop environment

## Performance Improvements Over Browser

1. **Hardware Acceleration**: Full GPU acceleration without browser limitations
2. **No Background Throttling**: Maintains 60 FPS even when app is not focused
3. **Direct Camera Access**: Lower latency camera streaming
4. **Memory Optimization**: Better memory management for continuous video processing
5. **High-Performance Mode**: Dedicated graphics resources

## Requirements

- **macOS**: 10.13 or later
- **Windows**: Windows 10 or later
- **Camera**: Built-in or USB webcam

## Installation

### Development

1. Install dependencies:
```bash
npm install
```

2. Run the app:
```bash
npm start
```

3. For development with DevTools:
```bash
npm run dev
```

### Building

Build for your current platform:
```bash
npm run build
```

Build for macOS only:
```bash
npm run build:mac
```

Build for Windows only:
```bash
npm run build:win
```

Build for both platforms:
```bash
npm run build:all
```

## Output

Built applications will be in the `dist` folder:

- **macOS**: `dist/WesWorld FX-{version}.dmg` and `.zip`
- **Windows**: `dist/WesWorld FX Setup {version}.exe` and portable version

## Architecture

### Main Process (`electron/main.js`)
- Window management
- Hardware acceleration configuration
- Camera permission handling
- IPC communication

### Preload Script (`electron/preload.js`)
- Secure bridge between main and renderer processes
- Context isolation for security

### Renderer Optimizations (`electron/renderer-optimizations.js`)
- Canvas context optimization
- MediaStream constraint enhancement
- RequestAnimationFrame batching
- Performance monitoring

## Performance Optimizations

The desktop app includes several optimizations:

### GPU Acceleration
```javascript
--enable-gpu-rasterization
--enable-zero-copy
--disable-frame-rate-limit
```

### Canvas Optimization
- Hardware-accelerated 2D contexts
- `desynchronized` mode for lower latency
- Optimized pixel read operations

### Video Streaming
- Higher frame rate requests (up to 60 FPS)
- Better resolution defaults (1080p)
- Hardware video decoding

### WebAssembly
- Faster execution with native process
- Better memory management
- No browser sandboxing overhead

## Camera Permissions

### macOS
The app will automatically request camera permissions. You can also manually grant permissions in:
`System Preferences > Security & Privacy > Camera`

### Windows
Camera permissions are handled by Windows. Ensure the app has camera access in:
`Settings > Privacy > Camera`

## Troubleshooting

### Low FPS
1. Check if hardware acceleration is enabled
2. Close other camera applications
3. Update graphics drivers
4. Try different camera resolutions

### Camera Not Working
1. Grant camera permissions in system settings
2. Restart the application
3. Check if camera works in other apps
4. Try different USB ports (for external cameras)

### Build Errors
1. Ensure Node.js 16+ is installed
2. Clear node_modules and reinstall: `rm -rf node_modules && npm install`
3. Check build logs for specific errors

## Development

### Project Structure
```
electron/
  ├── main.js                    # Main process
  ├── preload.js                 # Preload script
  └── renderer-optimizations.js  # Desktop optimizations
build/
  ├── entitlements.mac.plist     # macOS permissions
  ├── icon.icns                  # macOS icon
  └── icon.ico                   # Windows icon
```

### Adding Features
1. Modify main process in `electron/main.js`
2. Add IPC handlers for communication
3. Update preload script if exposing new APIs
4. Test on both platforms

## License

MIT License - See LICENSE file for details

## Support

For issues or questions:
- Check the main README.md
- Review PERFORMANCE_FIXES.md
- Open an issue on GitHub
