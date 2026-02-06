#!/bin/bash

# WesWorld FX Desktop - Installation Script

echo "🎬 WesWorld FX Desktop Setup"
echo "============================"
echo ""

# Check for Node.js
if ! command -v node &> /dev/null; then
    echo "❌ Node.js is not installed"
    echo "Please install Node.js from https://nodejs.org/"
    echo "Recommended version: 18.x or later"
    exit 1
fi

NODE_VERSION=$(node -v)
echo "✅ Node.js found: $NODE_VERSION"
echo ""

# Check for npm
if ! command -v npm &> /dev/null; then
    echo "❌ npm is not installed"
    exit 1
fi

NPM_VERSION=$(npm -v)
echo "✅ npm found: $NPM_VERSION"
echo ""

# Install dependencies
echo "📦 Installing dependencies..."
npm install

if [ $? -eq 0 ]; then
    echo ""
    echo "✅ Installation complete!"
    echo ""
    echo "🚀 Quick Start:"
    echo "  • Run app:      npm start"
    echo "  • Development:  npm run dev"
    echo "  • Build Mac:    npm run build:mac"
    echo "  • Build Win:    npm run build:win"
    echo "  • Build Both:   npm run build:all"
    echo ""
    echo "📖 For more information, see electron/README.md"
else
    echo ""
    echo "❌ Installation failed"
    echo "Please check the error messages above"
    exit 1
fi
