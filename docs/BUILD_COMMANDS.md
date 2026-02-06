# Build Commands Reference

## Overview

WesWorldFX uses a Makefile with organized commands for the primary macOS native target and secondary web target.

Run `make help` to see all available commands.

## Primary: macOS Native (Metal GPU)

The native macOS app is the primary development and deployment target. Built with Xcode, uses Metal GPU acceleration.

### Essential Commands

| Command | Purpose |
|---------|---------|
| `make run` | **Main command** - Build and run the native app (debug) |
| `make setup` | Initial setup - Create Xcode project and dependencies |
| `make native-build` | Build debug version |
| `make native-release` | Build optimized release version |
| `make native-xcode` | Open Xcode project for IDE development |
| `make native-clean` | Clean all build artifacts |
| `make native-rebuild` | Quick: clean and rebuild |
| `make native-kill` | Force-kill any running instance |

### Development Workflow

```bash
# First time setup
make setup

# Regular development
make run              # Build and run
# (Make changes in Xcode)
make run              # Rebuild and run

# Release builds
make native-release   # Create optimized version
```

## Secondary: Web Target (Testing & Comparison)

Web version for browser testing, comparison testing, and alternative access.

### Essential Commands

| Command | Purpose |
|---------|---------|
| `make web-build` | Build web assets |
| `make web-clean` | Clean web build artifacts |
| `make web-watch` | Watch files and rebuild (foreground, Ctrl+C to stop) |
| `make web-daemon` | Start background watcher |
| `make web-daemon-stop` | Stop background watcher |
| `make web-daemon-logs` | View watcher logs (follow) |
| `make web-daemon-status` | Check if watcher is running |

### Web Development Workflow

```bash
# One-time watch in foreground
make web-watch
# Press Ctrl+C to stop

# Or run background watcher
make web-daemon                # Start
make web-daemon-logs           # View logs
make web-daemon-stop           # Stop when done
```

## Utilities

| Command | Purpose |
|---------|---------|
| `make build-info` | Generate build-info.json metadata from git |
| `make setup-hooks` | Install git hooks for auto-updating build-info |

## Implementation Details

### Native Build System

- **Tool**: Xcode with xcodebuild
- **Project**: `macos-native/WesWorldFX.xcodeproj`
- **Build Location**: `macos-native/build/Build/Products/`
- **Debug App**: `Build/Products/Debug/WesWorldFX.app`
- **Release App**: `Build/Products/Release/WesWorldFX.app`

### Web Build System

- **HTML Files**: `index.html`, `web-grid-generator.html` (root)
- **Static Assets**: `static/` directory
- **Configuration**: `wrangler.jsonc` (Cloudflare Workers)

### Scripts Used

- `scripts/generate_build_info.py` - Generate build metadata
- `scripts/setup_git_hooks.sh` - Install git hooks
- `scripts/watch_wasm.py` - File watcher for changes
- `scripts/update_build_info.py` - Update build info

### Constants Defined in Makefile

```makefile
MACOS_DIR = macos-native
NATIVE_APP_NAME = WesWorldFX
BUILD_DIR = macos-native/build
DEBUG_DIR = macos-native/build/Build/Products/Debug
RELEASE_DIR = macos-native/build/Build/Products/Release
```

## Troubleshooting

### Native App Won't Build

1. Check Xcode is installed: `xcode-select --install`
2. Run setup: `make setup`
3. Open in Xcode: `make native-xcode` (view compiler errors)
4. Clean and retry: `make native-clean && make run`

### App Won't Launch

1. Ensure build completed: `make native-build`
2. Kill any stuck process: `make native-kill`
3. Try again: `make run`

### Web Watcher Issues

1. Check status: `make web-daemon-status`
2. View logs: `make web-daemon-logs`
3. Restart: `make web-daemon-stop && make web-daemon`

## Notes

- **Colors in output**: Makefile uses ANSI colors for readability
  - Green (✓) = Success
  - Yellow = In progress/info
  - Red (❌) = Error
- **Default targets**: `make setup`, `make run`, `make clean` redirect to native commands
- **Parallel builds**: Both native and web can be developed simultaneously
- **Dependencies**: Native builds require Xcode, web requires Python 3
