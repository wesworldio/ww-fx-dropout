#!/bin/bash
# Compile Metal shaders to metallib for macOS release builds

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
METAL_FILE="$SCRIPT_DIR/WesWorldFX/Metal/Shaders.metal"
OUTPUT_METALLIB="$SCRIPT_DIR/Shaders.metallib"
BUNDLE_METALLIB="$SCRIPT_DIR/WesWorldFX.app/Contents/Resources/Shaders.metallib"

# Colors for output
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m' # No Color

if [ ! -f "$METAL_FILE" ]; then
    echo -e "${RED}Error: Shaders.metal not found at $METAL_FILE${NC}"
    exit 1
fi

echo -e "${YELLOW}Compiling Metal shaders...${NC}"
echo "  Source: $METAL_FILE"
echo "  Output: $OUTPUT_METALLIB"

# Compile using xcrun with optimizations
xcrun -sdk macosx metal -std=macos-metal2.4 -O3 "$METAL_FILE" -o "$OUTPUT_METALLIB"

# Check if compilation succeeded
if [ -f "$OUTPUT_METALLIB" ]; then
    SIZE=$(ls -lh "$OUTPUT_METALLIB" | awk '{print $5}')
    echo -e "${GREEN}✓ Shaders compiled successfully (${SIZE})${NC}"
    
    # Copy to app bundle if it exists
    if [ -d "$SCRIPT_DIR/WesWorldFX.app/Contents/Resources" ]; then
        cp "$OUTPUT_METALLIB" "$BUNDLE_METALLIB"
        echo -e "${GREEN}✓ Metallib copied to app bundle${NC}"
    fi
else
    echo -e "${RED}Error: Failed to compile shaders${NC}"
    exit 1
fi
