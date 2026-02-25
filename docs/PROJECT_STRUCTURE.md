# Project Structure & Organization

## Overview

WesWorldFX is a visual effects application with primary focus on **macOS native** (Xcode/Swift) as the main target, with a **web** version maintained for testing, comparison, and alternative access.

## Directory Structure

### Core Application Directories

- **`macos-native/`** - Primary development target
  - Swift/Objective-C implementation
  - Xcode project configuration
  - Native macOS UI and performance optimizations
  - Filter implementations and testing

- **`static/`** - Static web assets
  - CSS, fonts, and other static resources for web target

- **`assets/`** - Application assets
  - Images, icons, and other media resources

- **`build/`** - Build output and configuration
  - macOS entitlements and build scripts
  - Platform-specific build artifacts

### Development & Testing

- **`tests/`** - Test suite for automated testing
- **`scripts/`** - Utility scripts for development
- **`scenes/`** - Test scenes or sample data

### Web Target

- **`index.html`** - Main web interface
- **`web-grid-generator.html`** - Grid generator web tool
- **`wrangler.jsonc`** - Cloudflare Workers configuration

### Documentation

- **`docs/`** - Complete documentation
  - User guides and setup instructions
  - Technical documentation
  - Performance tips and optimization guides
  - CHANGELOG, release notes, and status

### Configuration & Deployment

- **`Makefile`** - Build automation
- **`package.json`** - Node.js dependencies (for web/build)
- **`config.json`** - Application configuration
- **`build-info.json`** - Build metadata

### Archived/Legacy

- **`archive/`** - Legacy code and experiments
  - Electron implementation (superseded)
  - WebAssembly builds (experimental)
  - HTML-based editors (legacy)
  - Analysis scripts and test outputs

### Project Metadata

- **`README.md`** - Main project readme
- **`LICENSE`** - License information
- **`CNAME`** - Domain configuration

## Primary Development Path

1. **macOS Native** (`macos-native/`)
   - Main application written in Swift
   - Native performance and integration
   - Primary testing and development

2. **Web Version** (root HTML files)
   - `index.html` - Main web interface
   - `web-grid-generator.html` - Web tool for grid generation
   - Used for testing and cross-platform comparison

## Getting Started

- See `docs/QUICKSTART_MAC_NATIVE.md` for macOS native app setup
- See `docs/README.md` for general documentation index
- See `docs/MACOS_NATIVE_REFACTOR.md` for technical architecture details

## Build & Run

```bash
# macOS native
make build-native
make run-native

# Web
make build-web
make run-web
```

For detailed build commands, see `docs/MAKEFILE_COMMANDS.md`
