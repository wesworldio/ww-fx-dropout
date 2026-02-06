// Continuing comprehensive grid overlay shaders...

// Grid overlay for lens_distortion
kernel void draw_grid_overlay_lens_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              constant float &gridSpacing [[buffer(0)]],
                                              constant float &gridThickness [[buffer(1)]],
                                              constant float &intensity [[buffer(2)]],
                                              constant float &centerX [[buffer(3)]],
                                              constant float &centerY [[buffer(4)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = (pos.x - cX) / cX;
    float dy = (pos.y - cY) / cY;
    float r2 = dx * dx + dy * dy;
    
    float k1 = -0.3;
    float k2 = 0.1;
    float radialDistortion = 1.0 + k1 * r2 + k2 * r2 * r2;
    
    float newX = cX + dx * cX * radialDistortion;
    float newY = cY + dy * cY * radialDistortion;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for radial_squeeze
kernel void draw_grid_overlay_radial_squeeze(texture2d<float, access::read> inTexture [[texture(0)]],
                                             texture2d<float, access::write> outTexture [[texture(1)]],
                                             constant float &gridSpacing [[buffer(0)]],
                                             constant float &gridThickness [[buffer(1)]],
                                             constant float &intensity [[buffer(2)]],
                                             constant float &centerX [[buffer(3)]],
                                             constant float &centerY [[buffer(4)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float squeezeFactor = 1.0 - normalizedDist * 0.4;
    float newDist = dist * squeezeFactor;
    
    float newX = cX + cos(angle) * newDist;
    float newY = cY + sin(angle) * newDist;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for smush_face
kernel void draw_grid_overlay_smush_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                         texture2d<float, access::write> outTexture [[texture(1)]],
                                         constant float &gridSpacing [[buffer(0)]],
                                         constant float &gridThickness [[buffer(1)]],
                                         constant float &intensity [[buffer(2)]],
                                         constant float &centerX [[buffer(3)]],
                                         constant float &centerY [[buffer(4)]],
                                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float squashX = 0.7;
    float stretchY = 1.3;
    
    float newX = cX + dx * squashX;
    float newY = cY + dy * stretchY;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for squeeze_horizontal
kernel void draw_grid_overlay_squeeze_horizontal(texture2d<float, access::read> inTexture [[texture(0)]],
                                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                                 constant float &gridSpacing [[buffer(0)]],
                                                 constant float &gridThickness [[buffer(1)]],
                                                 constant float &intensity [[buffer(2)]],
                                                 constant float &centerX [[buffer(3)]],
                                                 constant float &centerY [[buffer(4)]],
                                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float squeezeAmount = 0.6;
    float newX = cX + dx * squeezeAmount;
    float newY = pos.y;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for squeeze_vertical
kernel void draw_grid_overlay_squeeze_vertical(texture2d<float, access::read> inTexture [[texture(0)]],
                                               texture2d<float, access::write> outTexture [[texture(1)]],
                                               constant float &gridSpacing [[buffer(0)]],
                                               constant float &gridThickness [[buffer(1)]],
                                               constant float &intensity [[buffer(2)]],
                                               constant float &centerX [[buffer(3)]],
                                               constant float &centerY [[buffer(4)]],
                                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float squeezeAmount = 0.6;
    float newX = pos.x;
    float newY = cY + dy * squeezeAmount;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for squish_face
kernel void draw_grid_overlay_squish_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                          texture2d<float, access::write> outTexture [[texture(1)]],
                                          constant float &gridSpacing [[buffer(0)]],
                                          constant float &gridThickness [[buffer(1)]],
                                          constant float &intensity [[buffer(2)]],
                                          constant float &centerX [[buffer(3)]],
                                          constant float &centerY [[buffer(4)]],
                                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    float dist = sqrt(dx * dx + dy * dy);
    
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float squishFactor = 1.0 + normalizedDist * 0.5;
    float newX = cX + dx * squishFactor;
    float newY = cY + dy * squishFactor;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for stretch_face
kernel void draw_grid_overlay_stretch_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           constant float &gridSpacing [[buffer(0)]],
                                           constant float &gridThickness [[buffer(1)]],
                                           constant float &intensity [[buffer(2)]],
                                           constant float &centerX [[buffer(3)]],
                                           constant float &centerY [[buffer(4)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float stretchX = 1.4;
    float squashY = 0.7;
    
    float newX = cX + dx * stretchX;
    float newY = cY + dy * squashY;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for warp_face
kernel void draw_grid_overlay_warp_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                        texture2d<float, access::write> outTexture [[texture(1)]],
                                        constant float &gridSpacing [[buffer(0)]],
                                        constant float &gridThickness [[buffer(1)]],
                                        constant float &intensity [[buffer(2)]],
                                        constant float &centerX [[buffer(3)]],
                                        constant float &centerY [[buffer(4)]],
                                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float warp = sin(normalizedDist * M_PI_F) * 40.0;
    float newX = pos.x + cos(angle + M_PI_F / 2.0) * warp;
    float newY = pos.y + sin(angle + M_PI_F / 2.0) * warp;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for elastic_face
kernel void draw_grid_overlay_elastic_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           constant float &gridSpacing [[buffer(0)]],
                                           constant float &gridThickness [[buffer(1)]],
                                           constant float &intensity [[buffer(2)]],
                                           constant float &centerX [[buffer(3)]],
                                           constant float &centerY [[buffer(4)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float wobbleX = sin(pos.y / 40.0) * 20.0;
    float wobbleY = cos(pos.x / 40.0) * 20.0;
    
    float newX = pos.x + wobbleX;
    float newY = pos.y + wobbleY;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for elastic_stretch
kernel void draw_grid_overlay_elastic_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              constant float &gridSpacing [[buffer(0)]],
                                              constant float &gridThickness [[buffer(1)]],
                                              constant float &intensity [[buffer(2)]],
                                              constant float &centerX [[buffer(3)]],
                                              constant float &centerY [[buffer(4)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    float dist = sqrt(dx * dx + dy * dy);
    
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float elasticity = sin(normalizedDist * M_PI_F) * 0.3;
    float stretchFactor = 1.0 + elasticity;
    
    float newX = cX + dx * stretchFactor;
    float newY = cY + dy * stretchFactor;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for funny_squash
kernel void draw_grid_overlay_funny_squash(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           constant float &gridSpacing [[buffer(0)]],
                                           constant float &gridThickness [[buffer(1)]],
                                           constant float &intensity [[buffer(2)]],
                                           constant float &centerX [[buffer(3)]],
                                           constant float &centerY [[buffer(4)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float squashY = 0.5;
    float stretchX = 1.5;
    
    float newX = cX + dx * stretchX;
    float newY = cY + dy * squashY;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for funny_stretch
kernel void draw_grid_overlay_funny_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                                            texture2d<float, access::write> outTexture [[texture(1)]],
                                            constant float &gridSpacing [[buffer(0)]],
                                            constant float &gridThickness [[buffer(1)]],
                                            constant float &intensity [[buffer(2)]],
                                            constant float &centerX [[buffer(3)]],
                                            constant float &centerY [[buffer(4)]],
                                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float cX = float(width) / 2.0;
    float cY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - cX;
    float dy = pos.y - cY;
    
    float waveAmount = sin(dy / 30.0) * 20.0;
    float newX = pos.x + waveAmount;
    float newY = pos.y;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}
