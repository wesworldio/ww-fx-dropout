#!/usr/bin/env python3
from PIL import Image
import numpy as np
import os

def analyze_grid_pattern(path1, path2, name):
    """Analyze if two grid images have similar distortion patterns"""
    try:
        img1 = Image.open(path1).convert('L')  # Convert to grayscale
        img2 = Image.open(path2).convert('L')
        
        arr1 = np.array(img1)
        arr2 = np.array(img2)
        
        # Check if blank
        mean1 = np.mean(arr1)
        mean2 = np.mean(arr2)
        
        if mean1 < 5 and mean2 < 5:
            return 'BOTH_BLANK', {}
        if mean1 < 5:
            return 'METAL_BLANK', {}
        if mean2 < 5:
            return 'WEB_BLANK', {}
        
        # Find where yellow grid lines are (bright pixels > 200)
        grid1 = arr1 > 200
        grid2 = arr2 > 200
        
        # Calculate grid coverage
        coverage1 = np.sum(grid1) / grid1.size * 100
        coverage2 = np.sum(grid2) / grid2.size * 100
        
        # Compare grid positions using correlation
        # Flatten and compare where grid lines appear
        grid1_flat = grid1.flatten().astype(float)
        grid2_flat = grid2.flatten().astype(float)
        
        # Calculate correlation coefficient
        if np.std(grid1_flat) > 0 and np.std(grid2_flat) > 0:
            correlation = np.corrcoef(grid1_flat, grid2_flat)[0, 1]
        else:
            correlation = 0.0
        
        # Calculate overlap - how much of grid1 overlaps with grid2
        overlap = np.sum(grid1 & grid2) / max(np.sum(grid1), np.sum(grid2)) * 100
        
        # Analyze distortion by looking at grid displacement
        # Sample grid points and see if they moved similarly
        h, w = arr1.shape
        sample_points = []
        for y in range(0, h, 40):
            for x in range(0, w, 40):
                if grid1[y, x]:
                    # Find nearest grid point in img2 within small radius
                    search_radius = 20
                    y_start = max(0, y - search_radius)
                    y_end = min(h, y + search_radius + 1)
                    x_start = max(0, x - search_radius)
                    x_end = min(w, x + search_radius + 1)
                    
                    region2 = grid2[y_start:y_end, x_start:x_end]
                    if np.any(region2):
                        sample_points.append(1)
                    else:
                        sample_points.append(0)
        
        if sample_points:
            local_match = np.mean(sample_points) * 100
        else:
            local_match = 0
        
        stats = {
            'coverage1': coverage1,
            'coverage2': coverage2,
            'correlation': correlation,
            'overlap': overlap,
            'local_match': local_match
        }
        
        # Determine similarity based on multiple factors
        if correlation > 0.95 and overlap > 85:
            return 'VERY_SIMILAR', stats
        elif correlation > 0.85 and overlap > 70:
            return 'SIMILAR', stats
        elif correlation > 0.5:
            return 'SOMEWHAT_SIMILAR', stats
        else:
            return 'DIFFERENT_PATTERN', stats
            
    except Exception as e:
        return 'ERROR', {'error': str(e)}

metal_dir = 'filter-grid-test-output'
web_dir = 'web-filter-grid-test-output'

results = {
    'VERY_SIMILAR': [],
    'SIMILAR': [],
    'SOMEWHAT_SIMILAR': [],
    'DIFFERENT_PATTERN': [],
    'METAL_BLANK': [],
    'WEB_BLANK': [],
    'BOTH_BLANK': [],
    'ERROR': []
}

for filename in sorted(os.listdir(metal_dir)):
    if filename.endswith('.png'):
        name = filename[:-4]
        metal_path = os.path.join(metal_dir, filename)
        web_path = os.path.join(web_dir, filename)
        
        category, stats = analyze_grid_pattern(metal_path, web_path, name)
        
        if category in results:
            if stats:
                results[category].append((name, stats))
            else:
                results[category].append(name)

# Print organized results
print("\n=== GRID DISTORTION PATTERN COMPARISON ===\n")

if results['VERY_SIMILAR']:
    print("✓ MATCHING PATTERNS (correlation > 0.95, overlap > 85%):")
    for item in results['VERY_SIMILAR']:
        name, stats = item
        print(f"  • {name} (corr={stats['correlation']:.3f}, overlap={stats['overlap']:.1f}%)")
    print()

if results['SIMILAR']:
    print("≈ SIMILAR PATTERNS (correlation > 0.85, overlap > 70%):")
    for item in results['SIMILAR']:
        name, stats = item
        print(f"  • {name} (corr={stats['correlation']:.3f}, overlap={stats['overlap']:.1f}%)")
    print()

if results['SOMEWHAT_SIMILAR']:
    print("~ SOMEWHAT SIMILAR (correlation > 0.5):")
    for item in results['SOMEWHAT_SIMILAR']:
        name, stats = item
        print(f"  • {name} (corr={stats['correlation']:.3f}, overlap={stats['overlap']:.1f}%, coverage: M={stats['coverage1']:.1f}% W={stats['coverage2']:.1f}%)")
    print()

if results['DIFFERENT_PATTERN']:
    print("✗ DIFFERENT PATTERNS (low correlation):")
    for item in results['DIFFERENT_PATTERN']:
        name, stats = item
        coverage_diff = abs(stats['coverage1'] - stats['coverage2'])
        if coverage_diff > 5:
            note = f" [coverage differs: M={stats['coverage1']:.1f}% vs W={stats['coverage2']:.1f}%]"
        else:
            note = ""
        print(f"  • {name} (corr={stats['correlation']:.3f}, overlap={stats['overlap']:.1f}%){note}")
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

# Summary statistics
total = sum(len(v) for v in results.values())
print(f"\nTotal filters analyzed: {total}")
print(f"  Matching/Similar: {len(results['VERY_SIMILAR']) + len(results['SIMILAR'])}")
print(f"  Different: {len(results['SOMEWHAT_SIMILAR']) + len(results['DIFFERENT_PATTERN'])}")
print(f"  Blank: {len(results['METAL_BLANK']) + len(results['WEB_BLANK']) + len(results['BOTH_BLANK'])}")
