#!/usr/bin/env python3
"""
Check what's actually in the web images
"""
from PIL import Image
import numpy as np

WEB_DIR = "/Users/wes/Sites/wesworld/ww-fx-dropout/web-filter-grid-test-output"

# Check a couple of images
filters = ["funhouse_mirror", "bulge_eyes"]

for filter_name in filters:
    path = f"{WEB_DIR}/{filter_name}.png"
    img = Image.open(path)
    arr = np.array(img)
    
    print(f"\n{filter_name}.png:")
    print(f"  Shape: {arr.shape}")
    print(f"  Data type: {arr.dtype}")
    print(f"  Min value: {arr.min()}")
    print(f"  Max value: {arr.max()}")
    print(f"  Mean value: {arr.mean():.2f}")
    
    # Check unique values
    unique_vals = np.unique(arr)
    print(f"  Unique values: {len(unique_vals)} values")
    if len(unique_vals) <= 10:
        print(f"  Values: {unique_vals}")
    
    # Check if it's all one color
    if len(unique_vals) == 1:
        print(f"  WARNING: Image is solid color!")
    
    # Sample some pixels
    h, w = arr.shape[:2]
    print(f"  Sample pixels:")
    print(f"    Center: {arr[h//2, w//2]}")
    print(f"    Top-left: {arr[0, 0]}")
    print(f"    Bottom-right: {arr[h-1, w-1]}")
