#!/usr/bin/env python3
"""
Visual side-by-side comparison with detailed analysis
"""
from PIL import Image, ImageDraw, ImageFont
import numpy as np
import os

METAL_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/filter-grid-test-output"
WEB_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/web-filter-grid-test-output"

def analyze_single_filter(filter_name):
    """Deep analysis of a single filter"""
    metal_path = f"{METAL_DIR}/{filter_name}.png"
    web_path = f"{WEB_DIR}/{filter_name}.png"
    
    metal = np.array(Image.open(metal_path).convert('RGB'))
    web = np.array(Image.open(web_path).convert('RGB'))
    
    print(f"\n{'='*70}")
    print(f"FILTER: {filter_name}")
    print(f"{'='*70}")
    
    # Get grid masks
    metal_grid = (metal[:, :, 0] + metal[:, :, 1]) > 50
    web_grid = (web[:, :, 0] + web[:, :, 1]) > 50
    
    h, w = metal_grid.shape
    
    # Analyze grid distribution by rows and columns
    print("\nGrid Distribution Analysis:")
    
    # Sample some rows
    sample_rows = [h//4, h//2, 3*h//4]
    print(f"\n  Row samples (grid pixel %):")
    for row in sample_rows:
        metal_row_pct = np.sum(metal_grid[row, :]) / w * 100
        web_row_pct = np.sum(web_grid[row, :]) / w * 100
        print(f"    Row {row:3d}: Metal={metal_row_pct:5.1f}%  Web={web_row_pct:5.1f}%  Δ={web_row_pct-metal_row_pct:+5.1f}%")
    
    # Sample some columns
    sample_cols = [w//4, w//2, 3*w//4]
    print(f"\n  Column samples (grid pixel %):")
    for col in sample_cols:
        metal_col_pct = np.sum(metal_grid[:, col]) / h * 100
        web_col_pct = np.sum(web_grid[:, col]) / h * 100
        print(f"    Col {col:3d}: Metal={metal_col_pct:5.1f}%  Web={web_col_pct:5.1f}%  Δ={web_col_pct-metal_col_pct:+5.1f}%")
    
    # Analyze center region distortion
    cy, cx = h // 2, w // 2
    radius = min(h, w) // 4
    
    # Create circular mask
    y, x = np.ogrid[:h, :w]
    dist_from_center = np.sqrt((x - cx)**2 + (y - cy)**2)
    center_mask = dist_from_center < radius
    edge_mask = dist_from_center > radius * 1.5
    
    metal_center = np.sum(metal_grid & center_mask) / np.sum(center_mask) * 100
    web_center = np.sum(web_grid & center_mask) / np.sum(center_mask) * 100
    
    metal_edge = np.sum(metal_grid & edge_mask) / np.sum(edge_mask) * 100
    web_edge = np.sum(web_grid & edge_mask) / np.sum(edge_mask) * 100
    
    print(f"\n  Center region (radius {radius}px):")
    print(f"    Metal: {metal_center:.1f}%  Web: {web_center:.1f}%  Δ={web_center-metal_center:+.1f}%")
    print(f"  Edge region (outside 1.5x radius):")
    print(f"    Metal: {metal_edge:.1f}%  Web: {web_edge:.1f}%  Δ={web_edge-metal_edge:+.1f}%")
    
    # Check if pattern is inverted/flipped
    print(f"\n  Pattern symmetry:")
    
    # Horizontal flip comparison
    metal_flipped_h = np.fliplr(metal_grid)
    web_vs_metal_flipped_h = np.sum(web_grid & metal_flipped_h) / np.sum(web_grid | metal_flipped_h) * 100
    
    # Vertical flip comparison
    metal_flipped_v = np.flipud(metal_grid)
    web_vs_metal_flipped_v = np.sum(web_grid & metal_flipped_v) / np.sum(web_grid | metal_flipped_v) * 100
    
    # Normal comparison
    web_vs_metal = np.sum(web_grid & metal_grid) / np.sum(web_grid | metal_grid) * 100
    
    print(f"    Normal overlap:     {web_vs_metal:.1f}%")
    print(f"    H-flipped overlap:  {web_vs_metal_flipped_h:.1f}%")
    print(f"    V-flipped overlap:  {web_vs_metal_flipped_v:.1f}%")
    
    if web_vs_metal_flipped_h > web_vs_metal * 1.5:
        print(f"    ⚠ POSSIBLE HORIZONTAL FLIP")
    if web_vs_metal_flipped_v > web_vs_metal * 1.5:
        print(f"    ⚠ POSSIBLE VERTICAL FLIP")
    
    # Check for phase shift (offset)
    print(f"\n  Phase shift detection:")
    best_offset = (0, 0)
    best_overlap = web_vs_metal
    
    for dy in [-10, -5, 0, 5, 10]:
        for dx in [-10, -5, 0, 5, 10]:
            if dy == 0 and dx == 0:
                continue
            
            # Shift metal grid
            shifted = np.roll(metal_grid, (dy, dx), axis=(0, 1))
            overlap = np.sum(web_grid & shifted) / np.sum(web_grid | shifted) * 100
            
            if overlap > best_overlap:
                best_overlap = overlap
                best_offset = (dy, dx)
    
    if best_offset != (0, 0):
        print(f"    Best offset: dy={best_offset[0]:+d}, dx={best_offset[1]:+d} (overlap: {best_overlap:.1f}%)")
        print(f"    ⚠ POSSIBLE PHASE/OFFSET DIFFERENCE")
    else:
        print(f"    No significant offset detected")

# Analyze a few key filters
filters_to_analyze = ["funhouse_mirror", "water_ripple", "bulge_eyes"]

for filter_name in filters_to_analyze:
    analyze_single_filter(filter_name)

print(f"\n{'='*70}\n")
