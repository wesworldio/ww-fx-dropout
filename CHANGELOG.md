# Changelog

All notable changes to WesWorld FX will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [Unreleased]

### Added
- Desktop app for Windows, macOS, and Linux
- GitHub Actions workflow for automated releases
- Release management scripts (`create-release.sh` and `.bat`)
- Comprehensive desktop app documentation
- Hardware acceleration for better FPS

### Changed
- Improved performance with Electron-based desktop app
- Better camera access with lower latency

## [1.0.0] - 2026-02-02

### Added
- Initial desktop app release
- Cross-platform support (Windows, macOS, Linux)
- Hardware-accelerated rendering
- Direct camera access
- 95+ face filters
- Offline capability
- Better FPS than web browsers (50-60+ vs 30-45)
- WASM-based face detection
- Real-time video processing
- OBS virtual camera integration

### Desktop App Features
- Native app for macOS (Intel + Apple Silicon)
- Native app for Windows (x64 + x86)
- Native app for Linux (AppImage + DEB)
- GPU acceleration enabled by default
- No frame rate limiting
- Desynchronized canvas rendering
- High-performance WebGL contexts
- RequestAnimationFrame batching
- Optimized memory management

### Documentation
- Desktop app guide (DESKTOP_APP_GUIDE.md)
- Quick start guide (DESKTOP_QUICKSTART.md)
- Release documentation (docs/RELEASES.md)
- Build icon guide (build/README.md)
- Setup completion summary

### Development
- Electron 28 integration
- electron-builder configuration
- macOS code signing support
- Windows installer (NSIS)
- DMG creation for macOS
- GitHub Actions CI/CD
- Automated release workflow

## [Previous Versions]

See git history for web-only versions and development history.

---

## Release Types

- **Added** - New features
- **Changed** - Changes in existing functionality
- **Deprecated** - Soon-to-be removed features
- **Removed** - Removed features
- **Fixed** - Bug fixes
- **Security** - Security fixes

## Links

- [Latest Release](https://github.com/wesworldio/ww-fx-1/releases/latest)
- [All Releases](https://github.com/wesworldio/ww-fx-1/releases)
- [Repository](https://github.com/wesworldio/ww-fx-1)
