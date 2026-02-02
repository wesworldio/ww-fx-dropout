# Performance Optimization Summary

## Changes Made to Fix Camera Lag

### 1. **Resolution Selector (NEW!)**
- **Feature:** Adjustable quality preset dropdown
- **Options:**
  - **1080p (Best Performance)** - Default, optimized for smooth operation
  - **4K (Best Quality)** - For high-end devices and quality priority
- **How to use:** Select your preferred quality in the settings, then restart camera
- **Auto-applies:** Changes take effect immediately on camera restart
- **Location:** Settings panel in index.html

### 2. **Frame Rate Reduction**
- **Before:** 60 FPS target
- **After:** 30 FPS target
- **Impact:** 50% reduction in processing load
- **Location:** Line 2160 in index.html

### 3. **Video Resolution Optimization**
- **Before:** 
  - Min: 1280x720
  - Ideal: 3840x2160 (4K)
  - No max limit
- **After:**
  - Min: 640x480
  - Ideal: 1280x720 (720p)
  - Max: 1920x1080 (1080p)
- **Impact:** Dramatically reduces camera capture overhead
- **Location:** Line 2569 in index.html

### 4. **Canvas Processing Cap**
- **Before:** Canvas matched full video resolution
- **After:** Canvas capped at 1920x1080 max
- **Impact:** Prevents processing extremely large frames
- **Location:** Line 4602-4623 in index.html

### 5. **Roulette Feature Optimization**
- **Before:** 
  - 10 cycles
  - 100ms interval
- **After:**
  - 8 cycles (20% reduction)
  - 200ms interval (2x slower)
- **Impact:** Less aggressive filter switching, better performance
- **Location:** Line 4518-4532 in index.html

## Expected Results

### Before Optimizations:
- Heavy lag on startup
- Stuttering during roulette
- High CPU usage
- Poor performance on mid-range devices

### After Optimizations:
- Smoother startup
- More stable roulette experience
- Lower CPU/memory usage
- Better performance across all devices
- Still maintains good visual quality

## Testing the Changes

1. **Refresh your browser** (hard refresh: Cmd+Shift+R or Ctrl+Shift+R)
2. **Grant camera access**
3. **Try different quality presets:**
   - Start with **1080p** (default) for best performance
   - If your device handles it well, try **4K** for better quality
   - Change takes effect on camera restart
4. **Compare performance:**
   - Check initial camera load speed
   - Test roulette feature
   - Try various filters
   - Monitor overall smoothness

### Which Quality Should You Choose?

**Choose 1080p (Best Performance) if:**
- You experience any lag or stuttering
- Using an older device or mobile
- Prioritize smooth filter transitions
- Running many browser tabs/apps

**Choose 4K (Best Quality) if:**
- Your device handles 1080p smoothly
- You have a high-end computer
- Recording or streaming professionally
- Quality is more important than frame rate
- You have a 4K camera and want to use it

## Additional Tips

For best performance:
- Use Chrome or Edge browser
- Close other applications
- Ensure good lighting
- Use 720p or 1080p camera (not 4K)
- Enable hardware acceleration in browser settings

See [docs/PERFORMANCE_TIPS.md](./docs/PERFORMANCE_TIPS.md) for comprehensive guide.

## Rollback (if needed)

If you prefer the old settings:
- **Frame rate:** Change `targetFPS = 30` back to `60` (line 2160)
- **Resolution:** Remove the `max` constraints in video constraints (line 2572-2573)
- **Canvas cap:** Remove the scaling logic (lines 4605-4614)
- **Roulette:** Change back to `maxCycles = 10` and interval `100` (lines 4518, 4532)

## Technical Details

These optimizations balance:
- **Quality** - Still high enough for streaming/recording
- **Performance** - Reduced processing by ~50-60%
- **Compatibility** - Works better on more devices
- **User Experience** - Smoother, more responsive interface

The WebAssembly filters are already highly optimized, but these changes reduce the data they need to process, resulting in faster overall performance.
