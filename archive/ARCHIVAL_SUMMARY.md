# WesWorld FX - Archival Summary

This document describes what was archived from the root project directory to focus development on the macOS-native implementation.

## Date
February 6, 2026

## Rationale
The project is now focused exclusively on the native macOS app (Metal GPU acceleration, 60+ FPS). All other implementations and web-based versions have been archived to reduce clutter and clarify the project scope.

## Root Directory - Cleaned For macOS-Native

The following folders/files remain at the root level for active macOS-native development:

### Essential
- `macos-native/` - Main native macOS app (Swift + Metal)
- `build/` - macOS build resources (entitlements, icons, plist files)
- `docs/` - Project documentation (streamlined)
- `assets/` - Face masks and filter resources
- `scripts/` - Build helper scripts (git hooks, build-info generation)

### Project Files
- `README.md` - Main project readme (macOS-native focused)
- `CHANGELOG.md` - Project changelog
- `LICENSE` - Project license
- `Makefile` - Build system (macOS-native targets only)
- `build-info.json` - Build information

### Development
- `.github/` - GitHub configuration
- `.vscode/` - VS Code settings
- `.trunk/` - Trunk linter configuration
- `.venv/` - Python virtual environment (if present)
- `venv/` - Alternative Python environment

## Archived Items

### Old Implementation Documentation
```
archive/DESKTOP_APP_GUIDE.md              - Electron desktop app guide
archive/DESKTOP_QUICKSTART.md             - Old desktop quick start
archive/DESKTOP_SETUP_COMPLETE.md         - Legacy setup docs
archive/MACOS_NATIVE_REFACTOR.md          - Performance notes (historical)
archive/QUICKSTART_MAC_NATIVE.md          - Old native quickstart
archive/PERFORMANCE_FIXES.md              - Archived performance notes
archive/FILTER_COMPARISON_GUIDE.md        - Old comparison guide
archive/RELEASES_COMPLETE.md              - Release notes archive
```

### Web/Electron Implementation
```
archive/electron/                         - Electron app source
archive/static/                           - Web static assets
archive/index.html                        - Web interface
archive/package.json                      - Node.js package manifest
archive/package-lock.json                 - NPM lock file
archive/config.json                       - Web server config
archive/wrangler.jsonc                    - Cloudflare Workers config
archive/node_modules/                     - NPM dependencies
```

### WASM & WebAssembly
```
archive/wasm/                             - WebAssembly source (empty build/)
archive/wasm-archived/                    - Complete WASM project
archive/static/wasm/                      - Compiled WASM modules
archive/watch_wasm.py                     - WASM file watcher script
archive/create-release.sh                 - WASM release script
archive/generate_icons.sh                 - Icon generation (web)
```

### Testing & Examples
```
archive/tests/                            - Playwright E2E tests
archive/examples/                         - Example media files
archive/docs_archived/                    - Old implementation docs
  - testing.md
  - filter_validation.md
  - filters.md
  - implementation.md
  - project-summary.md
  - WASM_README.md
  - WASM_MIGRATION.md
  - UI_MATCHING_FEATURES.md
  - UI_OVERHAUL.md
  - VERIFICATION_REPORT.md
  - DAEMON_README.md
```

### Legacy Implementations
```
archive/python-backend/                   - Python backend filters
archive/python-files/                     - Python utilities
archive/scripts-backend/                  - Backend scripts
archive/websocket-version/                - WebSocket server version
archive/tests-websocket/                  - WebSocket tests
archive/scenes_archived/                  - UI scene definitions (JSON)
```

### Build Artifacts
```
archive/WesWorldFX.app/                   - Compiled macOS app
archive/dist/                             - Distribution build output
```

### Other
```
archive/CNAME                             - GitHub Pages domain config
archive/README.md                         - Original comprehensive README
```

## Documentation Organization

### Active (docs/)
- `README.md` - Index of current documentation
- `CHANGELOG.md` - Project changelog
- `PERFORMANCE_TIPS.md` - macOS performance optimization
- `filter_examples/` - Comparison images for all filters

### Archived (archive/docs_archived/)
- All old implementation and testing documentation
- Web/WASM specific guides
- Legacy feature documentation

## Scripts Cleanup

### Kept (scripts/)
- `generate_build_info.py` - Generates build info from git
- `update_build_info.py` - Updates build-info.json
- `setup_git_hooks.sh` - Installs git hooks
- `pre-commit-hook` - Git hook for auto-updating build-info

### Archived (archive/)
- `watch_wasm.py` - WASM file watcher (no longer needed)
- `create-release.bat` - Windows release script
- `create-release.sh` - Cross-platform release script
- `upload-release.sh` - Release upload script
- `generate_icons.sh` - Icon generation for web

## Makefile Changes

The root `Makefile` has been simplified to focus exclusively on macOS-native:

**Removed targets:**
- `wasm-build` - Build WASM module
- `wasm-clean` - Clean WASM artifacts
- `watch` - Watch WASM source files
- `daemon` - WASM watcher daemon
- `daemon-stop` - Stop daemon
- `daemon-status` - Check daemon status
- `daemon-logs` - View daemon logs

**Current targets:**
- `setup` - Create Xcode project
- `build` - Build debug version
- `release` - Build release version
- `run` - Build and run
- `xcode` - Open in Xcode
- `clean` - Clean artifacts
- `build-info` - Generate build info
- `setup-hooks` - Setup git hooks

## README Changes

The root `README.md` has been updated to:
- Focus exclusively on macOS-native app
- Emphasize 60+ FPS performance with Metal GPU
- Reference `macos-native/README.md` for details
- Link to `docs/` for additional information
- Remove all references to WASM, web, Python, Electron versions

## Migration Notes

If you need to reference or work with archived implementations:

1. **WASM/Web Version**: See `archive/wasm-archived/` and `archive/static/`
2. **Electron Desktop**: See `archive/electron/` and `archive/DESKTOP_APP_GUIDE.md`
3. **Python Backend**: See `archive/python-backend/`
4. **Testing Setup**: See `archive/tests/`
5. **Documentation**: See `archive/docs_archived/`

## Restoring Items

To restore archived items:
```bash
# Example: Restore WASM project
mv archive/wasm-archived wasm
mv archive/static/wasm static/wasm

# Example: Restore electron app
mv archive/electron electron
```

## Active Development Path

For macOS-native development:
1. Start with [README.md](../README.md)
2. Full details in [macos-native/README.md](../macos-native/README.md)
3. Setup: `make setup && make run`
4. Documentation: See [docs/README.md](../docs/README.md)
