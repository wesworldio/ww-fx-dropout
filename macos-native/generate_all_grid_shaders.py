#!/usr/bin/env python3
"""
Auto-generate grid overlay shaders for all filters by extracting distortion logic
"""
import re
import sys

def extract_distortion_logic(filter_name, filter_body):
    """Extract the coordinate transformation logic from a filter"""
    
    # Find the distortion calculation section
    lines = filter_body.split('\n')
    
    # Look for the newX/newY calculations or sourceCoord assignment
    distortion_lines = []
    capturing = False
    
    for i, line in enumerate(lines):
        stripped = line.strip()
        
        # Start capturing at variable declarations for coordinates
        if (('newX' in stripped and '=' in stripped) or 
            ('newY' in stripped and '=' in stripped) or
            ('sourceCoord' in stripped and 'float2' in stripped) or
            (capturing and len(stripped) > 0)):
            
            # Skip texture reads/writes
            if '.read(' in stripped or '.write(' in stripped or 'inTexture.sample' in stripped:
                break
                
            # Skip the final return/clamp statement usually
            if 'return' in stripped:
                break
                
            capturing = True
            distortion_lines.append(line)
            
            # Stop after we've captured the source position calculation
            if 'sourcePos' in stripped and 'uint2' in stripped:
                break
    
    return '\n'.join(distortion_lines)


# Read shader file
with open('WesWorldFX/Metal/Shaders.metal', 'r') as f:
    content = f.read()

# Extract all filter kernels
pattern = r'kernel void ([a-z_]+)\(texture2d<float, access::read> inTexture.*?\n\{(.*?)(?=\nkernel void|\Z)'
matches = re.findall(pattern, content, re.DOTALL)

# Filters to generate
target_filters = [
    'bulge_eyes', 'funhouse_mirror', 'funny_squash', 'pinch_cheeks', 'pincushion',
    'radial_wobble', 'ultimate_distortion', 'wobble_face', 'elastic_face',
    'elastic_stretch', 'funny_stretch', 'gentle_ripple', 'lens_distortion',
    'radial_squeeze', 'smush_face', 'squeeze_horizontal', 'squeeze_vertical',
    'squish_face', 'stretch_face', 'warp_face', 'upside_down'
]

generated_shaders = []

for filter_name, filter_body in matches:
    if filter_name not in target_filters:
        continue
    
    print(f"Processing {filter_name}...")
    
    # Extract core distortion logic
    distortion = extract_distortion_logic(filter_name, filter_body)
    
    # Build the grid shader with same distortion logic
    grid_shader = f'''
// Grid overlay for {filter_name} - matches filter distortion
kernel void draw_grid_overlay_{filter_name}(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           constant float &gridSpacing [[buffer(0)]],
                                           constant float &gridThickness [[buffer(1)]],
                                           constant float &intensity [[buffer(2)]],
                                           constant float &centerX [[buffer(3)]],
                                           constant float &centerY [[buffer(4)]],
                                           uint2 gid [[thread_position_in_grid]]) {{
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    // Apply same distortion as {filter_name}
    float2 pos = float2(gid);
{distortion}
    
    // Use the distorted coordinates for grid calculation
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0); // Yellow
    
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}}
'''
    
    generated_shaders.append(grid_shader)

# Write to a new file
output_file = 'generated_grid_shaders.metal'
with open(output_file, 'w') as f:
    f.write('// Auto-generated grid overlay shaders\n')
    f.write('// Generated to match each filter\'s specific distortion\n\n')
    f.write('#include <metal_stdlib>\nusing namespace metal;\n\n')
    for shader in generated_shaders:
        f.write(shader)
        f.write('\n')

print(f"\n✅ Generated {len(generated_shaders)} grid shaders")
print(f"📝 Written to: {output_file}")
