#!/bin/bash

# Create GitHub release v1.0.0 with local builds

cd /Users/wes/Sites/wesworld/ww-fx-dropout

echo "Creating GitHub release v1.0.0..."

gh release create v1.0.0 \
  --repo wesworldio/ww-fx-dropout \
  --title "WesWorld FX Desktop v1.0.0" \
  --notes-file release-notes.md \
  "dist/WesWorld FX-1.0.0.dmg#WesWorld-FX-1.0.0-mac-intel.dmg" \
  "dist/WesWorld FX-1.0.0-arm64.dmg#WesWorld-FX-1.0.0-mac-arm64.dmg" \
  "dist/WesWorld FX-1.0.0-mac.zip#WesWorld-FX-1.0.0-mac-intel.zip" \
  "dist/WesWorld FX-1.0.0-arm64-mac.zip#WesWorld-FX-1.0.0-mac-arm64.zip"

echo ""
echo "Release created successfully!"
echo "View at: https://github.com/wesworldio/ww-fx-dropout/releases/tag/v1.0.0"
