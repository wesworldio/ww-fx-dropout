# Custom Bulge Filters - User Guide

## Overview

WesWorld FX now includes a powerful **Custom Bulge Filter** feature, similar to Photoshop's Liquify tool. This allows you to create your own custom distortion effects by placing multiple bulge and pinch points anywhere in the frame.

## Features

✨ **Multiple Control Points** - Add unlimited bulge/pinch points to create complex effects  
💾 **Persistent Storage** - Custom filters are automatically saved and persist across app restarts  
📦 **Export/Import** - Share your custom filters with others or back them up  
🎨 **Visual Editor** - Interactive canvas with real-time preview  
⚡ **GPU Accelerated** - Custom filters run at full 60 FPS using Metal compute shaders  

## Creating a Custom Bulge Filter

### Method 1: Keyboard Shortcut
Press **B** key while the app is running to open the Custom Bulge Filter Editor.

### Method 2: Menu Bar
Navigate to **Filters → Create Custom Bulge Filter...**

## Using the Editor

### Adding Points
1. **Click** anywhere on the preview to add a bulge point (pushes pixels outward)
2. **Shift + Click** to add a pinch point (pulls pixels inward)
3. Points appear as colored circles with numbers

### Moving Points
- Click and drag any point to reposition it
- The effect updates in real-time

### Adjusting Properties
When a point is selected, use the sliders to adjust:

- **Radius** (0.05 - 0.50): Size of the effect area
- **Strength** (-1.0 to 1.0): 
  - Positive values = Bulge effect (push outward)
  - Negative values = Pinch effect (pull inward)

### Point Colors
- 🟡 Yellow center = Bulge effect (positive strength)
- 🔴 Red center = Pinch effect (negative strength)
- 🟢 Green circle = Unselected point
- 🔵 Blue circle = Selected point

### Saving Your Filter
1. Enter a descriptive name in the "Filter Name" field
2. Click "Save Filter" or press Enter
3. Your filter appears in the main filter dropdown with a 💎 icon

## Managing Custom Filters

### Using Custom Filters
- Custom filters appear at the bottom of the filter dropdown with a 💎 icon
- Select them like any other filter
- Use arrow keys ↑↓ to browse through filters
- Press **R** to reload the filter list after importing

### Deleting a Custom Filter
Press **N** or go to **Filters → Manage Custom Filters...**

### Import/Export

#### Exporting All Filters
1. Press **N** key or **Filters → Manage Custom Filters...**
2. Click "Export All"
3. Choose a location and save the `.wwfxbulge` file

#### Exporting a Single Filter
1. **Filters → Export Custom Filters...**
2. The file will include all your custom filters

#### Importing Filters
1. Press **N** key or **Filters → Import Custom Filters...**
2. Select a `.wwfxbulge` file
3. Imported filters are automatically merged with your existing filters
4. If a filter with the same name exists, it's imported as "Name (Imported)"

## File Format

Custom filters are saved in JSON format with the extension `.wwfxbulge`:

```json
{
  "version": "1.0",
  "appName": "WesWorld FX",
  "exportDate": "2026-02-05T10:30:00Z",
  "filters": [
    {
      "id": "UUID",
      "name": "My Custom Effect",
      "points": [
        {
          "x": 0.5,
          "y": 0.5,
          "radius": 0.15,
          "strength": 0.65
        }
      ],
      "createdDate": "2026-02-05T10:00:00Z",
      "modifiedDate": "2026-02-05T10:25:00Z"
    }
  ]
}
```

## Tips & Tricks

### Creating Realistic Effects
- Start with subtle strength values (0.3 - 0.5)
- Use multiple small points instead of one large point
- Mix bulge and pinch points for complex distortions

### Face Filters
- Place bulge points at eye positions for eye enlargement
- Use pinch points at cheek positions for face slimming
- Combine multiple points for cartoon-like effects

### Symmetrical Effects
- Click on both left and right sides at the same position
- Keep radius and strength consistent for balanced effects
- Use grid overlay (press **W**) to visualize the distortion

### Performance
- Custom filters with many points (10+) may impact performance
- Keep point count under 8 for optimal 60 FPS performance
- More complex filters work great for recording/screenshots

## Keyboard Shortcuts

| Key | Action |
|-----|--------|
| **B** | Open Custom Bulge Filter Editor |
| **N** | Manage Custom Filters (Import/Export/Delete) |
| **R** | Reload filter list (after importing) |
| **Tab** | Toggle UI overlay |
| **W** | Toggle grid overlay (visualize distortion) |
| **Space** | Random filter |
| **↑↓** | Browse filters |

## Technical Details

### Storage Location
Custom filters are stored in UserDefaults under the key:
```
com.wesworld.fx.customBulgeFilters
```

### Metal Shader
Custom bulge filters use the `custom_bulge` Metal compute shader with:
- Per-pixel distortion calculation
- Multiple point accumulation
- Smooth falloff curves
- Sub-pixel sampling

### Performance
- GPU-accelerated using Metal compute shaders
- 60 FPS at 1080p with up to 8 bulge points
- Real-time processing with zero lag
- Grid overlay shows exact distortion mapping

## Troubleshooting

**Q: My custom filter isn't showing up in the list**  
A: Press **R** to reload the filter list, or restart the app.

**Q: Can I edit an existing custom filter?**  
A: Currently, you'll need to create a new filter. Delete the old one using **N → Delete All**.

**Q: The editor preview is black**  
A: Make sure camera permissions are granted and the camera is working in the main window first.

**Q: Import failed**  
A: Verify the file has the `.wwfxbulge` extension and is valid JSON format.

**Q: Performance is slow with my custom filter**  
A: Try reducing the number of points or the point radius. 8 points is optimal for 60 FPS.

## Examples

### Big Eyes Effect
- 2 bulge points at eye positions
- Radius: 0.12
- Strength: 0.8

### Slim Face Effect
- 2 pinch points at cheek positions
- Radius: 0.15
- Strength: -0.4

### Funhouse Mirror
- Multiple alternating bulge/pinch points across the frame
- Radius: 0.2
- Strength: Alternating 0.6 / -0.6

### Cartoon Nose
- 1 large bulge point at nose position
- Radius: 0.08
- Strength: 1.0

## Future Enhancements

Planned features for future versions:
- Edit existing custom filters
- Preset templates (Big Eyes, Slim Face, etc.)
- Animation/time-based effects
- Preview with/without grid overlay
- Copy/paste points between filters
- Undo/redo in editor

---

**WesWorld FX v2.1.2** - © 2026 WesWorld  
For support and updates, visit: https://wesworld.io
