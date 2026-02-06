# WesWorld FX - Makefile Commands Reference

## Quick Start

```bash
# Build and run the native macOS Metal app
make run

# Or use the setup command first
make setup
make run
```

## All Available Commands

### 🚀 Quick Commands

| Command | Description |
|---------|-------------|
| `make run` | Build and run the native macOS Metal app (main entry point) |
| `make setup` | Initial setup for the native app |
| `make help` | Display all available commands |

### 🎨 Native macOS Metal App Commands

| Command | Description |
|---------|-------------|
| `make native-setup` | Create Xcode project for native app |
| `make native-build` | Build native app (debug version) |
| `make native-run` | Build and run native app |
| `make native-release` | Build release version |
| `make native-clean` | Clean native build artifacts |
| `make native-xcode` | Open Xcode project |
| `make native-kill` | Kill any running instances |
| `make native-rebuild` | Clean, rebuild, and run |

### ⚡ Swift Package Manager Commands (Faster)

| Command | Description |
|---------|-------------|
| `make native-spm-build` | Build using Swift Package Manager |
| `make native-spm-run` | Build and run using Swift Package Manager (no Xcode) |
| `make native-spm-release` | Build release with Swift Package Manager |

### 🌐 Web/WASM Commands

| Command | Description |
|---------|-------------|
| `make build` | Build WASM module |
| `make clean` | Clean WASM build artifacts |
| `make watch` | Watch files and rebuild (foreground) |
| `make daemon` | Start watcher daemon (background) |
| `make daemon-stop` | Stop watcher daemon |
| `make daemon-status` | Check watcher daemon status |
| `make daemon-logs` | View watcher logs (tail -f) |

### 🛠️ Utility Commands

| Command | Description |
|---------|-------------|
| `make build-info` | Generate build-info.json from git |
| `make setup-hooks` | Install git hooks for auto build-info.json |

---

## Project Structure

```
ww-fx-dropout/
├── Makefile                    # Root makefile with all commands
├── macos-native/               # Native macOS Metal app (Swift)
│   ├── Makefile               # Native app specific commands
│   ├── Package.swift          # Swift package definition
│   ├── WesWorldFX/            # App source code
│   │   ├── Sources/
│   │   ├── Metal/
│   │   │   └── Shaders.metal  # GPU compute kernels
│   │   └── Resources/
│   └── build/                 # Build output
├── wasm/                       # Web WASM module
├── web/                        # Web interface
└── static/                     # Static assets
```

---

## Native App Details

### Build System
- **Primary**: Swift Package Manager (fast, no Xcode required)
- **Alternative**: Xcode project (manual setup via `create-xcode-project.sh`)

### Technology Stack
- **Language**: Swift 6.2.3
- **Framework**: AppKit + Metal
- **GPU**: Metal compute shaders for real-time filtering
- **Camera**: AVFoundation
- **UI**: Native Cocoa

### Key Features
- 🎥 Live camera feed with real-time Metal filters
- 🌀 Custom bulge/pinch distortion effects
- 🎨 Grid pattern visualization
- ⚡ GPU-accelerated processing (Metal compute)
- 💾 Filter persistence (UserDefaults)

---

## Example Workflows

### Develop the Native App
```bash
# First time setup
make native-setup
make native-run

# Or faster with SPM:
make native-spm-run

# Make changes, then rebuild
make native-rebuild

# Or just rerun
make native-run
```

### Develop the Web Version
```bash
# Watch for changes (foreground)
make watch

# Or run daemon (background)
make daemon
make daemon-logs      # View logs
make daemon-stop      # Stop watching
```

### Build Release
```bash
# Native app
make native-release
# Output: macos-native/build/Build/Products/Release/WesWorldFX.app

# Or with SPM
make native-spm-release
# Output: macos-native/.build/release/WesWorldFX
```

---

## Current Build Status

✅ **Native App Status**
- Build: ✓ Complete (0.96s)
- Runtime: ✓ Active
- Camera: ✓ Authorized and running
- Metal: ✓ Shaders loaded (97,984 bytes)
- GPU Pipeline: ✓ Custom bulge compute pipeline ready

---

## Troubleshooting

### App Won't Build
```bash
# Clean and rebuild
make native-clean
make native-spm-build

# Or use Xcode (if project exists)
make native-xcode
```

### Camera Not Working
- Ensure camera permissions are granted in System Preferences
- Check Console.app for Metal/AVFoundation errors

### Memory Issues
- App may consume 100-200 MB (normal for Metal GPU processing)
- Use `make native-kill` to terminate and restart

### Simulator Errors
- Native app requires macOS (not iOS)
- Only builds for arm64/x86_64 on macOS

---

## Performance Tips

1. **Use `make native-spm-run`** - Faster than Xcode builds
2. **Editor Preview** - Press `B` to open Custom Bulge Editor with live updates
3. **GPU Processing** - Metal shaders run on GPU, not CPU (faster)
4. **Background Thread** - Long operations offloaded automatically

---

## Build Configuration

**Debug Build** (Default)
- Optimization: O0 (slower, better debugging)
- Debug symbols: Included
- App size: ~50 MB
- Build time: ~1 second

**Release Build**
- Optimization: Osize (smaller, optimized)
- Debug symbols: Stripped
- App size: ~30 MB
- Build time: ~2 seconds

---

## Notes

- Python backend code has been archived (see `archive/README.md`)
- WASM version is web-based, separate from native app
- Native app is the recommended version for macOS
- All commands work from project root directory
- Color output available in terminal (Green=✓, Yellow=Task, Red=Error)

---

**Last Updated**: February 5, 2026  
**App Status**: ✅ Ready for Development
