#!/bin/bash
# Create a proper Xcode project for WesWorld FX

set -e

PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
APP_NAME="WesWorldFX"
BUNDLE_ID="io.wesworld.fx.native"

echo "Creating Xcode project for $APP_NAME..."

cd "$PROJECT_DIR"

# Create a minimal Xcode project using xcodegen or manually
# For now, we'll create a Package.swift and generate from that

cat > Package.swift << 'EOF'
// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "WesWorldFX",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "WesWorldFX", targets: ["WesWorldFX"])
    ],
    targets: [
        .executableTarget(
            name: "WesWorldFX",
            path: "WesWorldFX/Sources",
            resources: [
                .process("../Resources"),
                .process("../Metal/Shaders.metal")
            ]
        )
    ]
)
EOF

echo "✓ Package.swift created"
echo ""
echo "To build:"
echo "  swift build"
echo ""
echo "To run:"
echo "  swift run"
echo ""
echo "To open in Xcode:"
echo "  open Package.swift"
echo ""
echo "Or use the Makefile:"
echo "  make build"
echo "  make run"
