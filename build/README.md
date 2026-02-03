# Build Assets

This directory contains assets needed for building the desktop app.

## Required Files

### macOS
- `icon.icns` - App icon for macOS (512x512 minimum)
- `dmg-background.png` - Background image for DMG installer (540x380px)

### Windows
- `icon.ico` - App icon for Windows (256x256 minimum)

### Linux
- `icons/` directory with PNG icons in various sizes (16x16, 32x32, 48x48, 64x64, 128x128, 256x256, 512x512)

## Creating Icons

### From PNG to ICNS (macOS)
```bash
# Create iconset directory
mkdir icon.iconset

# Generate different sizes
sips -z 16 16     icon.png --out icon.iconset/icon_16x16.png
sips -z 32 32     icon.png --out icon.iconset/icon_16x16@2x.png
sips -z 32 32     icon.png --out icon.iconset/icon_32x32.png
sips -z 64 64     icon.png --out icon.iconset/icon_32x32@2x.png
sips -z 128 128   icon.png --out icon.iconset/icon_128x128.png
sips -z 256 256   icon.png --out icon.iconset/icon_128x128@2x.png
sips -z 256 256   icon.png --out icon.iconset/icon_256x256.png
sips -z 512 512   icon.png --out icon.iconset/icon_256x256@2x.png
sips -z 512 512   icon.png --out icon.iconset/icon_512x512.png
sips -z 1024 1024 icon.png --out icon.iconset/icon_512x512@2x.png

# Create icns file
iconutil -c icns icon.iconset
```

### From PNG to ICO (Windows)
Use online tools like:
- https://convertio.co/png-ico/
- https://icoconvert.com/

Or use ImageMagick:
```bash
convert icon.png -define icon:auto-resize=256,128,96,64,48,32,16 icon.ico
```

## Default Icons

If you don't provide custom icons, the app will use the default Electron icon. You can use the existing icons from `assets/icons/` directory as a starting point.

To generate icons from the existing assets:
```bash
# Copy the largest icon as source
cp ../assets/icons/android-chrome-512x512.png icon-source.png

# Then follow the icon creation steps above
```

## DMG Background (macOS only)

Create a 540x380px image for the DMG installer background. This is optional - Electron Builder will use a default if not provided.
