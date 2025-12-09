# Archived Code

This directory contains code that is not used by the WASM version (`index.html`). The WASM version runs entirely client-side and does not require a Python backend.

## Archive Structure

### `websocket-version/`
WebSocket-based client code that connects to a Python backend:
- `index.html` - WebSocket client HTML file
- `filters.js` - JavaScript filter implementations (not used by WASM version)

### `python-backend/`
Python backend files used by the WebSocket version:
- `web_server.py` - FastAPI WebSocket server
- `face_filters.py` - Python filter implementations
- `interactive_filters.py` - Interactive filter viewer
- `daemon_interactive.py` - Daemon for interactive filters
- `generate_comparison.py` - Filter comparison generator
- `logger.py` - JSON logging utility
- `update_checker.py` - Auto-update checker
- `test_daemon_logging.py` - Test script for daemon logging

### `tests-websocket/`
Test files for the WebSocket version:
- `test_web_e2e.py` - End-to-end tests for web server
- `test_filter_processing.py` - Filter processing tests

### `scripts-backend/`
Scripts that depend on the Python backend:
- `dev_server.py` - Development server that runs web server and WASM watcher
- `validate_filters.py` - Filter validation script

### `python-files/`
Python dependency files and old Makefile:
- `requirements.txt` - Python dependencies for backend (opencv-python, fastapi, uvicorn, etc.)
- `requirements-test.txt` - Test dependencies (pytest, playwright, etc.)
- `Makefile` - Original Makefile with all Python backend commands (filters, web server, tests, etc.)

## Current Active Code

The WASM version (`index.html` in the root) uses:
- MediaPipe Face Detection (from CDN)
- WebAssembly module (`wasm/wwfx_module.wasm`)
- Client-side JavaScript (embedded in `index.html`)
- No Python backend required

## Restoring Archived Code

If you need to restore the WebSocket version:
1. Copy files from `archive/websocket-version/` back to `static/`
2. Copy files from `archive/python-backend/` back to `src/`
3. Copy test files from `archive/tests-websocket/` back to `tests/`
4. Copy scripts from `archive/scripts-backend/` back to `scripts/`
5. Install Python dependencies: `pip install -r requirements.txt`

