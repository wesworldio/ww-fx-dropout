"""
Simple unit tests for filter configuration validation.
These tests validate that filter parameters are correctly set without requiring a browser.
"""

import pytest


def test_filter_parameter_updates():
    """Verify that all filter parameters have been updated according to Sam's feedback."""
    
    # Read the index.html file to verify filter parameters
    with open('index.html', 'r') as f:
        content = f.read()
    
    # Test cases for updated filters
    updates = {
        "upside_down": {
            "search": "Math.sin(x / 30) * 15",
            "description": "Wave distortion increased from 5 to 15 pixels",
        },
        "radial_squeeze": {
            "search": "const radius = Math.min(width, height) / 2, strength = 1.8;",
            "description": "Strength increased from 1.2 to 1.8",
        },
        "elastic_stretch": {
            "search": "const radius = Math.min(width, height) / 2, strength = 2.0;",
            "description": "Strength increased from 1.3 to 2.0",
        },
        "lens_distortion": {
            "search": "const k1 = 1.2, k2 = 0.6;",
            "description": "Coefficients increased from 0.7/0.3 to 1.2/0.6",
        },
        "multi_ripple_reduced": {
            "search": "const ripple1 = Math.sin(dist * 0.05) * 5;",
            "description": "First ripple reduced from 8 to 5",
        },
        "multi_ripple_reduced2": {
            "search": "const ripple2 = Math.sin(dist * 0.08) * 3;",
            "description": "Second ripple reduced from 5 to 3",
        },
        "multi_ripple_reduced3": {
            "search": "const ripple3 = Math.sin(dist * 0.12) * 2;",
            "description": "Third ripple reduced from 4 to 2",
        },
        "wave_distortion": {
            "search": "const waveX = Math.sin(dist * 0.08 + angle * 2) * 6;",
            "description": "Wave amplitude reduced from 10 to 6",
        },
        "squeeze_horizontal": {
            "search": "const strength = 1.4;",
            "description": "Horizontal squeeze strength increased from 0.9 to 1.4",
            "context": "applySqueezeHorizontal",
        },
        "squeeze_vertical": {
            "search": "const strength = 1.4;",
            "description": "Vertical squeeze strength increased from 0.9 to 1.4",
            "context": "applySqueezeVertical",
        },
        "complex_ripple_reduced": {
            "search": "const radialRipple = Math.sin(dist * 0.06) * 6;",
            "description": "Radial ripple reduced from 10 to 6",
        },
        "complex_ripple_reduced2": {
            "search": "const angularRipple = Math.sin(angle * 4) * 3;",
            "description": "Angular ripple reduced from 5 to 3",
        },
        "squish_face": {
            "search": "const strength = 1.1;",
            "description": "Squish face strength increased from 0.7 to 1.1",
            "context": "applySquishFace",
        },
        "stretch_face": {
            "search": "const strength = 1.4;",
            "description": "Stretch face strength increased from 0.9 to 1.4",
            "context": "applyStretchFace",
        },
        "warp_face": {
            "search": "const strength = 0.8;",
            "description": "Warp face strength increased from 0.5 to 0.8",
            "context": "applyWarpFace",
        },
        "warp_face_offset": {
            "search": "const warpX = strength * Math.sin(dy * Math.PI * 2) * 45;",
            "description": "Warp offset increased from 30 to 45",
        },
        "funny_stretch": {
            "search": "const strength = 1.2;",
            "description": "Funny stretch strength increased from 0.8 to 1.2",
            "context": "applyFunnyStretch",
        },
    }
    
    results = []
    for name, test in updates.items():
        search_str = test["search"]
        context = test.get("context", "")
        
        # Check if the string exists in the content
        if context:
            # Find the context first, then check for the search string within it
            context_pos = content.find(context)
            if context_pos != -1:
                # Look for the search string within the next 1000 characters
                section = content[context_pos:context_pos + 1000]
                found = search_str in section
            else:
                found = False
        else:
            found = search_str in content
        
        results.append({
            "name": name,
            "description": test["description"],
            "found": found,
        })
        
        if found:
            print(f"✓ {test['description']}")
        else:
            print(f"✗ {test['description']} - NOT FOUND")
    
    # Check that all updates were found
    failed = [r for r in results if not r["found"]]
    if failed:
        print(f"\n{len(failed)} filter parameter(s) not found:")
        for f in failed:
            print(f"  - {f['name']}: {f['description']}")
        pytest.fail(f"{len(failed)} filter parameters not correctly updated")
    
    print(f"\n✓ All {len(results)} filter parameters correctly updated!")


def test_getDistortedCoordinates_updates():
    """Verify getDistortedCoordinates function also has updated parameters."""
    
    with open('index.html', 'r') as f:
        content = f.read()
    
    # Find the getDistortedCoordinates function or calculateDistortionVector
    func_start = content.find("function calculateDistortionVector")
    if func_start == -1:
        func_start = content.find("function getDistortedCoordinates")
    
    assert func_start != -1, "Could not find distortion coordinate function"
    
    # Extract a larger chunk of the function (next 30000 characters to cover all cases)
    func_content = content[func_start:func_start + 30000]
    
    # Check key parameters in the wireframe distortion function
    checks = [
        ("const squeezeStrength = 1.8;", "radial_squeeze strength in coordinate function"),
        ("const squishStrength = 1.1;", "squish_face strength in coordinate function"),
        ("const stretchFaceStrength = 1.4;", "stretch_face strength in coordinate function"),
        ("const elasticStrength = 2.0;", "elastic_stretch strength in coordinate function"),
        ("const lensStrength = 0.7;", "lens_distortion strength in coordinate function (simplified)"),
        ("const warpStrength = 0.8;", "warp_face strength in coordinate function"),
        ("const funnyStretchStrength = 1.2;", "funny_stretch strength in coordinate function"),
        # Also check the updated squeeze values in coordinate function
        ("const squeezeHFactor = 1.0 - 1.4", "squeeze_horizontal factor in coordinate function"),
        ("const squeezeVFactor = 1.0 - 1.4", "squeeze_vertical factor in coordinate function"),
    ]
    
    results = []
    for check_str, description in checks:
        found = check_str in func_content
        results.append((description, found))
        if found:
            print(f"✓ {description}")
        else:
            print(f"✗ {description} - NOT FOUND")
    
    failed = [desc for desc, found in results if not found]
    if failed:
        print(f"\n{len(failed)} coordinate function parameter(s) not found")
        pytest.fail(f"{len(failed)} parameters not updated in coordinate function")
    
    print(f"\n✓ All {len(results)} coordinate function parameters correctly updated!")


def test_filter_list_completeness():
    """Verify all expected filters are present in the code."""
    
    with open('index.html', 'r') as f:
        content = f.read()
    
    expected_filters = [
        "ultimate_distortion",
        "water_ripple",
        "pincushion",
        "upside_down",
        "multi_ripple",
        "radial_squeeze",
        "elastic_stretch",
        "lens_distortion",
        "wave_distortion",
        "squeeze_horizontal",
        "squeeze_vertical",
        "radial_wobble",
        "complex_ripple",
        "squish_face",
        "stretch_face",
        "funhouse_mirror",
        "pinch_cheeks",
        "bulge_eyes",
        "warp_face",
        "funny_squash",
        "funny_stretch",
        "wobble_face",
    ]
    
    missing = []
    for filter_name in expected_filters:
        # Check if filter appears in applyXXX function definition
        func_name = ''.join(word.capitalize() for word in filter_name.split('_'))
        search_pattern = f"apply{func_name}("
        
        if search_pattern not in content:
            missing.append(filter_name)
            print(f"✗ Filter '{filter_name}' not found")
        else:
            print(f"✓ Filter '{filter_name}' present")
    
    if missing:
        pytest.fail(f"{len(missing)} filters not found: {', '.join(missing)}")
    
    print(f"\n✓ All {len(expected_filters)} expected filters are present!")


def test_sam_feedback_summary():
    """Display summary of Sam's feedback and implementation status."""
    
    feedback_summary = {
        "★ Favorites (Great & Good)": [
            "ultimate_distortion ⭐ Great",
            "water_ripple ⭐ Great",
            "radial_wobble ⭐ Great",
            "bulge_eyes ⭐ Great",
            "pincushion ✓ Good",
            "funhouse_mirror ✓ Good",
            "pinch_cheeks ✓ Good",
            "funny_squash ✓ Good",
            "wobble_face ✓ Good",
        ],
        "Too little → Increased": [
            "upside_down",
            "radial_squeeze",
            "elastic_stretch",
            "lens_distortion",
            "squeeze_horizontal",
            "squeeze_vertical",
            "squish_face",
            "stretch_face",
            "warp_face",
            "funny_stretch",
        ],
        "Too much → Decreased": [
            "multi_ripple",
            "wave_distortion",
            "complex_ripple",
        ],
    }
    
    print("\n" + "="*60)
    print("FILTER UPDATE SUMMARY (Based on Sam's Feedback)")
    print("="*60)
    
    total_filters = 0
    for category, filters in feedback_summary.items():
        print(f"\n{category}: {len(filters)} filters")
        for f in filters:
            print(f"  • {f}")
        total_filters += len(filters)
    
    print("\n" + "="*60)
    print(f"Total filters reviewed: {total_filters}")
    print("Favorites group now appears first in UI!")
    print("="*60 + "\n")
    
    # This test always passes - it's just informational
    assert True


if __name__ == "__main__":
    pytest.main([__file__, "-v", "-s"])
