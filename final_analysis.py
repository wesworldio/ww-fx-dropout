#!/usr/bin/env python3
from PIL import Image
import numpy as np
import os

def compare_distortion_patterns(path1, path2, name):
    """Compare distortion patterns by brightness-normalizing and looking at structure"""
    try:
        img1 = Image.open(path1).convert('RGB')
        img2 = Image.open(path2).convert('RGB')
        
        # Convert to arrays
        arr1 = np.array(img1)
        arr2 = np.array(img2)
        
        # Check if images are blank
        mean1 = np.mean(arr1)
        mean2 = np.mean(arr2)
        
        if mean1 < 5:
            return 'METAL_BLANK', None
        if mean2 < 5:
            return 'WEB_BLANK', None
        
        # Extract yellow channel (R+G with low B)
        yellow1 = (arr1[:, :, 0].astype(float) + arr1[:, :, 1].astype(float)) / 2 - arr1[:, :, 2].astype(float)
        yellow2 = (arr2[:, :, 0].astype(float) + arr2[:, :, 1].astype(float)) / 2 - arr2[:, :, 2].astype(float)
        
        # Normalize to 0-1 range
        max1 = np.max(yellow1)
        max2 = np.max(yellow2)
        
        if max1 > 0:
            yellow1 = yellow1 / max1
        if max2 > 0:
            yellow2 = yellow2 / max2
        
        # Calculate correlation of the normalized yellow channels
        y1_flat = yellow1.flatten()
        y2_flat = yellow2.flatten()
        
        if np.std(y1_flat) > 0.001 and np.std(y2_flat) > 0.001:
            correlation = np.corrcoef(y1_flat, y2_flat)[0, 1]
        else:
            correlation = 0.0
        
        # Simple edge detection using differences
        # Horizontal edges
        grad1_h = np.abs(np.diff(yellow1, axis=1, prepend=0))
        grad2_h = np.abs(np.diff(yellow2, axis=1, prepend=0))
        
        # Vertical edges
        grad1_v = np.abs(np.diff(yellow1, axis=0, prepend=0))
        grad2_v = np.abs(np.diff(yellow2, axis=0, prepend=0))
        
        # Combined gradient magnitude
        grad1_mag = np.sqrt(grad1_h**2 + grad1_v**2)
        grad2_mag = np.sqrt(grad2_h**2 + grad2_v**2)
        
        # Normalize gradients
        if np.max(grad1_mag) > 0:
            grad1_mag = grad1_mag / np.max(grad1_mag)
        if np.max(grad2_mag) > 0:
            grad2_mag = grad2_mag / np.max(grad2_mag)
        
        # Correlation of gradient magnitudes (distortion similarity)
        g1_flat = grad1_mag.flatten()
        g2_flat = grad2_mag.flatten()
        
        if np.std(g1_flat) > 0.001 and np.std(g2_flat) > 0.001:
            gradient_corr = np.corrcoef(g1_flat, g2_flat)[0, 1]
        else:
            gradient_corr = 0.0
        
        # Threshold to get grid structure (top 5% brightest)
        threshold1 = np.percentile(yellow1, 95)
        threshold2 = np.percentile(yellow2, 95)
        
        grid1 = yellow1 > threshold1
        grid2 = yellow2 > threshold2
        
        # Calculate grid overlap
        grid_overlap = np.sum(grid1 & grid2) / max(np.sum(grid1), np.sum(grid2), 1) * 100
        
        stats = {
            'correlation': correlation,
            'gradient_corr': gradient_corr,
            'grid_overlap': grid_overlap
        }
        
        # Classify based on gradient correlation (most important for distortion patterns)
        if gradient_corr > 0.90:
            return 'MATCHING', stats
        elif gradient_corr > 0.75:
            return 'SIMILAR', stats
        elif gradient_corr > 0.50:
            return 'SOMEWHAT_SIMILAR', stats
        else:
            return 'DIFFERENT', stats
            
    except Exception as e:
        return 'ERROR', {'error': str(e)}

metal_dir = 'filter-grid-test-output'
web_dir = 'web-filter-grid-test-output'

results = {
    'MATCHING': [],
    'SIMILAR': [],
    'SOMEWHAT_SIMILAR': [],
    'DIFFERENT': [],
    'METAL_BLANK': [],
    'WEB_BLANK': [],
    'ERROR': []
}

print("Analyzing distortion patterns (brightness-normalized)...\n")

for filename in sorted(os.listdir(metal_dir)):
    if filename.endswith('.png'):
        name = filename[:-4]
        metal_path = os.path.join(metal_dir, filename)
        web_path = os.path.join(web_dir, filename)
        
        category, stats = compare_distortion_patterns(metal_path, web_path, name)
        
        if stats:
            results[category].append((name, stats))
        else:
            results[category].append(name)

# Print organized results
print("\n" + "="*70)
print("GRID DISTORTION PATTERN COMPARISON")
print("(Brightness-normalized structural analysis)")
print("="*70 + "\n")

if results['MATCHING']:
    print("✓ MATCHING DISTORTION PATTERNS (gradient correlation > 0.90):")
    for item in results['MATCHING']:
        name, stats = item
        print(f"  • {name}")
        print(f"      gradient={stats['gradient_corr']:.3f}, overlap={stats['grid_overlap']:.1f}%")
    print()

if results['SIMILAR']:
    print("≈ SIMILAR DISTORTION PATTERNS (gradient correlation > 0.75):")
    for item in results['SIMILAR']:
        name, stats = item
        print(f"  • {name}")
        print(f"      gradient={stats['gradient_corr']:.3f}, overlap={stats['grid_overlap']:.1f}%")
    print()

if results['SOMEWHAT_SIMILAR']:
    print("~ SOMEWHAT SIMILAR (gradient correlation > 0.50):")
    for item in results['SOMEWHAT_SIMILAR']:
        name, stats = item
        print(f"  • {name}")
        print(f"      gradient={stats['gradient_corr']:.3f}, overlap={stats['grid_overlap']:.1f}%")
    print()

if results['DIFFERENT']:
    print("✗ DIFFERENT DISTORTION PATTERNS:")
    for item in results['DIFFERENT']:
        name, stats = item
        print(f"  • {name}")
        print(f"      gradient={stats['gradient_corr']:.3f}, overlap={stats['grid_overlap']:.1f}%")
    print()

if results['METAL_BLANK']:
    print("⚠ BLANK IN METAL VERSION:")
    for name in results['METAL_BLANK']:
        print(f"  • {name}")
    print()

if results['WEB_BLANK']:
    print("⚠ BLANK IN WEB VERSION:")
    for name in results['WEB_BLANK']:
        print(f"  • {name}")
    print()

if results['ERROR']:
    print("❌ ERRORS:")
    for item in results['ERROR']:
        if isinstance(item, tuple):
            name, stats = item
            print(f"  • {name}: {stats.get('error', 'unknown')}")
        else:
            print(f"  • {item}")
    print()

# Summary
total = sum(len(v) for v in results.values())
matching = len(results['MATCHING']) + len(results['SIMILAR'])
different = len(results['SOMEWHAT_SIMILAR']) + len(results['DIFFERENT'])
blank = len(results['METAL_BLANK']) + len(results['WEB_BLANK'])

print("="*70)
print(f"SUMMARY: {total} filters analyzed")
print(f"  ✓ Matching/Similar patterns: {matching}")
print(f"  ✗ Different patterns: {different}")
print(f"  ⚠ Blank/problematic: {blank}")
print("="*70)
