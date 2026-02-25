#!/usr/bin/env python3
"""
Check if the grids are showing distortion or if one is just straight
"""
from PIL import Image
import numpy as np

def check_grid_straightness(img_path, name):
    """Check if grid lines are straight or distorted"""
    img = np.array(Image.open(img_path).convert('RGB'))
    grid = (img[:, :, 0] + img[:, :, 1]) > 50
    
    h, w = grid.shape
    
    print(f"\n{name}:")
    
    # Check horizontal lines - should be distorted in different ways
    # Sample middle horizontal line
    mid_row = h // 2
    row_pixels = []
    for x in range(0, w, 64):  # Sample every 64 pixels
        if grid[mid_row, x]:
            row_pixels.append((x, mid_row))
    
    # Check if grid appears at regular intervals (straight) or irregular (distorted)
    if len(row_pixels) > 2:
        intervals = []
        for i in range(1, len(row_pixels)):
            intervals.append(row_pixels[i][0] - row_pixels[i-1][0])
        
        if intervals:
            avg_interval = np.mean(intervals)
            std_interval = np.std(intervals)
            print(f"  Horizontal spacing: avg={avg_interval:.1f}px, std={std_interval:.1f}px")
            
            if std_interval < 5:
                print(f"  → STRAIGHT/REGULAR grid")
            else:
                print(f"  → DISTORTED grid")
    
    # Count grid density in different regions
    regions = [
        ("Top-left", (0, h//3, 0, w//3)),
        ("Top-right", (0, h//3, 2*w//3, w)),
        ("Center", (h//3, 2*h//3, w//3, 2*w//3)),
        ("Bottom-left", (2*h//3, h, 0, w//3)),
        ("Bottom-right", (2*h//3, h, 2*w//3, w)),
    ]
    
    densities = []
    for region_name, (y1, y2, x1, x2) in regions:
        region = grid[y1:y2, x1:x2]
        density = np.sum(region) / region.size * 100
        densities.append(density)
        print(f"  {region_name:15s}: {density:5.1f}% grid coverage")
    
    # Check if uniform (no distortion) or varied (distorted)
    std_density = np.std(densities)
    if std_density < 1.0:
        print(f"  → UNIFORM distribution (std={std_density:.2f}) - likely no distortion")
    else:
        print(f"  → VARIED distribution (std={std_density:.2f}) - shows distortion")

filters = ["funhouse_mirror", "bulge_eyes", "water_ripple"]

for f in filters:
    print(f"\n{'='*60}")
    print(f"FILTER: {f}")
    print(f"{'='*60}")
    check_grid_straightness(f"filter-grid-test-output/{f}.png", "METAL")
    check_grid_straightness(f"web-filter-grid-test-output/{f}.png", "WEB")
