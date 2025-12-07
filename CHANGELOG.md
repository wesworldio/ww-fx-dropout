# Changelog - Mac Standalone Version Enhancements

## New Features

### 🔄 Auto-Update System
- **Automatic update checking**: Checks GitHub for updates every 5 minutes (configurable)
- **Configurable branch**: Defaults to `main` branch, can be changed in `config.json`
- **Manual update pull**: Press `U` to check for updates or pull them
- **Update notifications**: Shows update available indicator in UI when updates are found
- **Git integration**: Automatically pulls updates from configured branch

**Configuration** (in `config.json`):
```json
{
  "updates": {
    "enabled": true,
    "branch": "main",
    "check_interval": 300,
    "auto_pull": false
  }
}
```

### ⭐ Favorites System
- **Save favorite filters**: Press `F` to toggle favorite status for current filter
- **Persistent storage**: Favorites are saved to `config.json`
- **Visual indicator**: Favorite filters show a ★ indicator in the UI

### 🎥 Recording Capability
- **Start/Stop recording**: Press `R` to toggle recording
- **Automatic file naming**: Recordings saved with timestamp to `recordings/` directory
- **Visual indicator**: Recording status shown in UI with ● RECORDING indicator
- **Format**: MP4 format using mp4v codec

### 🎨 Theme Support
- **Multiple themes**: Support for different color themes
- **Web theme compatibility**: Automatically converts web themes to standalone format
- **Configurable**: Set theme in `config.json` with `"theme": "theme_name"`
- **Default themes**: `default`, `wesworld`, `dropout` available

### 📹 Enhanced Camera Selection
- **Camera detection**: Automatically detects and lists all available cameras
- **Camera information**: Shows camera index and backend information
- **Persistent selection**: Remembers last used camera in config

### 🚀 Performance Improvements
- **Background update checks**: Update checking runs in background threads
- **Optimized frame processing**: Better frame handling and caching
- **Efficient UI rendering**: Improved overlay rendering performance

## New Keyboard Shortcuts

- **F**: Toggle favorite for current filter
- **R**: Start/Stop recording
- **U**: Check for updates / Pull updates (if available)
- **H**: Toggle UI overlay (existing)
- **SPACE**: Toggle auto-advance (existing)
- **←/→**: Navigate filters (existing)
- **Q**: Quit (existing)

## Configuration Updates

The `config.json` file now supports:

```json
{
  "camera_index": 1,
  "advance_interval": 0.1,
  "updates": {
    "enabled": true,
    "branch": "main",
    "check_interval": 300,
    "auto_pull": false,
    "last_commit": null,
    "last_check": 0
  },
  "favorites": ["sam_reich", "bulge", "swirl"],
  "theme": "default"
}
```

## File Structure

New files and directories:
- `update_checker.py`: Auto-update system
- `themes/default.json`: Default theme configuration
- `recordings/`: Directory for recorded videos (auto-created)

## Usage Examples

### Check for Updates Manually
Press `U` in the application, or run:
```bash
python3 update_checker.py
```

### Change Update Branch
Edit `config.json`:
```json
{
  "updates": {
    "branch": "develop"
  }
}
```

### Record a Video
1. Start the application: `make interactive`
2. Select your filter
3. Press `R` to start recording
4. Press `R` again to stop
5. Video saved to `recordings/recording_YYYYMMDD_HHMMSS.mp4`

### Use a Different Theme
Edit `config.json`:
```json
{
  "theme": "wesworld"
}
```

## Technical Details

### Update Checker
- Uses GitHub API to check for latest commit
- Compares with local git commit hash
- Supports configurable check intervals
- Handles network errors gracefully

### Recording
- Uses OpenCV VideoWriter
- MP4 format with mp4v codec
- Automatic timestamp-based naming
- Saves to dedicated recordings directory

### Themes
- JSON-based configuration
- RGB color values
- Supports both new format and legacy web format
- Automatic conversion from hex to RGB

## Backward Compatibility

All existing features remain unchanged:
- All keyboard shortcuts still work
- Config file structure is backward compatible
- Existing themes are automatically converted
- No breaking changes to filter functionality

