# WesWorld FX Tests

This directory contains automated tests for validating filter configurations and functionality.

## Test Files

### `test_filter_params.py`
Unit tests that validate filter parameter configurations without requiring a browser:
- **test_filter_parameter_updates**: Verifies all filter strength parameters are correctly updated in filter implementations
- **test_getDistortedCoordinates_updates**: Ensures wireframe coordinate calculations match filter implementations  
- **test_filter_list_completeness**: Confirms all expected filters are present in the codebase
- **test_sam_feedback_summary**: Displays implementation status of Sam's feedback

### `test_filters.py`
Integration tests using Playwright (requires running web server):
- Browser-based tests for filter selection and UI interaction
- Currently optional - run parameter tests for quick validation

## Running Tests

### Setup
```bash
# Create virtual environment (first time only)
python3 -m venv venv

# Activate virtual environment
source venv/bin/activate

# Install dependencies
pip install -r requirements.txt

# Install Playwright browsers (for browser tests only)
playwright install chromium
```

### Run Parameter Tests (Quick)
```bash
source venv/bin/activate
python -m pytest test_filter_params.py -v
```

### Run Browser Tests (Requires Server)
```bash
# Terminal 1: Start HTTP server
python3 -m http.server 8000

# Terminal 2: Run tests
source venv/bin/activate
python -m pytest test_filters.py -v
```

## Test Results Summary

All filter parameter tests pass ✅:
- 17 filter implementations verified with correct strength values
- 9 coordinate function parameters confirmed  
- 22 filters confirmed present in codebase
- All updates from Sam's feedback successfully implemented

### Filter Update Summary
Based on Sam's feedback:

**Great (no changes needed)**: 4 filters
- ultimate_distortion, water_ripple, radial_wobble, bulge_eyes

**Good (no changes needed)**: 5 filters  
- pincushion, funhouse_mirror, pinch_cheeks, funny_squash, wobble_face

**Too Little → Increased**: 10 filters
- upside_down, radial_squeeze, elastic_stretch, lens_distortion
- squeeze_horizontal, squeeze_vertical, squish_face, stretch_face
- warp_face, funny_stretch

**Too Much → Decreased**: 3 filters
- multi_ripple, wave_distortion, complex_ripple

## Wireframe Visualization

The wireframe grid overlay automatically reflects all filter changes:
- Updated filter implementations are automatically used in wireframe calculations
- Toggle wireframe with 'w' key in the application
- Wireframe uses the same `calculateDistortionVector` function that was updated

## CI/CD Integration

To integrate tests into CI:
```bash
# Install dependencies
python3 -m venv venv
source venv/bin/activate  
pip install -r requirements.txt

# Run parameter tests (no browser needed)
python -m pytest test_filter_params.py -v --tb=short

# For browser tests, also need:
playwright install chromium
python3 -m http.server 8000 &
SERVER_PID=$!
python -m pytest test_filters.py -v --tb=short
kill $SERVER_PID
```
