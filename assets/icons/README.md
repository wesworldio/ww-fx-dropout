# Icon Files

Place the WesWorld FX logo icon files here with the following naming convention:

## Required Files

For favicon and iOS home screen support, you need the following icon sizes:

- `icon-180x180.png` - Primary iOS home screen icon (required)
- `icon-152x152.png` - iPad Pro home screen
- `icon-144x144.png` - iPad home screen
- `icon-120x120.png` - iPhone home screen (high-res)
- `icon-114x114.png` - iPhone home screen
- `icon-76x76.png` - iPad home screen
- `icon-72x72.png` - iPad home screen
- `icon-60x60.png` - iPhone home screen
- `icon-57x57.png` - iPhone home screen (legacy)
- `icon-32x32.png` - Standard favicon
- `icon-16x16.png` - Small favicon

## Quick Setup

If you have a single high-resolution icon (e.g., 512x512 or 1024x1024), you can generate all sizes using ImageMagick:

```bash
# Assuming you have icon.png (512x512 or larger)
convert icon.png -resize 180x180 assets/icons/icon-180x180.png
convert icon.png -resize 152x152 assets/icons/icon-152x152.png
convert icon.png -resize 144x144 assets/icons/icon-144x144.png
convert icon.png -resize 120x120 assets/icons/icon-120x120.png
convert icon.png -resize 114x114 assets/icons/icon-114x114.png
convert icon.png -resize 76x76 assets/icons/icon-76x76.png
convert icon.png -resize 72x72 assets/icons/icon-72x72.png
convert icon.png -resize 60x60 assets/icons/icon-60x60.png
convert icon.png -resize 57x57 assets/icons/icon-57x57.png
convert icon.png -resize 32x32 assets/icons/icon-32x32.png
convert icon.png -resize 16x16 assets/icons/icon-16x16.png
```

Or using sips on macOS:

```bash
# Assuming you have icon.png
sips -z 180 180 icon.png --out assets/icons/icon-180x180.png
sips -z 152 152 icon.png --out assets/icons/icon-152x152.png
sips -z 144 144 icon.png --out assets/icons/icon-144x144.png
sips -z 120 120 icon.png --out assets/icons/icon-120x120.png
sips -z 114 114 icon.png --out assets/icons/icon-114x114.png
sips -z 76 76 icon.png --out assets/icons/icon-76x76.png
sips -z 72 72 icon.png --out assets/icons/icon-72x72.png
sips -z 60 60 icon.png --out assets/icons/icon-60x60.png
sips -z 57 57 icon.png --out assets/icons/icon-57x57.png
sips -z 32 32 icon.png --out assets/icons/icon-32x32.png
sips -z 16 16 icon.png --out assets/icons/icon-16x16.png
```

## Note

The HTML references these files from the `assets/` directory (not `assets/icons/`), so after generating the icons, move them to the `assets/` directory:

```bash
mv assets/icons/*.png assets/
```

Or update the HTML paths if you prefer to keep them in `assets/icons/`.

