# 🚀 QUICK START - Mac Native Version

## Problem: Web version only getting 15-25 FPS

## Solution: Two new Mac-native versions

### 1️⃣ Python Version (30-45 FPS) - Try This First!

```bash
cd macos-native
pip3 install opencv-python numpy
python3 python-launcher.py
```

**Done!** You should see 30-45 FPS. That's 2-3x faster than the web version.

### 2️⃣ Native Version (60+ FPS) - For Maximum Speed

```bash
cd macos-native
make run
```

**Wait ~1 minute for compilation, then enjoy 60+ FPS!** 🎉

## Which Should I Use?

- **Just want it faster?** → Python (5 minutes, 2-3x speedup)
- **Want maximum FPS?** → Native (10 minutes, 3-4x speedup)
- **Need to modify filters?** → Python (easier to experiment)
- **Production app?** → Native (best performance & UX)

## What You Get

✅ All 23 filters working  
✅ Real-time FPS counter  
✅ Keyboard controls (arrows to switch filters)  
✅ Click to cycle filters  
✅ Same interface as web version  

## Performance Comparison

| Version | FPS | Setup Time |
|---------|-----|------------|
| Web (old) | 15-25 | 0 min |
| **Python** | **30-45** | **5 min** |
| **Native** | **60+** | **10 min** |

## Detailed Guides

📖 [Full Documentation](macos-native/README.md)  
📖 [Setup Guide](macos-native/SETUP_GUIDE.md)  
📖 [Performance Comparison](macos-native/PERFORMANCE_COMPARISON.md)  
📖 [Implementation Details](macos-native/IMPLEMENTATION_SUMMARY.md)  

## Troubleshooting

### Python: "cv2 not found"
```bash
pip3 install opencv-python
```

### Native: "xcode-select not found"
```bash
xcode-select --install
```

### Either: "Camera not working"
- Go to System Settings → Privacy & Security → Camera
- Enable camera access for the app

## That's It!

Pick your version and enjoy 2-4x faster performance! 🎉

For questions, see the [detailed documentation](macos-native/).
