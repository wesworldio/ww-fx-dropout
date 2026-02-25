#!/usr/bin/env python3
"""
Compare grid overlay images between Metal and Web implementations
"""
import os
from PIL import Image
import numpy as np

# Directories
METAL_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/filter-grid-test-output"
WEB_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/web-filter-grid-test-output"

# Filters to check
FILTERS_TO_CHECK = [
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

def load_image(path):
    """Load image as numpy array"""
    if not os.path.exists(path):
        return None
    return np.array(Image.open(path))

def compare_images(img1, img2, threshold=10):
    """
    Compare two images and return similarity metrics
    Returns: (is_match, diff_percentage, description)
    """
    if img1 is None or img2 is None:
        return False, 100.0, "Image file missing"
    
    if img1.shape != img2.shape:
        return False, 100.0, f"Shape mismatch: {img1.shape} vs {img2.shape}"
    
    # Calculate absolute difference
    diff = np.abs(img1.astype(int) - img2.astype(int))
    
    # Calculate percentage of different pixels (considering threshold)
    diff_pixels = np.any(diff > threshold, axis=-1) if len(diff.shape) == 3 else diff > threshold
    diff_percentage = (np.sum(diff_pixels) / diff_pixels.size) * 100
    
    # Consider match if less than 5% difference
    is_match = diff_percentage < 5.0
    
    if is_match:
        return True, diff_percentage, "MATCH"
    
    # Analyze the difference pattern to describe what's wrong
    if diff_percentage > 50:
        return False, diff_percentage, "Major structural difference"
    elif diff_percentage > 20:
        return False, diff_percentage, "Significant pattern difference"
    else:
        return False, diff_percentage, "Minor pattern difference"

def analyze_grid_structure(img, filter_name):
    """
    Analyze the grid structure to detect patterns like:
    - Direction of curves/warping
    - Intensity of distortion
    """
    # Focus on the yellow channel (grid is yellow on black)
    if len(img.shape) == 3:
        # Get brightness (max of RGB channels)
        brightness = np.max(img, axis=2)
    else:
        brightness = img
    
    # Get grid pixels (bright pixels)
    grid_pixels = brightness > 50
    
    if not np.any(grid_pixels):
        return "No grid found"
    
    # Find center
    h, w = grid_pixels.shape
    cy, cx = h // 2, w // 2
    
    # Sample distortion in different regions
    regions = {
        'top': (0, h//3, w//3, 2*w//3),
        'bottom': (2*h//3, h, w//3, 2*w//3),
        'left': (h//3, 2*h//3, 0, w//3),
        'right': (h//3, 2*h//3, 2*w//3, w),
        'center': (h//3, 2*h//3, w//3, 2*w//3)
    }
    
    info = []
    for region_name, (y1, y2, x1, x2) in regions.items():
        region_grid = grid_pixels[y1:y2, x1:x2]
        density = np.sum(region_grid) / region_grid.size * 100
        if density > 1:  # Only report if there's significant grid
            info.append(f"{region_name}:{density:.1f}%")
    
    return ", ".join(info) if info else "Sparse grid"

def main():
    print("=" * 70)
    print("GRID OVERLAY COMPARISON: Metal vs Web")
    print("=" * 70)
    print()
    
    fixed = []
    still_different = []
    regression = []
    
    for filter_name in FILTERS_TO_CHECK:
        metal_path = os.path.join(METAL_DIR, f"{filter_name}.png")
        web_path = os.path.join(WEB_DIR, f"{filter_name}.png")
        
        metal_img = load_image(metal_path)
        web_img = load_image(web_path)
        
        is_match, diff_pct, description = compare_images(metal_img, web_img)
        
        print(f"Filter: {filter_name}")
        print(f"  Status: {'✓ MATCH' if is_match else '✗ DIFFERENT'}")
        print(f"  Difference: {diff_pct:.2f}%")
        
        if not is_match:
            print(f"  Issue: {description}")
            
            # Detailed analysis for different images
            if metal_img is not None and web_img is not None:
                metal_structure = analyze_grid_structure(metal_img, filter_name)
                web_structure = analyze_grid_structure(web_img, filter_name)
                print(f"  Metal: {metal_structure}")
                print(f"  Web:   {web_structure}")
            
            # Categorize based on filter name (bulge_eyes should be matching)
            if filter_name == "bulge_eyes":
                regression.append((filter_name, description))
            else:
                still_different.append((filter_name, description))
        else:
            if filter_name == "bulge_eyes":
                print("  Note: Still matching (as expected)")
            else:
                fixed.append(filter_name)
        
        print()
    
    print("=" * 70)
    print("SUMMARY")
    print("=" * 70)
    print()
    
    if fixed:
        print(f"✓ FIXED ({len(fixed)} filters now matching):")
        for f in fixed:
            print(f"  - {f}")
        print()
    
    if still_different:
        print(f"✗ STILL DIFFERENT ({len(still_different)} filters):")
        for f, issue in still_different:
            print(f"  - {f}: {issue}")
        print()
    
    if regression:
        print(f"⚠ REGRESSION ({len(regression)} filters):")
        for f, issue in regression:
            print(f"  - {f}: {issue}")
        print()
    
    if not fixed and not still_different and not regression:
        print("No issues found - all filters match!")

if __name__ == "__main__":
    main()
