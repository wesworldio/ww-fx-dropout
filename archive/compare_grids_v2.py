#!/usr/bin/env python3
"""
Improved grid comparison with proper RGB handling
"""
from PIL import Image
import numpy as np
import os

METAL_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/filter-grid-test-output"
WEB_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/web-filter-grid-test-output"

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
    """Load image and convert to RGB (ignore alpha)"""
    if not os.path.exists(path):
        return None
    img = Image.open(path).convert('RGB')
    return np.array(img)

def get_grid_mask(img, threshold=50):
    """Extract grid pixels (yellow on black)"""
    # Grid is yellow: high R, high G, low B
    # Black background: low R, low G, low B
    brightness = img[:, :, 0] + img[:, :, 1]  # R + G channels
    return brightness > threshold

def compare_grids(img1, img2):
    """Compare grid patterns"""
    if img1 is None or img2 is None:
        return False, 100.0, "Image missing"
    
    if img1.shape != img2.shape:
        return False, 100.0, f"Shape mismatch"
    
    # Get grid masks
    grid1 = get_grid_mask(img1)
    grid2 = get_grid_mask(img2)
    
    # Count grid pixels
    count1 = np.sum(grid1)
    count2 = np.sum(grid2)
    
    if count1 == 0 and count2 == 0:
        return True, 0.0, "Both empty"
    
    if count1 == 0 or count2 == 0:
        return False, 100.0, f"One empty (Metal:{count1}, Web:{count2})"
    
    # Compare grid positions
    both_grid = grid1 & grid2  # Pixels that are grid in both
    either_grid = grid1 | grid2  # Pixels that are grid in either
    
    # Calculate overlap percentage
    overlap = np.sum(both_grid) / np.sum(either_grid) * 100
    
    # Also check spatial correlation
    diff = np.sum(grid1 != grid2) / grid1.size * 100
    
    is_match = overlap > 85 and diff < 15
    
    if is_match:
        return True, diff, f"MATCH (overlap: {overlap:.1f}%)"
    
    # Analyze difference pattern
    if overlap < 30:
        return False, diff, f"Completely different patterns (overlap: {overlap:.1f}%)"
    elif overlap < 60:
        return False, diff, f"Major pattern difference (overlap: {overlap:.1f}%)"
    else:
        return False, diff, f"Minor pattern difference (overlap: {overlap:.1f}%)"

def analyze_distortion_direction(img):
    """Analyze the direction and nature of grid distortion"""
    grid = get_grid_mask(img)
    h, w = grid.shape
    
    # Divide into quadrants
    cy, cx = h // 2, w // 2
    
    quadrants = {
        'TL': grid[:cy, :cx],
        'TR': grid[:cy, cx:],
        'BL': grid[cy:, :cx],
        'BR': grid[cy:, cx:]
    }
    
    densities = {}
    for name, quad in quadrants.items():
        densities[name] = np.sum(quad) / quad.size * 100
    
    # Check horizontal vs vertical distribution
    top_half = np.sum(grid[:cy, :]) / (cy * w) * 100
    bottom_half = np.sum(grid[cy:, :]) / ((h - cy) * w) * 100
    left_half = np.sum(grid[:, :cx]) / (h * cx) * 100
    right_half = np.sum(grid[:, cx:]) / (h * (w - cx)) * 100
    
    info = []
    info.append(f"H:{left_half:.1f}|{right_half:.1f}")
    info.append(f"V:{top_half:.1f}|{bottom_half:.1f}")
    
    return ", ".join(info)

def main():
    print("=" * 80)
    print("GRID OVERLAY COMPARISON: Metal vs Web (Improved)")
    print("=" * 80)
    print()
    
    fixed = []
    still_different = []
    regression = []
    
    for filter_name in FILTERS_TO_CHECK:
        metal_path = os.path.join(METAL_DIR, f"{filter_name}.png")
        web_path = os.path.join(WEB_DIR, f"{filter_name}.png")
        
        metal_img = load_image(metal_path)
        web_img = load_image(web_path)
        
        is_match, diff_pct, description = compare_grids(metal_img, web_img)
        
        status_symbol = "✓" if is_match else "✗"
        print(f"{status_symbol} {filter_name:<25} Diff: {diff_pct:5.1f}%  {description}")
        
        if not is_match and metal_img is not None and web_img is not None:
            metal_dist = analyze_distortion_direction(metal_img)
            web_dist = analyze_distortion_direction(web_img)
            print(f"  {'':27} Metal: {metal_dist}")
            print(f"  {'':27} Web:   {web_dist}")
        
        # Categorize
        if not is_match:
            if filter_name == "bulge_eyes":
                regression.append((filter_name, description))
            else:
                still_different.append((filter_name, description))
        else:
            if filter_name == "bulge_eyes":
                pass  # Expected to match
            else:
                fixed.append(filter_name)
    
    print()
    print("=" * 80)
    print("SUMMARY")
    print("=" * 80)
    
    if fixed:
        print(f"\n✓ FIXED ({len(fixed)} filters):")
        for f in fixed:
            print(f"  • {f}")
    
    if still_different:
        print(f"\n✗ STILL DIFFERENT ({len(still_different)} filters):")
        for f, issue in still_different:
            print(f"  • {f}: {issue}")
    
    if regression:
        print(f"\n⚠ REGRESSION ({len(regression)} filters):")
        for f, issue in regression:
            print(f"  • {f}: {issue}")
    
    if not still_different and not regression:
        print("\n✓ All filters now match correctly!")

if __name__ == "__main__":
    main()
