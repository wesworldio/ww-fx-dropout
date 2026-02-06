#!/usr/bin/env python3
"""
Generate grid overlay shaders for all filters by extracting their distortion logic
"""

import re
import sys

# Read the Shaders.metal file
with open('WesWorldFX/Metal/Shaders.metal', 'r') as f:
    shader_content = f.read()

# Find all filter kernel functions (excluding grid overlays)
filter_pattern = r'kernel void ([a-z_]+)\(texture2d<float, access::read> inTexture.*?\n\{(.*?)(?=\nkernel void|\Z)'
filters = re.findall(filter_pattern, shader_content, re.DOTALL)

# Skip existing grid overlay functions and non-filter kernels
skip_filters = ['draw_grid_overlay', 'draw_grid_overlay_complex_ripple', 
                'draw_grid_overlay_water_ripple', 'draw_grid_overlay_multi_ripple',
                'wave_distortion']

grid_shaders = []

for filter_name, filter_body in filters:
    if filter_name in skip_filters or filter_name.startswith('draw_grid'):
        continue
    
    # Extract the distortion logic (the coordinate transformation part)
    # Look for float2 sourceCoord = ... or similar
    coord_match = re.search(r'float2 sourceCoord = ([^;]+);', filter_body, re.DOTALL)
    
    if not coord_match:
        # Try alternative patterns
        coord_match = re.search(r'float2 ([a-zA-Z_]+Coord) = ([^;]+);.*?float4 color = ', filter_body, re.DOTALL)
    
    # Extract the core distortion math
    distortion_code = ""
    
    # Try to find the distortion calculation
    lines = filter_body.split('\n')
    in_distortion = False
    distortion_lines = []
    
    for line in lines:
        stripped = line.strip()
        
        # Start capturing when we see coordinate calculations
        if 'float2' in stripped and ('Coord' in stripped or 'coord' in stripped):
            in_distortion = True
        
        if in_distortion:
            distortion_lines.append(line)
            
            # Stop at texture sampling
            if 'inTexture.sample' in stripped or 'inTexture.read' in stripped:
                break
    
    distortion_code = '\n'.join(distortion_lines)
    
    # Generate grid overlay shader
    grid_shader = f'''
// Grid overlay for {filter_name}
kernel void draw_grid_overlay_{filter_name}(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           constant float &gridSpacing [[buffer(0)]],
                                           constant float &gridThickness [[buffer(1)]],
                                           constant float &intensity [[buffer(2)]],
                                           constant float &centerX [[buffer(3)]],
                                           constant float &centerY [[buffer(4)]],
                                           uint2 gid [[thread_position_in_grid]]) {{
    float2 textureSize = float2(inTexture.get_width(), inTexture.get_height());
    float2 uv = float2(gid) / textureSize;
    float2 coord = float2(gid);
    float2 center = float2(centerX, centerY);
    
    // Apply the same distortion as {filter_name}
{distortion_code}
    
    // Draw grid at the distorted position
    float2 gridPos = fmod(sourceCoord + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0); // Yellow
    
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}}
'''
    
    grid_shaders.append((filter_name, grid_shader))
    print(f"✓ Generated grid overlay for {filter_name}")

print(f"\n✅ Generated {len(grid_shaders)} grid overlay shaders")
print("\nNow I'll need to manually integrate these with proper distortion code...")
