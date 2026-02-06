#!/bin/bash

# Create macOS icon from PNG source
# Requires: build/icon-source.png (512x512 or larger)

if [ ! -f "build/icon-source.png" ]; then
    echo "Error: build/icon-source.png not found"
    echo "Please provide a 512x512 PNG image as source"
    exit 1
fi

echo "Creating macOS icon..."

# Create iconset directory
mkdir -p build/icon.iconset

# Generate different sizes
sips -z 16 16     build/icon-source.png --out build/icon.iconset/icon_16x16.png
sips -z 32 32     build/icon-source.png --out build/icon.iconset/icon_16x16@2x.png
sips -z 32 32     build/icon-source.png --out build/icon.iconset/icon_32x32.png
sips -z 64 64     build/icon-source.png --out build/icon.iconset/icon_32x32@2x.png
sips -z 128 128   build/icon-source.png --out build/icon.iconset/icon_128x128.png
sips -z 256 256   build/icon-source.png --out build/icon.iconset/icon_128x128@2x.png
sips -z 256 256   build/icon-source.png --out build/icon.iconset/icon_256x256.png
sips -z 512 512   build/icon-source.png --out build/icon.iconset/icon_256x256@2x.png
sips -z 512 512   build/icon-source.png --out build/icon.iconset/icon_512x512.png
sips -z 1024 1024 build/icon-source.png --out build/icon.iconset/icon_512x512@2x.png

# Create icns file
iconutil -c icns build/icon.iconset -o build/icon.icns

# Clean up
rm -rf build/icon.iconset

echo "✅ Created build/icon.icns"

# For Windows, use ImageMagick if available
if command -v convert &> /dev/null; then
    echo "Creating Windows icon..."
    convert build/icon-source.png -define icon:auto-resize=256,128,96,64,48,32,16 build/icon.ico
    echo "✅ Created build/icon.ico"
else
    echo "⚠️  ImageMagick not found - skipping Windows icon"
    echo "   Install with: brew install imagemagick"
    echo "   Or create icon.ico manually"
fi

echo ""
echo "Icons created successfully!"
echo "Run 'npm run build' to create installers"
