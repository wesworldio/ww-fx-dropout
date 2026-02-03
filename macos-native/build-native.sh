#!/bin/bash
# Build script for WesWorld FX Native Mac App

set -e

echo "Building WesWorld FX Native Mac App..."

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="WesWorldFX"
BUNDLE_ID="io.wesworld.fx.native"

echo "Project Directory: $PROJECT_DIR"

# Check if Xcode is installed
if ! command -v xcodebuild &> /dev/null; then
    echo -e "${RED}Error: Xcode is not installed. Please install Xcode from the Mac App Store.${NC}"
    exit 1
fi

# Create Xcode project using swift package
cd "$PROJECT_DIR"

echo -e "${YELLOW}Creating Xcode project...${NC}"

# Create Package.swift for SPM
cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WesWorldFX",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "WesWorldFX", targets: ["WesWorldFX"])
    ],
    targets: [
        .executableTarget(
            name: "WesWorldFX",
            dependencies: [],
            path: "WesWorldFX/Sources",
            resources: [
                .process("../Resources"),
                .process("../Metal")
            ]
        )
    ]
)
EOF

# Generate Xcode project
echo -e "${YELLOW}Generating Xcode project...${NC}"
swift package generate-xcodeproj

echo -e "${GREEN}✓ Xcode project created successfully!${NC}"
echo ""
echo -e "${YELLOW}To build and run:${NC}"
echo "  1. Open WesWorldFX.xcodeproj in Xcode"
echo "  2. Select your Mac as the build target"
echo "  3. Press Cmd+R to build and run"
echo ""
echo -e "${YELLOW}Or build from command line:${NC}"
echo "  ./build-native.sh release"

if [ "$1" == "release" ]; then
    echo ""
    echo -e "${YELLOW}Building release version...${NC}"
    xcodebuild -project WesWorldFX.xcodeproj \
        -scheme WesWorldFX \
        -configuration Release \
        -derivedDataPath build \
        clean build
    
    echo -e "${GREEN}✓ Build complete!${NC}"
    echo "App location: build/Build/Products/Release/WesWorldFX"
fi
