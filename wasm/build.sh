#!/bin/bash
# Build script for WASM module
# Requires Emscripten SDK to be installed and activated

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${SCRIPT_DIR}/build"
WASM_OUTPUT_DIR="${SCRIPT_DIR}/../static/wasm"

echo "Building WesWorld FX WASM module..."

# Check for Emscripten
if ! command -v emcc &> /dev/null; then
    echo "Error: Emscripten not found. Please install and activate Emscripten SDK."
    echo "Visit: https://emscripten.org/docs/getting_started/downloads.html"
    exit 1
fi

# Create build directory
mkdir -p "${BUILD_DIR}"
mkdir -p "${WASM_OUTPUT_DIR}"

# Create build directory for Emscripten
cd "${BUILD_DIR}"

# Configure with Emscripten
emcmake cmake "${SCRIPT_DIR}" \
    -DCMAKE_BUILD_TYPE=Release

# Build
emmake make -j$(nproc 2>/dev/null || echo 4)

# Copy output files
if [ -f "${BUILD_DIR}/wwfx_module.js" ]; then
    cp "${BUILD_DIR}/wwfx_module.js" "${WASM_OUTPUT_DIR}/"
    echo "✓ Copied wwfx_module.js"
fi

if [ -f "${BUILD_DIR}/wwfx_module.wasm" ]; then
    cp "${BUILD_DIR}/wwfx_module.wasm" "${WASM_OUTPUT_DIR}/"
    echo "✓ Copied wwfx_module.wasm"
fi

echo ""
echo "Build complete! Output files in: ${WASM_OUTPUT_DIR}"
echo ""
echo "To use in standalone.html:"
echo "  1. Copy wasm/js/wwfx-wasm.js to static/js/"
echo "  2. Update standalone.html to load the WASM module"
echo "  3. Replace filter implementations with WASM calls"

