#!/usr/bin/env python3
"""
Final comprehensive comparison report
"""
from PIL import Image
import numpy as np
import os

METAL_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/filter-grid-test-output"
WEB_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/web-filter-grid-test-output"

FILTERS = [
    "funhouse_mirror",
    "water_ripple",
    "funny_squash",
    "funny_stretch",
    "squeeze_horizontal",
    "squeeze_vertical",
    "warp_face",
    "wave_distortion",
    "elastic_stretch",
    "multi_ripple",
    "bulge_eyes"
]

def check_distortion(img_path):
    """
    Check if image shows actual distortion or is uniform
    Returns: (has_distortion, std_density, description)
    """
    if not os.path.exists(img_path):
        return False, 0, "FILE MISSING"
    
    img = np.array(Image.open(img_path).convert('RGB'))
    grid = (img[:, :, 0] + img[:, :, 1]) > 50
    
    h, w = grid.shape
    
    # Check regional density variation
    regions = [
        (0, h//3, 0, w//3),          # TL
        (0, h//3, 2*w//3, w),        # TR
        (h//3, 2*h//3, w//3, 2*w//3), # Center
        (2*h//3, h, 0, w//3),        # BL
        (2*h//3, h, 2*w//3, w),      # BR
    ]
    
    densities = []
    for (y1, y2, x1, x2) in regions:
        region = grid[y1:y2, x1:x2]
        density = np.sum(region) / region.size * 100
        densities.append(density)
    
    std = np.std(densities)
    avg = np.mean(densities)
    
    # Uniform = no distortion, Varied = has distortion
    if std < 0.8:
        return False, std, f"UNIFORM (std={std:.2f}, avg={avg:.1f}%) - NO DISTORTION"
    else:
        return True, std, f"DISTORTED (std={std:.2f}, avg={avg:.1f}%)"

print("=" * 80)
print("FINAL GRID COMPARISON REPORT - Metal vs Web")
print("=" * 80)
print()

results = {
    'match': [],
    'metal_no_distortion': [],
    'web_no_distortion': [],
    'both_no_distortion': [],
    'patterns_differ': []
}

for filter_name in FILTERS:
    metal_path = f"{METAL_DIR}/{filter_name}.png"
    web_path = f"{WEB_DIR}/{filter_name}.png"
    
    metal_distorted, metal_std, metal_desc = check_distortion(metal_path)
    web_distorted, web_std, web_desc = check_distortion(web_path)
    
    print(f"{filter_name}:")
    print(f"  Metal: {metal_desc}")
    print(f"  Web:   {web_desc}")
    
    # Categorize
    if not metal_distorted and not web_distorted:
        # Both straight - might match
        results['both_no_distortion'].append(filter_name)
        print(f"  ⚠️  BOTH SHOW NO DISTORTION - filter not working in either")
    elif not metal_distorted and web_distorted:
        # Metal straight, web distorted - Metal broken
        results['metal_no_distortion'].append(filter_name)
        print(f"  ❌ METAL NOT APPLYING FILTER - shows straight grid")
    elif metal_distorted and not web_distorted:
        # Metal distorted, web straight - Web broken
        results['web_no_distortion'].append(filter_name)
        print(f"  ❌ WEB NOT APPLYING FILTER - shows straight grid")
    else:
        # Both distorted but patterns differ
        results['patterns_differ'].append(filter_name)
        print(f"  ⚠️  BOTH DISTORTED BUT PATTERNS DIFFER")
    
    print()

print("=" * 80)
print("SUMMARY")
print("=" * 80)
print()

if results['match']:
    print(f"✅ MATCHING ({len(results['match'])}):")
    for f in results['match']:
        print(f"   • {f}")
    print()

if results['metal_no_distortion']:
    print(f"❌ METAL NOT APPLYING FILTER ({len(results['metal_no_distortion'])}):")
    print(f"   These filters show straight/uniform grids in Metal but distorted grids in Web.")
    print(f"   Metal implementation is NOT applying the filter effect.")
    for f in results['metal_no_distortion']:
        print(f"   • {f}")
    print()

if results['web_no_distortion']:
    print(f"❌ WEB NOT APPLYING FILTER ({len(results['web_no_distortion'])}):")
    print(f"   These filters show straight/uniform grids in Web but distorted grids in Metal.")
    print(f"   Web implementation is NOT applying the filter effect.")
    for f in results['web_no_distortion']:
        print(f"   • {f}")
    print()

if results['both_no_distortion']:
    print(f"⚠️  BOTH NOT APPLYING FILTER ({len(results['both_no_distortion'])}):")
    print(f"   These filters show straight grids in BOTH implementations.")
    for f in results['both_no_distortion']:
        print(f"   • {f}")
    print()

if results['patterns_differ']:
    print(f"⚠️  PATTERN MISMATCH ({len(results['patterns_differ'])}):")
    print(f"   Both show distortion but the distortion patterns are different.")
    for f in results['patterns_differ']:
        print(f"   • {f}")
    print()

print("=" * 80)
print("CONCLUSION")
print("=" * 80)
print()
if results['metal_no_distortion']:
    print("❌ CRITICAL ISSUE: Metal implementation is NOT applying filter effects!")
    print("   The Metal shader is rendering straight grids instead of distorted ones.")
    print()
if results['web_no_distortion']:
    print("❌ CRITICAL ISSUE: Web implementation is NOT applying filter effects!")
    print()
if results['patterns_differ']:
    print("⚠️  Some filters have different distortion algorithms between implementations.")
    print()
