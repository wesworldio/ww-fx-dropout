#!/bin/bash
# Generate all icon sizes from a source icon image
# Usage: ./scripts/generate_icons.sh path/to/icon.png

if [ $# -eq 0 ]; then
    echo "Usage: $0 <path-to-icon-image>"
    echo "Example: $0 ~/Downloads/wesworld-icon.png"
    exit 1
fi

SOURCE_ICON="$1"
ASSETS_DIR="assets"

if [ ! -f "$SOURCE_ICON" ]; then
    echo "Error: Source icon file not found: $SOURCE_ICON"
    exit 1
fi

# Check if sips (macOS) or convert (ImageMagick) is available
if command -v sips &> /dev/null; then
    echo "Using sips (macOS) to generate icons..."
    sips -z 180 180 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-180x180.png"
    sips -z 152 152 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-152x152.png"
    sips -z 144 144 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-144x144.png"
    sips -z 120 120 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-120x120.png"
    sips -z 114 114 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-114x114.png"
    sips -z 76 76 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-76x76.png"
    sips -z 72 72 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-72x72.png"
    sips -z 60 60 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-60x60.png"
    sips -z 57 57 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-57x57.png"
    sips -z 32 32 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-32x32.png"
    sips -z 16 16 "$SOURCE_ICON" --out "$ASSETS_DIR/icon-16x16.png"
    echo "✓ Icons generated successfully in $ASSETS_DIR/"
elif command -v convert &> /dev/null; then
    echo "Using ImageMagick to generate icons..."
    convert "$SOURCE_ICON" -resize 180x180 "$ASSETS_DIR/icon-180x180.png"
    convert "$SOURCE_ICON" -resize 152x152 "$ASSETS_DIR/icon-152x152.png"
    convert "$SOURCE_ICON" -resize 144x144 "$ASSETS_DIR/icon-144x144.png"
    convert "$SOURCE_ICON" -resize 120x120 "$ASSETS_DIR/icon-120x120.png"
    convert "$SOURCE_ICON" -resize 114x114 "$ASSETS_DIR/icon-114x114.png"
    convert "$SOURCE_ICON" -resize 76x76 "$ASSETS_DIR/icon-76x76.png"
    convert "$SOURCE_ICON" -resize 72x72 "$ASSETS_DIR/icon-72x72.png"
    convert "$SOURCE_ICON" -resize 60x60 "$ASSETS_DIR/icon-60x60.png"
    convert "$SOURCE_ICON" -resize 57x57 "$ASSETS_DIR/icon-57x57.png"
    convert "$SOURCE_ICON" -resize 32x32 "$ASSETS_DIR/icon-32x32.png"
    convert "$SOURCE_ICON" -resize 16x16 "$ASSETS_DIR/icon-16x16.png"
    echo "✓ Icons generated successfully in $ASSETS_DIR/"
else
    echo "Error: Neither sips (macOS) nor ImageMagick convert found."
    echo "Please install ImageMagick or use macOS with sips."
    exit 1
fi

