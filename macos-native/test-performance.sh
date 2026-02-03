#!/bin/bash
# Quick test script for both Python and Native versions

echo "╔════════════════════════════════════════╗"
echo "║  WesWorld FX - Performance Test        ║"
echo "╚════════════════════════════════════════╝"
echo ""

# Check if we're on Mac
if [[ "$OSTYPE" != "darwin"* ]]; then
    echo "❌ This script is for macOS only"
    exit 1
fi

cd "$(dirname "$0")"

echo "📦 Checking dependencies..."
echo ""

# Check Python
if ! command -v python3 &> /dev/null; then
    echo "❌ Python3 not found. Install from python.org"
    exit 1
fi
echo "✅ Python3: $(python3 --version)"

# Check if opencv is installed
if ! python3 -c "import cv2" 2>/dev/null; then
    echo "⚠️  OpenCV not installed"
    echo "   Installing now..."
    pip3 install opencv-python numpy
fi
echo "✅ OpenCV installed"

# Check Xcode tools
if ! command -v swift &> /dev/null; then
    echo "⚠️  Swift not found (needed for native version)"
    echo "   Install with: xcode-select --install"
    SWIFT_OK=false
else
    echo "✅ Swift: $(swift --version | head -n1)"
    SWIFT_OK=true
fi

echo ""
echo "═══════════════════════════════════════════"
echo ""

# Offer choices
echo "Choose version to test:"
echo ""
echo "  1) Python/OpenCV   (30-45 FPS, easy)"
echo "  2) Native/Metal    (60+ FPS, best)"
echo "  3) Run both        (compare side-by-side)"
echo ""
read -p "Choice [1-3]: " choice

case $choice in
    1)
        echo ""
        echo "🐍 Launching Python version..."
        echo "   Expected FPS: 30-45"
        echo ""
        python3 python-launcher.py
        ;;
    2)
        if [ "$SWIFT_OK" = false ]; then
            echo "❌ Swift not available. Install Xcode tools first."
            exit 1
        fi
        echo ""
        echo "⚡ Building and launching Native version..."
        echo "   Expected FPS: 60+"
        echo ""
        make run
        ;;
    3)
        echo ""
        echo "📊 Running both for comparison..."
        echo ""
        echo "First: Python version (30-45 FPS expected)"
        read -p "Press Enter to start Python test..."
        python3 python-launcher.py
        
        if [ "$SWIFT_OK" = true ]; then
            echo ""
            echo "Next: Native version (60+ FPS expected)"
            read -p "Press Enter to start Native test..."
            make run
        else
            echo ""
            echo "⚠️  Skipping native (Swift not available)"
        fi
        ;;
    *)
        echo "Invalid choice"
        exit 1
        ;;
esac

echo ""
echo "✅ Test complete!"
echo ""
echo "Performance tips:"
echo "  • Close other apps for best FPS"
echo "  • Plug in MacBook (battery mode throttles GPU)"
echo "  • Use 720p camera resolution"
echo ""
