#!/usr/bin/env python3
from PIL import Image
import numpy as np
import os

def compare_images(path1, path2):
    try:
        img1 = Image.open(path1)
        img2 = Image.open(path2)
        
        # Check if dimensions match
        if img1.size != img2.size:
            return 'DIFFERENT_SIZE'
        
        # Convert to numpy arrays
        arr1 = np.array(img1)
        arr2 = np.array(img2)
        
        # Check if both are mostly black (blank)
        if np.mean(arr1) < 5 and np.mean(arr2) < 5:
            return 'BOTH_BLANK'
        
        # Check if one is blank
        if np.mean(arr1) < 5:
            return 'METAL_BLANK'
        if np.mean(arr2) < 5:
            return 'WEB_BLANK'
        
        # Calculate difference
        diff = np.abs(arr1.astype(float) - arr2.astype(float))
        max_diff = np.max(diff)
        mean_diff = np.mean(diff)
        percent_diff = np.sum(diff > 10) / diff.size * 100
        
        if mean_diff < 0.5 and percent_diff < 0.1:
            return 'IDENTICAL'
        elif mean_diff < 2.0 and percent_diff < 1.0:
            return f'VERY_SIMILAR (mean_diff={mean_diff:.2f}, {percent_diff:.1f}% pixels differ)'
        else:
            return f'DIFFERENT (mean_diff={mean_diff:.2f}, max={max_diff:.0f}, {percent_diff:.1f}% pixels differ)'
    except Exception as e:
        return f'ERROR: {str(e)}'

metal_dir = 'filter-grid-test-output'
web_dir = 'web-filter-grid-test-output'

for filename in sorted(os.listdir(metal_dir)):
    if filename.endswith('.png') and filename != 'index.html':
        metal_path = os.path.join(metal_dir, filename)
        web_path = os.path.join(web_dir, filename)
        result = compare_images(metal_path, web_path)
        print(f'{filename[:-4]}: {result}')
