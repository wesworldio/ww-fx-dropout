#!/usr/bin/env python3
from PIL import Image
import numpy as np
import os

def analyze_image_content(path, name):
    """Check what's actually in the image"""
    img = Image.open(path)
    arr = np.array(img)
    
    # Check different color ranges
    if len(arr.shape) == 3:  # RGB image
        # Check for yellow (high R and G, low B)
        yellow_mask = (arr[:, :, 0] > 200) & (arr[:, :, 1] > 200) & (arr[:, :, 2] < 50)
        yellow_pct = np.sum(yellow_mask) / yellow_mask.size * 100
        
        # Check for any bright pixels (white or near-white)
        bright_mask = np.all(arr > 200, axis=2)
        bright_pct = np.sum(bright_mask) / bright_mask.size * 100
        
        # Check for any non-black pixels
        nonblack_mask = np.any(arr > 10, axis=2)
        nonblack_pct = np.sum(nonblack_mask) / nonblack_mask.size * 100
        
        # Average color of non-black pixels
        if np.any(nonblack_mask):
            nonblack_pixels = arr[nonblack_mask]
            avg_color = np.mean(nonblack_pixels, axis=0)
        else:
            avg_color = [0, 0, 0]
        
        return {
            'yellow': yellow_pct,
            'bright': bright_pct,
            'nonblack': nonblack_pct,
            'avg_color': avg_color
        }
    else:  # Grayscale
        return {'error': 'grayscale image'}

metal_dir = 'filter-grid-test-output'
web_dir = 'web-filter-grid-test-output'

# Sample a few filters
samples = ['bulge_eyes', 'lens_distortion', 'upside_down', 'warp_face', 'elastic_stretch']

print("=== IMAGE CONTENT ANALYSIS ===\n")

for name in samples:
    metal_path = os.path.join(metal_dir, f'{name}.png')
    web_path = os.path.join(web_dir, f'{name}.png')
    
    if os.path.exists(metal_path) and os.path.exists(web_path):
        metal_stats = analyze_image_content(metal_path, name)
        web_stats = analyze_image_content(web_path, name)
        
        print(f"{name}:")
        print(f"  METAL: yellow={metal_stats['yellow']:.2f}%, bright={metal_stats['bright']:.2f}%, nonblack={metal_stats['nonblack']:.2f}%")
        print(f"         avg_color=[{metal_stats['avg_color'][0]:.0f}, {metal_stats['avg_color'][1]:.0f}, {metal_stats['avg_color'][2]:.0f}]")
        print(f"  WEB:   yellow={web_stats['yellow']:.2f}%, bright={web_stats['bright']:.2f}%, nonblack={web_stats['nonblack']:.2f}%")
        print(f"         avg_color=[{web_stats['avg_color'][0]:.0f}, {web_stats['avg_color'][1]:.0f}, {web_stats['avg_color'][2]:.0f}]")
        print()
