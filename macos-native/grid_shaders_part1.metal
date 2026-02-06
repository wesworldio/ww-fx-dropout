
// ============================================================================
// COMPREHENSIVE GRID OVERLAY SHADERS FOR ALL FILTERS
// Each grid shader matches its corresponding filter's distortion exactly
// ============================================================================

// Grid overlay for upside_down
kernel void draw_grid_overlay_upside_down(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    // Upside down: flip vertically
    float newX = float(gid.x);
    float newY = float(height - 1 - gid.y);
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for bulge_eyes
kernel void draw_grid_overlay_bulge_eyes(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float eyeOffsetX = float(width) * 0.15;
    float eyeOffsetY = -float(height) * 0.05;
    float leftEyeX = cX - eyeOffsetX;
    float leftEyeY = cY + eyeOffsetY;
    float rightEyeX = cX + eyeOffsetX;
    float rightEyeY = cY + eyeOffsetY;
    float eyeRadius = min(float(width), float(height)) * 0.12;
    const float strength = 0.65;
    
    float2 pos = float2(gid);
    float newX = pos.x;
    float newY = pos.y;
    
    float dxLeft = pos.x - leftEyeX;
    float dyLeft = pos.y - leftEyeY;
    float distLeft = sqrt(dxLeft * dxLeft + dyLeft * dyLeft);
    
    float dxRight = pos.x - rightEyeX;
    float dyRight = pos.y - rightEyeY;
    float distRight = sqrt(dxRight * dxRight + dyRight * dyRight);
    
    if (distLeft < eyeRadius) {
        float factor = 1.0 - (distLeft / eyeRadius) * strength;
        newX = leftEyeX + dxLeft * factor;
        newY = leftEyeY + dyLeft * factor;
    } else if (distRight < eyeRadius) {
        float factor = 1.0 - (distRight / eyeRadius) * strength;
        newX = rightEyeX + dxRight * factor;
        newY = rightEyeY + dyRight * factor;
    }
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for funhouse_mirror
kernel void draw_grid_overlay_funhouse_mirror(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float angle = atan2(dy, dx);
    float dist = sqrt(dx * dx + dy * dy);
    
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float waveAmount = 30.0;
    float frequency = 6.0;
    float radialOffset = sin(angle * frequency) * waveAmount * normalizedDist;
    
    float newDist = dist + radialOffset;
    float newX = cX + cos(angle) * newDist;
    float newY = cY + sin(angle) * newDist;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for pinch_cheeks
kernel void draw_grid_overlay_pinch_cheeks(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float cheekOffsetX = float(width) * 0.2;
    float cheekOffsetY = float(height) * 0.08;
    float leftCheekX = cX - cheekOffsetX;
    float leftCheekY = cY + cheekOffsetY;
    float rightCheekX = cX + cheekOffsetX;
    float rightCheekY = cY + cheekOffsetY;
    float cheekRadius = min(float(width), float(height)) * 0.15;
    const float pinchStrength = 0.5;
    
    float2 pos = float2(gid);
    float newX = pos.x;
    float newY = pos.y;
    
    float dxLeft = pos.x - leftCheekX;
    float dyLeft = pos.y - leftCheekY;
    float distLeft = sqrt(dxLeft * dxLeft + dyLeft * dyLeft);
    
    if (distLeft < cheekRadius) {
        float factor = 1.0 + (distLeft / cheekRadius - 1.0) * pinchStrength;
        newX = leftCheekX + dxLeft * factor;
        newY = leftCheekY + dyLeft * factor;
    }
    
    float dxRight = pos.x - rightCheekX;
    float dyRight = pos.y - rightCheekY;
    float distRight = sqrt(dxRight * dxRight + dyRight * dyRight);
    
    if (distRight < cheekRadius) {
        float factor = 1.0 + (distRight / cheekRadius - 1.0) * pinchStrength;
        newX = rightCheekX + dxRight * factor;
        newY = rightCheekY + dyRight * factor;
    }
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for pincushion
kernel void draw_grid_overlay_pincushion(texture2d<float, access::read> inTexture [[texture(0)]],
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
    float dist = sqrt(dx * dx + dy * dy);
    
    const float k = 0.5;
    float factor = 1.0 + k * dist * dist;
    
    float newX = cX + dx * cX * factor;
    float newY = cY + dy * cY * factor;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for radial_wobble
kernel void draw_grid_overlay_radial_wobble(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float wobbleAmount = 20.0;
    float frequency = 8.0;
    float maxDist = sqrt(cX * cX + cY * cY);
    float normalizedDist = dist / maxDist;
    
    float angleOffset = sin(normalizedDist * frequency * M_PI_F) * (wobbleAmount / 180.0 * M_PI_F);
    float newAngle = angle + angleOffset;
    
    float newX = cX + cos(newAngle) * dist;
    float newY = cY + sin(newAngle) * dist;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for ultimate_distortion
kernel void draw_grid_overlay_ultimate_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float swirl = normalizedDist * normalizedDist * 3.0;
    float newAngle = angle + swirl;
    
    float bulge = 1.0 - normalizedDist * 0.3;
    float newDist = dist * bulge;
    
    float wobble = sin(angle * 5.0) * 15.0 * normalizedDist;
    newDist += wobble;
    
    float newX = cX + cos(newAngle) * newDist;
    float newY = cY + sin(newAngle) * newDist;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for wobble_face
kernel void draw_grid_overlay_wobble_face(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float wobbleX = sin(pos.y / 30.0) * 15.0;
    float wobbleY = cos(pos.x / 30.0) * 15.0;
    
    float newX = pos.x + wobbleX;
    float newY = pos.y + wobbleY;
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Grid overlay for gentle_ripple
kernel void draw_grid_overlay_gentle_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
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
    
    float amplitude = 5.0;
    float frequency = 0.03;
    float offset = sin(dist * frequency) * amplitude;
    
    float angle = atan2(dy, dx);
    float newX = cX + (dist + offset) * cos(angle);
    float newY = cY + (dist + offset) * sin(angle);
    
    float2 gridPos = fmod(float2(newX, newY) + gridSpacing * 0.5, gridSpacing);
    bool isGridLine = gridPos.x < gridThickness || gridPos.y < gridThickness;
    
    float4 baseColor = inTexture.read(gid);
    float4 gridColor = float4(1.0, 1.0, 0.0, 1.0);
    float4 outputColor = isGridLine ? mix(baseColor, gridColor, intensity) : baseColor;
    outTexture.write(outputColor, gid);
}

// Continuing in next file due to length...
