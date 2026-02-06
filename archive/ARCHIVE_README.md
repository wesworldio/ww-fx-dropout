# Archived Files and Directories

This archive contains legacy code, alternative implementations, and experimental features that are no longer part of the primary development focus.

## Contents

### Directories

- **electron/**: Electron desktop app implementation (superseded by macOS native Xcode/Swift app)
- **wasm/**: WebAssembly build configuration (experimental, not actively maintained)
- **html-editor/**: Legacy HTML-based filter editors (replaced by macos-native implementation)
- **examples/**: Example videos and test materials
- **filter-grid-test-output/**: Filter grid comparison test results
- **web-filter-grid-test-output/**: Web-based grid test output
- **python-backend/**, **scripts-backend/**: Legacy Python backend implementations
- **tests-websocket/**, **websocket-version/**: WebSocket-based architecture experiments
- **standalone.html**: Standalone web version (see primary `index.html` and `web-grid-generator.html`)

### Scripts

Analysis and comparison scripts (kept for reference):

- `analyze_grid_patterns.py`
- `check_image_content.py`
- `check_straightness.py`
- `check_web_images.py`
- `compare_filter_grids.py`
- `compare_grids.py`
- `compare_grids_v2.py`
- `deep_analysis.py`
- `final_analysis.py`
- `final_grid_report.py`
- `final_pattern_analysis.py`

### Test Files

- `e2e-test.html`: Legacy end-to-end test file (use test suite in macos-native/)

### Media

- `comparison_*.png` / `comparison_*.jpg`: Filter comparison screenshots

## Project Focus

The project now focuses on:

1. **Primary**: macOS native app (`macos-native/`) - Swift/Xcode implementation
2. **Secondary**: Web target (`index.html`, `web-grid-generator.html`) - for testing and comparison

Files in this archive can be restored if needed but are not part of the active development workflow.
