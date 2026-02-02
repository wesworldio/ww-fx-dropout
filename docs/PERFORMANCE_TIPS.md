# Performance Optimization Guide

## Overview

This guide provides tips for achieving smooth camera performance with WesWorld FX filters.

## Recent Performance Improvements (v1.0.0)

The following optimizations have been implemented to reduce camera lag:

### 1. **Adjustable Quality Presets (NEW!)**

You can now choose between two quality presets:

- **1080p (Best Performance)** - Default setting, optimized for smooth operation
  - Resolution: 640x480 to 1920x1080
  - Recommended for most users
  - Lower CPU/memory usage
  - Smoother roulette and filter switching

- **4K (Best Quality)** - For high-end devices
  - Resolution: 1280x720 to 3840x2160
  - Higher quality video output
  - Requires powerful hardware
  - Best for recording/streaming

**How to change:** Look for the "Quality Preset" dropdown in the settings panel, select your preference, and restart the camera.

### 2. **Reduced Frame Rate (60fps → 30fps)**
- Target frame rate lowered from 60fps to 30fps
- Provides smoother experience with less processing overhead
- Still maintains fluid video for most use cases

### 3. **Lower Video Resolution**
- Default resolution reduced to 720p-1080p range (from 4K)
- Constraints: 640x480 minimum, 1280x720 ideal, 1920x1080 maximum
- Significantly reduces processing load while maintaining quality

### 4. **Canvas Processing Cap**
- Canvas size capped at 1920x1080 regardless of camera resolution
- Prevents excessive processing on high-resolution cameras
- Automatically scales down larger inputs

### 5. **Roulette Optimization**
- Cycle interval increased from 100ms to 200ms
- Number of cycles reduced from 10 to 8
- Reduces rapid filter switching that causes performance spikes

## User Tips for Best Performance

### Quality Preset Selection

**Start with 1080p preset (default):**
- Best for most users and devices
- Smooth performance on mid-range hardware
- Still great quality for streaming/recording
- Lower resource usage

**Try 4K preset if:**
- You have a high-end desktop/laptop
- 1080p mode runs smoothly for you
- You need maximum quality for professional work
- Your camera supports 4K natively

**How to change quality:**
1. Open the settings panel (gear icon)
2. Find "Quality Preset" dropdown
3. Select either "1080p (Best Performance)" or "4K (Best Quality)"
4. Restart camera to apply

### Device-Specific Recommendations

#### **Desktop/Laptop**
- Use a wired internet connection if accessing remotely
- Close unnecessary browser tabs and applications
- Use Chrome or Edge for best WebAssembly performance
- Consider using a lower resolution camera (720p is ideal)

#### **Mobile Devices**
- Close background apps to free up memory
- Ensure good lighting (helps face detection)
- Use newer devices (2-3 years old or newer recommended)
- Portrait mode often performs better than landscape

### Browser Settings

1. **Hardware Acceleration**
   - Chrome: Settings → System → "Use hardware acceleration when available" (enable)
   - Firefox: Settings → Performance → "Use hardware acceleration when available" (enable)
   - Edge: Settings → System → "Use hardware acceleration when available" (enable)

2. **Clear Browser Cache**
   - Periodically clear cache to remove old WASM modules
   - Hard refresh the page (Ctrl+Shift+R or Cmd+Shift+R)

### Camera Settings

1. **Resolution**
   - Use 720p or 1080p cameras for best balance
   - 4K cameras may cause lag despite auto-scaling
   - Lower resolution = better performance

2. **Lighting**
   - Good lighting reduces camera processing overhead
   - Helps face detection run more efficiently
   - Reduces noise and improves filter quality

### Filter Selection

1. **Lighter Filters**
   - Simple filters (flip, rotate, mirror) perform best
   - Complex filters (distortion, masks) require more processing
   - Test different filters to find your device's sweet spot

2. **Avoid Rapid Switching**
   - Give each filter 1-2 seconds to stabilize
   - Rapid switching can cause temporary lag
   - Use roulette sparingly (now optimized but still intensive)

3. **Face Mask Filters**
   - Require face detection (most intensive)
   - Performance depends on face visibility
   - May lag on older devices

### Performance Testing

To test if optimizations are working:

1. Open browser console (F12)
2. Monitor frame processing times
3. Check for dropped frames or stuttering
4. Compare performance with/without filters active

### Troubleshooting Common Issues

#### **Camera Still Lagging**
- Try refreshing the page
- Check that no other apps are using the camera
- Lower your screen resolution
- Try a different browser
- Restart your device

#### **Roulette Feature Lags**
- This is normal - it rapidly cycles through filters
- New optimizations should help (8 cycles @ 200ms intervals)
- Wait for roulette to complete before making changes
- Consider using manual filter selection instead

#### **Specific Filters Cause Lag**
- Some filters are more computationally intensive
- Face masks require face detection overhead
- Complex distortions process more pixels
- This is expected behavior

#### **Initial Startup Lag**
- First load may be slower while WASM initializes
- MediaPipe face detection loads models
- Subsequent uses should be faster
- Cache helps with repeat visits

## Technical Details

### Frame Processing Pipeline

1. **Frame Rate Limiting** (30fps target)
2. **Video Capture** (scaled to max 1920x1080)
3. **Face Detection** (if needed by filter)
4. **Filter Application** (WASM or JavaScript)
5. **Canvas Rendering**

Each step is optimized to minimize latency and maximize throughput.

### Browser Compatibility

Best performance:
- Chrome/Edge (Chromium-based) - Excellent
- Firefox - Good
- Safari - Good
- Mobile Chrome/Safari - Fair to Good (device-dependent)

## Future Improvements

Planned optimizations:
- Adaptive frame rate based on device performance
- Filter complexity indicators
- Performance mode toggle
- Web Worker offloading for heavy filters
- GPU acceleration where available

## Feedback

If you continue to experience lag after these optimizations, please provide:
- Device type and specs
- Browser and version
- Camera resolution
- Specific filters causing issues
- Console logs (if applicable)

This helps us further optimize the experience for all users.
