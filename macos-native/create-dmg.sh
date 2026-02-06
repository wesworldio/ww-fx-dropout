#!/bin/bash
# Create DMG installer for WesWorldFX
set -e

# Read version from build-info.json
VERSION=$(python3 -c "import json; print(json.load(open('../build-info.json'))['version'])")
BUILD=$(python3 -c "import json; print(json.load(open('../build-info.json'))['buildNumber'])")

echo "Creating DMG for WesWorldFX v${VERSION} (Build ${BUILD})..."

APP_NAME="WesWorldFX"
DMG_NAME="WesWorld-FX-${VERSION}-mac-arm64.dmg"
VOLUME_NAME="WesWorld FX ${VERSION}"
SOURCE_APP="WesWorldFX.app"
TEMP_DMG="temp.dmg"

# Check if app exists
if [ ! -d "$SOURCE_APP" ]; then
    echo "Error: $SOURCE_APP not found. Build the app first."
    exit 1
fi

# Clean up old DMG if exists
rm -f "$DMG_NAME" "$TEMP_DMG"

# Create temporary DMG
echo "Creating temporary DMG..."
hdiutil create -size 50m -fs HFS+ -volname "$VOLUME_NAME" "$TEMP_DMG"

# Mount the DMG
echo "Mounting DMG..."
hdiutil attach "$TEMP_DMG" -mountpoint "/Volumes/$VOLUME_NAME"

# Copy app to DMG
echo "Copying app to DMG..."
cp -R "$SOURCE_APP" "/Volumes/$VOLUME_NAME/"

# Create Applications symlink
echo "Creating Applications symlink..."
ln -s /Applications "/Volumes/$VOLUME_NAME/Applications"

# Unmount
echo "Unmounting DMG..."
hdiutil detach "/Volumes/$VOLUME_NAME"

# Convert to compressed DMG
echo "Compressing DMG..."
hdiutil convert "$TEMP_DMG" -format UDZO -o "$DMG_NAME"

# Clean up temp DMG
rm -f "$TEMP_DMG"

echo ""
echo "✓ DMG created successfully: $DMG_NAME"
echo "  Size: $(du -h "$DMG_NAME" | cut -f1)"
