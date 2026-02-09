# Copy the latest build-info.json into the app bundle's Resources directory before building
# This script should be run before building the app (e.g., from your Makefile or build-native.sh)

set -e


# Use the script's directory to find the project root
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
RESOURCES_DIR="$PROJECT_ROOT/macos-native/WesWorldFX/Resources"
BUILD_INFO_SRC="$PROJECT_ROOT/build-info.json"
BUILD_INFO_DEST="$RESOURCES_DIR/build-info.json"

if [ ! -f "$BUILD_INFO_SRC" ]; then
    echo "Error: build-info.json not found at $BUILD_INFO_SRC"
    exit 1
fi

mkdir -p "$RESOURCES_DIR"
cp "$BUILD_INFO_SRC" "$BUILD_INFO_DEST"
echo "Copied build-info.json to $BUILD_INFO_DEST"
