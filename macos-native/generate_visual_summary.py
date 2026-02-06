#!/usr/bin/env python3
"""
Visual summary generator for the 42 bulge effects
Creates ASCII art visualization of each filter's point layout
"""

import json

def load_filters(filepath):
    """Load the bulge effects from JSON file"""
    with open(filepath, 'r', encoding='utf-8') as f:
        data = json.load(f)
    return data['filters']

def visualize_filter(filter_data, width=40, height=20):
    """Create ASCII art visualization of filter points"""
    name = filter_data['name']
    points = filter_data['points']
    
    # Create grid
    grid = [[' ' for _ in range(width)] for _ in range(height)]
    
    # Place points
    for point in points:
        x = int(point['x'] * (width - 1))
        y = int(point['y'] * (height - 1))
        strength = point['strength']
        
        # Choose character based on strength
        if strength > 0:
            char = '●'  # Bulge
        else:
            char = '○'  # Pinch
            
        # Place point with number
        if 0 <= x < width and 0 <= y < height:
            grid[y][x] = char
    
    # Add border
    border = '─' * (width + 2)
    result = f"┌{border}┐\n"
    for row in grid:
        result += f"│ {''.join(row)} │\n"
    result += f"└{border}┘\n"
    
    # Add info
    result += f"{name}\n"
    result += f"Points: {len(points)} | "
    bulge_count = sum(1 for p in points if p['strength'] > 0)
    pinch_count = len(points) - bulge_count
    result += f"Bulge: {bulge_count}, Pinch: {pinch_count}\n"
    
    return result

def generate_summary_report(filters):
    """Generate comprehensive text summary"""
    report = []
    report.append("="*80)
    report.append(" 42 BULGE EFFECTS - VISUAL SUMMARY")
    report.append("="*80)
    report.append("")
    report.append("Legend: ● = Bulge (push out)  ○ = Pinch (pull in)")
    report.append("")
    report.append("="*80)
    report.append("")
    
    for i, filter_data in enumerate(filters, 1):
        report.append(f"\n{'='*80}")
        report.append(f" {i}. {filter_data['name'].upper()}")
        report.append(f"{'='*80}\n")
        
        # Small visualization
        points = filter_data['points']
        report.append(f"Configuration: {len(points)} control point(s)")
        report.append("")
        
        # List all points
        for j, point in enumerate(points, 1):
            pos = f"({point['x']:.2f}, {point['y']:.2f})"
            radius = f"r={point['radius']:.2f}"
            strength = f"s={point['strength']:+.2f}"
            type_str = "BULGE" if point['strength'] > 0 else "PINCH"
            report.append(f"  Point {j}: {pos} | {radius} | {strength} | {type_str}")
        
        report.append("")
        
        # Visualization (simplified grid)
        visual = create_simple_grid(points)
        for line in visual:
            report.append(f"  {line}")
        
        report.append("")
    
    report.append("="*80)
    report.append(" END OF REPORT")
    report.append("="*80)
    
    return '\n'.join(report)

def create_simple_grid(points, size=20):
    """Create a simple grid visualization"""
    grid = [['·' for _ in range(size)] for _ in range(size)]
    
    for point in points:
        x = int(point['x'] * (size - 1))
        y = int(point['y'] * (size - 1))
        
        if 0 <= x < size and 0 <= y < size:
            if point['strength'] > 0:
                grid[y][x] = '●'  # Bulge
            else:
                grid[y][x] = '○'  # Pinch
    
    # Convert to strings
    result = []
    result.append('┌' + '─' * size + '┐')
    for row in grid:
        result.append('│' + ''.join(row) + '│')
    result.append('└' + '─' * size + '┘')
    
    return result

def generate_category_summary(filters):
    """Generate summary by category"""
    summary = []
    summary.append("\n" + "="*80)
    summary.append(" CATEGORY BREAKDOWN")
    summary.append("="*80 + "\n")
    
    # By complexity
    simple = [f for f in filters if len(f['points']) <= 2]
    medium = [f for f in filters if 3 <= len(f['points']) <= 5]
    complex_filters = [f for f in filters if len(f['points']) > 5]
    
    summary.append(f"SIMPLE (1-2 points): {len(simple)} filters")
    for f in simple:
        summary.append(f"  • {f['name']}")
    summary.append("")
    
    summary.append(f"MEDIUM (3-5 points): {len(medium)} filters")
    for f in medium:
        summary.append(f"  • {f['name']}")
    summary.append("")
    
    summary.append(f"COMPLEX (6+ points): {len(complex_filters)} filters")
    for f in complex_filters:
        summary.append(f"  • {f['name']} ({len(f['points'])} points)")
    summary.append("")
    
    return '\n'.join(summary)

def main():
    print("🎨 Loading bulge effects...")
    filters = load_filters('42_bulge_effects.wwfxbulge')
    
    print(f"✅ Loaded {len(filters)} filters")
    print("\n📊 Generating visual summary report...")
    
    # Generate full report
    report = generate_summary_report(filters)
    
    # Add category breakdown
    report += "\n" + generate_category_summary(filters)
    
    # Save to file
    output_file = 'BULGE_EFFECTS_VISUAL_SUMMARY.txt'
    with open(output_file, 'w', encoding='utf-8') as f:
        f.write(report)
    
    print(f"✅ Visual summary saved to: {output_file}")
    
    # Print preview
    print("\n" + "="*80)
    print(" PREVIEW (First 3 filters)")
    print("="*80)
    for i, filter_data in enumerate(filters[:3], 1):
        print(f"\n{i}. {filter_data['name']}")
        print(f"   Points: {len(filter_data['points'])}")
        visual = create_simple_grid(filter_data['points'], 15)
        for line in visual:
            print(f"   {line}")

if __name__ == "__main__":
    main()
