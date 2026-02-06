# Filter Validation Guide

This document describes how to validate that filters are working correctly in the web application.

## Quick Validation

The easiest way to validate filters is using the validation script:

```bash
# Terminal 1: Start web server
make web

# Terminal 2: Run validation
make validate-filters
```

## What Gets Validated

The validation script (`scripts/validate_filters.py`) performs the following checks:

1. **API Endpoint Validation**
   - Tests that `/api/filters` endpoint is accessible
   - Verifies response format and structure
   - Confirms all expected filters are returned

2. **Filter Processing Validation**
   - Creates test frames with patterns
   - Applies filters from different categories:
     - Distortion filters (bulge, swirl, fisheye)
     - Color filters (black_white, sepia, negative)
     - Color map filters (thermal, plasma, jet)
     - Effect filters (blur, sharpen, pixelate)
   - Verifies filters process frames without errors
   - Confirms processed frames are valid

3. **Filter Category Coverage**
   - Tests filters from all major categories
   - Ensures both full-image and face-tracking filters work
   - Validates animated filters with frame counting

## Expected Output

When validation passes, you should see:

```
============================================================
WesWorld FX Filter Validation
============================================================

1. Testing API endpoint...
   ✅ SUCCESS: Found 90+ filters

2. Testing filter processing...
   ✅ bulge: Success
   ✅ swirl: Success
   ✅ fisheye: Success
   ✅ black_white: Success
   ✅ sepia: Success
   ✅ negative: Success
   ✅ thermal: Success
   ✅ plasma: Success
   ✅ jet: Success
   ✅ blur: Success
   ✅ sharpen: Success
   ✅ pixelate: Success

============================================================
Results: 12 passed, 0 failed
✅ All filter tests passed!
```

## Troubleshooting

### Server Not Running

If you see:
```
❌ FAILED: Cannot connect to server. Is it running?
```

**Solution:** Start the web server first:
```bash
make web
```

### Filter Processing Errors

If a specific filter fails:
```
❌ bulge: Error: ...
```

**Possible causes:**
1. Filter method not found in FaceFilter class
2. Filter requires face detection but test frame has no face
3. Filter has a bug in its implementation

**Solution:** Check the error message and verify the filter implementation in `face_filters.py`.

### API Returns Empty List

If you see:
```
❌ FAILED: No filters returned
```

**Solution:** 
1. Check that `web_server.py` is running
2. Verify the `get_all_filters()` function returns filters
3. Check server logs for errors

## Manual Testing

You can also manually test filters in the browser:

1. Start the web server: `make web`
2. Open `http://localhost:9000` in your browser
3. Click "Show Controls"
4. Select a camera and click "Start Camera"
5. Select different filters from the dropdown
6. Verify the video feed shows the filter applied

## Integration with CI/CD

The validation script can be integrated into CI/CD pipelines:

```yaml
# Example GitHub Actions step
- name: Validate Filters
  run: |
    make web &
    sleep 5
    make validate-filters
    pkill -f web_server.py
```

## Filter Categories Tested

The validation covers these filter categories:

- **Distortion**: bulge, swirl, fisheye, pinch, wave, mirror
- **Color**: black_white, sepia, negative, rainbow, tint filters
- **Color Maps**: thermal, plasma, jet, turbo, inferno, magma, viridis
- **Effects**: blur, sharpen, pixelate, glow, emboss
- **Artistic**: sketch, cartoon, anime, posterize
- **Special**: sam_reich, sam_face_mask

## Extending Validation

To add more filters to the validation, edit `scripts/validate_filters.py` and add filter names to the `test_filters` list in the `main()` function.

