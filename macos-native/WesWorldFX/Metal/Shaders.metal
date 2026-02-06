//
//  Shaders.metal
//  WesWorld FX - Native Metal Shaders
//
//  High-performance GPU-accelerated distortion filters
//

#include <metal_stdlib>
using namespace metal;

// MARK: - Vertex/Fragment Shaders for Display

struct VertexIn {
    float2 position [[attribute(0)]];
    float2 texCoord [[attribute(1)]];
};

struct VertexOut {
    float4 position [[position]];
    float2 texCoord;
};

vertex VertexOut vertexShader(uint vertexID [[vertex_id]],
                               constant float4 *vertices [[buffer(0)]]) {
    VertexOut out;
    float4 vtx = vertices[vertexID];
    out.position = float4(vtx.xy, 0.0, 1.0);
    out.texCoord = vtx.zw;
    return out;
}

fragment float4 fragmentShader(VertexOut in [[stage_in]],
                                texture2d<float> texture [[texture(0)]]) {
    constexpr sampler textureSampler(mag_filter::linear, min_filter::linear);
    return texture.sample(textureSampler, in.texCoord);
}

// MARK: - Compute Shaders for Filters

// Upside Down
kernel void upside_down(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint height = inTexture.get_height();
    uint2 flippedPos = uint2(gid.x, height - 1 - gid.y);
    
    float4 color = inTexture.read(flippedPos);
    outTexture.write(color, gid);
}

// Upside Down V1 (with rotation)
kernel void upside_down_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    uint2 rotatedPos = uint2(width - 1 - gid.x, height - 1 - gid.y);
    
    float4 color = inTexture.read(rotatedPos);
    outTexture.write(color, gid);
}

// Bulge Eyes - Matches web implementation with dual eye positions
kernel void bulge_eyes(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    
    // Single bulge center point
    float bulgeRadius = min(float(width), float(height)) * 0.15;
    const float strength = 0.65;
    
    float2 pos = float2(gid);
    float newX = pos.x;
    float newY = pos.y;
    
    // Calculate distance to center
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    
    // Apply bulge
    if (dist < bulgeRadius) {
        float factor = 1.0 - (dist / bulgeRadius) * strength;
        newX = centerX + dx * factor;
        newY = centerY + dy * factor;
    }

    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)),
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funhouse Mirror - Matches web implementation with asymmetric distortion
kernel void funhouse_mirror(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 0.25;
    
    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    
    // Web version: horizontal stretch based on X position only
    float funhouseStretch = 1.0 + strength * sin(dx * M_PI_F);
    float newX = centerX + (pos.x - centerX) * funhouseStretch;
    float newY = pos.y;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Pinch Cheeks - Matches web implementation with angular pinching
kernel void pinch_cheeks(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.35;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Pinch sides inward - creates funny cheek effect
    float pinchFactor = 1.0 - strength * abs(cosAngle) * normalizedDist;
    float newDist = dist * pinchFactor;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Pincushion
kernel void pincushion(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.3;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 + strength);
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Radial Wobble - Matches web implementation with correct wobble amplitude
kernel void radial_wobble(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float normalizedDist = min(dist * invRadius, 1.0);
    
    // Wobbling radial distortion
    float wobble = sin(angle * 6.0) * 15.0 * normalizedDist;
    float newDist = dist + wobble;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Water Ripple - Matches web implementation
kernel void water_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    const float frequency = 0.05;
    const float amplitude = 15.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    
    // Web version: simple ripple without decay
    float ripple = sin(dist * frequency) * amplitude;
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float newX = pos.x + ripple * cosAngle;
    float newY = pos.y + ripple * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Ultimate Distortion
kernel void ultimate_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    float invHalfHeight = 1.0 / halfHeight;
    
    float x = float(gid.x);
    float y = float(gid.y);
    
    // Normalize coordinates
    float dx = (x - centerX) * invHalfWidth;
    float dy = (y - centerY) * invHalfHeight;
    float dx2 = dx * dx;
    float dy2 = dy * dy;
    
    // Pre-calculate sin/cos for dy
    float sinDyPI2 = sin(dy * M_PI_F * 2.0);
    float cosDyPI2 = cos(dy * M_PI_F * 2.0);
    
    // Funhouse mirror horizontal stretching
    float horizontalStretch = 0.3 * sinDyPI2 * dx;
    
    // Multiple ripple effects at different frequencies
    float distNorm = sqrt(dx2 + dy2);
    float ripple1 = sin(distNorm * 8.0) * 0.02;
    float ripple2 = sin(distNorm * 15.0) * 0.01;
    
    // Wobbling distortion
    float wobble = 0.1 * sin(dx * M_PI_F * 3.0) * cosDyPI2;
    
    // Combine all distortions
    float distortX = horizontalStretch + ripple1 + ripple2 + wobble;
    float distortY = ripple1 * 1.5 + ripple2 * 0.8;
    
    // Apply distortion to get source coordinates
    float newX = centerX + (x - centerX) * (1.0 + distortX);
    float newY = centerY + (y - centerY) * (1.0 + distortY);
    
    // Sample from source position
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Wobble Face - Matches web implementation with radial wobble
kernel void wobble_face(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 12.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float normalizedDist = min(dist * invRadius, 1.0);
    
    // Gentle wobbling distortion
    float wobble = strength * sin(angle * 6.0) * normalizedDist;
    float newDist = dist + wobble;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Complex Ripple - Matches web implementation with radial and angular ripples
kernel void complex_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Complex ripple with angular variation - reduced for subtlety
    float radialRipple = sin(dist * 0.06) * 6.0;
    float angularRipple = sin(angle * 4.0) * 3.0;
    float totalRipple = radialRipple + angularRipple;
    float newX = pos.x + totalRipple * cosAngle;
    float newY = pos.y + totalRipple * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Complex Ripple V1
kernel void complex_ripple_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 15.0;
    float ripple = sin(dist * 0.15 + cos(dist * 0.05) * 2.0) * strength;
    
    float2 newPos = pos + normalize(delta) * ripple;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Elastic Face - Matches web implementation with bouncy elastic-like distortion
kernel void elastic_face(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.5;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Bouncy elastic-like distortion
    float elasticFactor = 1.0 + strength * sin(normalizedDist * M_PI_F * 2.0) * 0.3;
    float newDist = normalizedDist * elasticFactor * radius;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Elastic Stretch
kernel void elastic_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    const float strength = 0.3;
    float normalizedY = delta.y / (height / 2.0);
    float factor = 1.0 + strength * sin(normalizedY * M_PI_F);
    
    float2 newPos = float2(center.x + delta.x * factor, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Elastic Stretch V1
kernel void elastic_stretch_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    const float strength = 0.4;
    float normalizedY = delta.y / (height / 2.0);
    float factor = 1.0 + strength * cos(normalizedY * M_PI_F * 2.0);
    
    float2 newPos = float2(center.x + delta.x * factor, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funny Squash - Matches web implementation with vertical squashing
kernel void funny_squash(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 0.4;
    
    float2 pos = float2(gid);
    float dy = (pos.y - centerY) * invHalfHeight;
    float squashFactor = 1.0 - strength * dy * dy;
    float newX = centerX + (pos.x - centerX) / squashFactor;
    float newY = pos.y;
    
    uint2 sourcePos = uint2(clamp(pos.x, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funny Stretch - Matches web implementation with horizontal stretch
kernel void funny_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    const float strength = 1.2;
    
    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    
    // Web version: vertical compression based on X position
    float stretchFactor = 1.0 + strength * dx * dx;
    float newX = pos.x;
    float newY = centerY + (pos.y - centerY) / stretchFactor;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(pos.y, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funny Stretch V1
kernel void funny_stretch_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float strength = 1.4;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 + strength * abs(normalizedX);
    
    float2 newPos = float2(pos.x, center.y + dy / factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Gentle Ripple - Matches web implementation with correct frequency and amplitude
kernel void gentle_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    const float frequency = 0.04;
    const float amplitude = 12.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    
    // Gentler ripple for subtle funny effect
    float ripple = sin(dist * frequency) * amplitude;
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float newX = pos.x + ripple * cosAngle;
    float newY = pos.y + ripple * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Lens Distortion
kernel void lens_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.7;
    float normalizedDist = dist / radius;
    float factor = 1.0 - strength * normalizedDist * normalizedDist;
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Lens Distortion V1
kernel void lens_distortion_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.5;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 - strength);
    
    float2 newPos = center + normalize(delta) * dist * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Multi Ripple
kernel void multi_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    
    float2 center1 = float2(width * 0.3, height * 0.3);
    float2 center2 = float2(width * 0.7, height * 0.7);
    
    float dist1 = length(pos - center1);
    float dist2 = length(pos - center2);
    
    const float strength = 10.0;
    float ripple1 = sin(dist1 * 0.1) * strength;
    float ripple2 = sin(dist2 * 0.1) * strength;
    
    float2 offset1 = normalize(pos - center1) * ripple1;
    float2 offset2 = normalize(pos - center2) * ripple2;
    
    float2 newPos = pos + offset1 + offset2;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Multi Ripple V1
kernel void multi_ripple_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    
    float2 center1 = float2(width * 0.25, height * 0.25);
    float2 center2 = float2(width * 0.75, height * 0.75);
    float2 center3 = float2(width * 0.5, height * 0.5);
    
    float dist1 = length(pos - center1);
    float dist2 = length(pos - center2);
    float dist3 = length(pos - center3);
    
    const float strength = 8.0;
    float ripple1 = sin(dist1 * 0.15) * strength;
    float ripple2 = sin(dist2 * 0.12) * strength;
    float ripple3 = cos(dist3 * 0.1) * strength * 0.5;
    
    float2 offset = normalize(pos - center1) * ripple1 +
                    normalize(pos - center2) * ripple2 +
                    normalize(pos - center3) * ripple3;
    
    float2 newPos = pos + offset * 0.5;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Radial Squeeze
kernel void radial_squeeze(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.6;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 + strength);
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Radial Squeeze V1
kernel void radial_squeeze_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.8;
    float normalizedDist = dist / radius;
    float factor = 1.0 - strength * exp(-normalizedDist * 2.0);
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Smush Face - Matches web implementation with radial compression
kernel void smush_face(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.3;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Smushes face from all sides
    float smushFactor = 1.0 - strength * normalizedDist * normalizedDist;
    float newDist = normalizedDist * smushFactor * radius;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squeeze Horizontal
kernel void squeeze_horizontal(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float normalizedX = dx * invHalfWidth;
    float squeezeFactor = 1.0 - 1.4 * normalizedX * normalizedX;
    float newX = centerX + dx * squeezeFactor;
    float newY = pos.y;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)),
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squeeze Horizontal V1
kernel void squeeze_horizontal_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    
    const float strength = 0.6;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 - strength * normalizedX * normalizedX;
    
    float2 newPos = float2(center.x + dx * factor, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squeeze Vertical
kernel void squeeze_vertical(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerY = float(height) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfHeight = 1.0 / halfHeight;
    
    float2 pos = float2(gid);
    float dy = pos.y - centerY;
    float normalizedY = dy * invHalfHeight;
    float squeezeFactor = 1.0 - 1.4 * normalizedY * normalizedY;
    float newX = pos.x;
    float newY = centerY + dy * squeezeFactor;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)),
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squeeze Vertical V1
kernel void squeeze_vertical_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                               texture2d<float, access::write> outTexture [[texture(1)]],
                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dy = pos.y - center.y;
    
    const float strength = 0.6;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 - strength * normalizedY * normalizedY;
    
    float2 newPos = float2(pos.x, center.y + dy * factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squish Face - Matches web implementation with horizontal compression
kernel void squish_face(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 1.1;
    
    float2 pos = float2(gid);
    float dy = (pos.y - centerY) * invHalfHeight;
    float squishFactor = 1.0 - strength * dy * dy;
    
    // Horizontal compression - makes face wider and funnier
    float newX = centerX + (pos.x - centerX) / squishFactor;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)), 
                           clamp(pos.y, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Squish Face V1
kernel void squish_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float xStrength = 0.5;
    const float yStrength = 0.3;
    
    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);
    
    float xFactor = 1.0 - xStrength * normalizedX * normalizedX;
    float yFactor = 1.0 + yStrength * normalizedY * normalizedY;
    
    float2 newPos = float2(center.x + dx * xFactor, center.y + dy * yFactor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Stretch Face - Matches web implementation with vertical stretch
kernel void stretch_face(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    const float strength = 1.4;
    
    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    
    // Vertical stretch - makes face taller and funnier
    float stretchFactor = 1.0 + strength * dx * dx;
    float newY = centerY + (pos.y - centerY) / stretchFactor;
    
    uint2 sourcePos = uint2(clamp(pos.x, 0.0, float(width - 1)), 
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Stretch Face V1
kernel void stretch_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dy = pos.y - center.y;
    
    const float strength = 1.4;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 + strength * normalizedY * normalizedY;
    
    float2 newPos = float2(pos.x, center.y + dy / factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Warp Face - Matches web implementation with funny expressions
kernel void warp_face(texture2d<float, access::read> inTexture [[texture(0)]],
                     texture2d<float, access::write> outTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 0.8;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float warpDx = dx * invHalfWidth;
    float warpDy = dy * invHalfHeight;
    
    // Web version: multiply normalized coords by wave factors
    float warpX = warpDx * (1.0 + strength * sin(warpDy * M_PI_F * 2.0));
    float warpY = warpDy * (1.0 + strength * cos(warpDx * M_PI_F * 2.0));
    float newX = centerX + warpX * halfWidth;
    float newY = centerY + warpY * halfHeight;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)),
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Warp Face V1
kernel void warp_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float strength = 1.0;
    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);
    
    float warpX = normalizedX * (1.0 + strength * cos(normalizedY * M_PI_F * 3.0));
    float warpY = normalizedY * (1.0 + strength * sin(normalizedX * M_PI_F * 3.0));
    
    float2 newPos = float2(center.x + warpX * (width / 2.0), center.y + warpY * (height / 2.0));
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Wave Distortion
kernel void wave_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    
    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    
    // Web version: combined radial and angular wave
    float waveX = sin(dist * 0.08 + angle * 2.0) * 6.0;
    float waveY = cos(dist * 0.06 - angle * 2.0) * 6.0;
    float newX = pos.x + waveX;
    float newY = pos.y + waveY;
    
    uint2 sourcePos = uint2(clamp(newX, 0.0, float(width - 1)),
                           clamp(newY, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Wave Distortion V1
kernel void wave_distortion_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    
    const float amplitude = 15.0;
    const float frequency = 0.08;
    
    float offsetX = sin(pos.y * frequency + pos.x * 0.02) * amplitude;
    float offsetY = cos(pos.x * frequency + pos.y * 0.02) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Simple Universal Grid Overlay - Used as fallback for all filters
kernel void draw_simple_grid_overlay(texture2d<float, access::read> inTexture [[texture(0)]],
                                     texture2d<float, access::write> outTexture [[texture(1)]],
                                     uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    // Read the input texture color
    float4 textureColor = inTexture.read(gid);
    
    // Grid parameters (match web)
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Check if this pixel is on a grid line
    bool onHorizontalGrid = (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0);
    bool onVerticalGrid = (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0);

    // Overlay yellow grid or write texture color
    if (onHorizontalGrid || onVerticalGrid) {
        outTexture.write(float4(1.0, 1.0, 0.0, 1.0), gid);
    } else {
        outTexture.write(textureColor, gid);
    }
}

// Grid Overlay with Bulge Eyes Distortion - Forward-maps grid lines like the web version
// Grid overlay for complex_ripple filter
kernel void draw_grid_overlay_complex_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                                             texture2d<float, access::write> outTexture [[texture(1)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;

    // Grid parameters (match web)
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Only draw for source grid points
    bool isGridPoint = false;
    if (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (!isGridPoint) {
        return;
    }

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    
    // Complex ripple with angular variation - same as complex_ripple filter
    float radialRipple = sin(dist * 0.06) * 6.0;
    float angularRipple = sin(angle * 4.0) * 3.0;
    float totalRipple = radialRipple + angularRipple;
    float newX = pos.x + totalRipple * cosAngle;
    float newY = pos.y + totalRipple * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for water_ripple filter
kernel void draw_grid_overlay_water_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;

    // Grid parameters (match web)
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Only draw for source grid points
    bool isGridPoint = false;
    if (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (!isGridPoint) {
        return;
    }

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    
    // Web version: simple ripple without decay
    const float frequency = 0.05;
    const float amplitude = 15.0;
    float ripple = sin(dist * frequency) * amplitude;
    float newX = pos.x + ripple * cos(angle);
    float newY = pos.y + ripple * sin(angle);

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for multi_ripple filter
kernel void draw_grid_overlay_multi_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;

    // Grid parameters (match web)
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Only draw for source grid points
    bool isGridPoint = false;
    if (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (!isGridPoint) {
        return;
    }

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);

    float ripple1 = sin(dist * 0.05) * 5.0;
    float ripple2 = sin(dist * 0.08) * 3.0;
    float ripple3 = sin(dist * 0.12) * 2.0;
    float totalRipple = ripple1 + ripple2 + ripple3;
    float newX = pos.x + totalRipple * cos(angle);
    float newY = pos.y + totalRipple * sin(angle);

    uint2 outPos = uint2(clamp(float2(newX, newY), float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for swirl filter

// Generic grid overlay for bulge_eyes filter (legacy)
kernel void draw_grid_overlay(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;

    // Grid parameters (match web)
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Read the input texture color first
    float4 textureColor = inTexture.read(gid);
    
    // Only draw grid for source grid points
    bool isGridPoint = false;
    if (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    if (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0) {
        isGridPoint = true;
    }
    
    // If it's a grid point, write yellow; otherwise write the texture color
    if (isGridPoint) {
        outTexture.write(float4(1.0, 1.0, 0.0, 1.0), gid);
    } else {
        outTexture.write(textureColor, gid);
    }
}


// ============================================================================
// COMPREHENSIVE GRID OVERLAY SHADERS FOR ALL FILTERS
// Each grid shader matches its corresponding filter's distortion exactly
// ============================================================================

inline bool isGridPoint(uint2 gid) {
    const uint gridSize = 30;
    const uint gridOffset = 5;
    if (gid.y >= gridOffset && ((gid.y - gridOffset) % gridSize) == 0) {
        return true;
    }
    if (gid.x >= gridOffset && ((gid.x - gridOffset) % gridSize) == 0) {
        return true;
    }
    return false;
}

// Grid overlay for upside_down
kernel void draw_grid_overlay_upside_down(texture2d<float, access::read> inTexture [[texture(0)]],
                                          texture2d<float, access::write> outTexture [[texture(1)]],
                                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint height = inTexture.get_height();
    float newX = float(gid.x);
    float newY = float(height - 1 - gid.y);

    uint2 outPos = uint2(clamp(newX, 0.0, float(outTexture.get_width() - 1)),
                         clamp(newY, 0.0, float(outTexture.get_height() - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for upside_down_v1 (rotation)
kernel void draw_grid_overlay_upside_down_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                             texture2d<float, access::write> outTexture [[texture(1)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float newX = float(width - 1 - gid.x);
    float newY = float(height - 1 - gid.y);

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for bulge_eyes - uses inverse distortion to find source grid lines
kernel void draw_grid_overlay_bulge_eyes(texture2d<float, access::read> inTexture [[texture(0)]],
                                         texture2d<float, access::write> outTexture [[texture(1)]],
                                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    // Read the input texture color first - this is the processed image
    float4 textureColor = inTexture.read(gid);
    
    // Always write the texture color as the base
    outTexture.write(textureColor, gid);

    // Grid parameters
    const uint gridSize = 30;
    const uint gridOffset = 5;

    // Check if this output position is on a grid line
    bool onHorizontalGrid = false;
    bool onVerticalGrid = false;
    
    uint gridX = gid.x;
    uint gridY = gid.y;
    
    if (gridY >= gridOffset && ((gridY - gridOffset) % gridSize) == 0) {
        onHorizontalGrid = true;
    }
    if (gridX >= gridOffset && ((gridX - gridOffset) % gridSize) == 0) {
        onVerticalGrid = true;
    }
    
    // Overlay yellow grid lines
    if (onHorizontalGrid || onVerticalGrid) {
        outTexture.write(float4(1.0, 1.0, 0.0, 1.0), gid);
    }
}

// Grid overlay for funhouse_mirror
kernel void draw_grid_overlay_funhouse_mirror(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    const float strength = 0.4;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float normalizedX = dx * invHalfWidth;
    float funhouseStretch = 1.0 + strength * sin(normalizedX * M_PI_F);
    float newX = centerX + dx * funhouseStretch;
    float newY = pos.y;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for funny_squash
kernel void draw_grid_overlay_funny_squash(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 0.4;

    float2 pos = float2(gid);
    float dy = pos.y - centerY;
    float normalizedY = dy * invHalfHeight;
    float squashFactor = 1.0 - strength * normalizedY * normalizedY;
    float newX = centerX + (pos.x - centerX) / squashFactor;
    float newY = pos.y;

    uint2 outPos = uint2(clamp(pos.x, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for pinch_cheeks
kernel void draw_grid_overlay_pinch_cheeks(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.35;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);

    float pinchFactor = 1.0 - strength * abs(cosAngle) * normalizedDist;
    float newDist = dist * pinchFactor;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for pincushion
kernel void draw_grid_overlay_pincushion(texture2d<float, access::read> inTexture [[texture(0)]],
                                         texture2d<float, access::write> outTexture [[texture(1)]],
                                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 0.3;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 + strength);

    float2 newPos = center + delta * factor;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for radial_wobble
kernel void draw_grid_overlay_radial_wobble(texture2d<float, access::read> inTexture [[texture(0)]],
                                            texture2d<float, access::write> outTexture [[texture(1)]],
                                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);

    float wobble = sin(angle * 6.0) * 15.0 * normalizedDist;
    float newDist = dist + wobble;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for ultimate_distortion
kernel void draw_grid_overlay_ultimate_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    float invHalfHeight = 1.0 / halfHeight;

    float x = float(gid.x);
    float y = float(gid.y);

    float dx = (x - centerX) * invHalfWidth;
    float dy = (y - centerY) * invHalfHeight;
    float dx2 = dx * dx;
    float dy2 = dy * dy;

    float sinDyPI2 = sin(dy * M_PI_F * 2.0);
    float cosDyPI2 = cos(dy * M_PI_F * 2.0);

    float horizontalStretch = 0.3 * sinDyPI2 * dx;

    float distNorm = sqrt(dx2 + dy2);
    float ripple1 = sin(distNorm * 8.0) * 0.02;
    float ripple2 = sin(distNorm * 15.0) * 0.01;

    float wobble = 0.1 * sin(dx * M_PI_F * 3.0) * cosDyPI2;

    float distortX = horizontalStretch + ripple1 + ripple2 + wobble;
    float distortY = ripple1 * 1.5 + ripple2 * 0.8;

    float newX = centerX + (x - centerX) * (1.0 + distortX);
    float newY = centerY + (y - centerY) * (1.0 + distortY);

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for wobble_face
kernel void draw_grid_overlay_wobble_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                          texture2d<float, access::write> outTexture [[texture(1)]],
                                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 12.0;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float normalizedDist = min(dist * invRadius, 1.0);

    float wobble = strength * sin(angle * 6.0) * normalizedDist;
    float newDist = dist + wobble;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for complex_ripple_v1
kernel void draw_grid_overlay_complex_ripple_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                texture2d<float, access::write> outTexture [[texture(1)]],
                                                uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 15.0;
    float ripple = sin(dist * 0.15 + cos(dist * 0.05) * 2.0) * strength;
    float2 newPos = pos + normalize(delta) * ripple;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for elastic_face
kernel void draw_grid_overlay_elastic_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.5;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);

    float elasticFactor = 1.0 + strength * sin(normalizedDist * M_PI_F * 2.0) * 0.3;
    float newDist = normalizedDist * elasticFactor * radius;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for elastic_stretch
kernel void draw_grid_overlay_elastic_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float2 delta = pos - center;
    const float strength = 0.3;
    float normalizedY = delta.y / (height / 2.0);
    float factor = 1.0 + strength * sin(normalizedY * M_PI_F);
    float2 newPos = float2(center.x + delta.x * factor, center.y + delta.y);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for elastic_stretch_v1
kernel void draw_grid_overlay_elastic_stretch_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float2 delta = pos - center;
    const float strength = 0.4;
    float normalizedY = delta.y / (height / 2.0);
    float factor = 1.0 + strength * cos(normalizedY * M_PI_F * 2.0);
    float2 newPos = float2(center.x + delta.x * factor, center.y + delta.y);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for funny_stretch
kernel void draw_grid_overlay_funny_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                                            texture2d<float, access::write> outTexture [[texture(1)]],
                                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    const float strength = 1.2;

    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    float stretchFactor = 1.0 + strength * dx * dx;
    float newX = pos.x;
    float centerY = float(height) / 2.0;
    float newY = centerY + (pos.y - centerY) / stretchFactor;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for funny_stretch_v1
kernel void draw_grid_overlay_funny_stretch_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                               texture2d<float, access::write> outTexture [[texture(1)]],
                                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;

    const float strength = 1.4;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 + strength * abs(normalizedX);

    float2 newPos = float2(pos.x, center.y + dy / factor);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for gentle_ripple
kernel void draw_grid_overlay_gentle_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                                            texture2d<float, access::write> outTexture [[texture(1)]],
                                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    const float frequency = 0.04;
    const float amplitude = 12.0;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);

    float ripple = sin(dist * frequency) * amplitude;
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);
    float newX = pos.x + ripple * cosAngle;
    float newY = pos.y + ripple * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for lens_distortion
kernel void draw_grid_overlay_lens_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 0.7;
    float normalizedDist = dist / radius;
    float factor = 1.0 - strength * normalizedDist * normalizedDist;
    float2 newPos = center + delta * factor;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for lens_distortion_v1
kernel void draw_grid_overlay_lens_distortion_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 0.5;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 - strength);
    float2 newPos = center + normalize(delta) * dist * factor;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for multi_ripple_v1
kernel void draw_grid_overlay_multi_ripple_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();

    float2 pos = float2(gid);
    float2 center1 = float2(width * 0.25, height * 0.25);
    float2 center2 = float2(width * 0.75, height * 0.75);
    float2 center3 = float2(width * 0.5, height * 0.5);

    float dist1 = length(pos - center1);
    float dist2 = length(pos - center2);
    float dist3 = length(pos - center3);

    const float strength = 8.0;
    float ripple1 = sin(dist1 * 0.15) * strength;
    float ripple2 = sin(dist2 * 0.12) * strength;
    float ripple3 = cos(dist3 * 0.1) * strength * 0.5;

    float2 offset = normalize(pos - center1) * ripple1 +
                    normalize(pos - center2) * ripple2 +
                    normalize(pos - center3) * ripple3;

    float2 newPos = pos + offset * 0.5;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for radial_squeeze
kernel void draw_grid_overlay_radial_squeeze(texture2d<float, access::read> inTexture [[texture(0)]],
                                             texture2d<float, access::write> outTexture [[texture(1)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 0.6;
    float normalizedDist = dist / radius;
    float factor = pow(normalizedDist, 1.0 + strength);
    float2 newPos = center + delta * factor;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for radial_squeeze_v1
kernel void draw_grid_overlay_radial_squeeze_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                texture2d<float, access::write> outTexture [[texture(1)]],
                                                uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.0;

    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);

    const float strength = 0.8;
    float normalizedDist = dist / radius;
    float factor = 1.0 - strength * exp(-normalizedDist * 2.0);
    float2 newPos = center + delta * factor;

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for smush_face
kernel void draw_grid_overlay_smush_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                         texture2d<float, access::write> outTexture [[texture(1)]],
                                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float radius = min(float(width), float(height)) / 2.0;
    float invRadius = 1.0 / radius;
    const float strength = 0.3;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float normalizedDist = min(dist * invRadius, 1.0);
    float angle = atan2(dy, dx);
    float cosAngle = cos(angle);
    float sinAngle = sin(angle);

    float smushFactor = 1.0 - strength * normalizedDist * normalizedDist;
    float newDist = normalizedDist * smushFactor * radius;
    float newX = centerX + newDist * cosAngle;
    float newY = centerY + newDist * sinAngle;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squeeze_horizontal
kernel void draw_grid_overlay_squeeze_horizontal(texture2d<float, access::read> inTexture [[texture(0)]],
                                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dx = pos.x - center.x;

    const float strength = 1.4;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 - strength * normalizedX * normalizedX;
    float2 newPos = float2(center.x + dx * factor, pos.y);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squeeze_horizontal_v1
kernel void draw_grid_overlay_squeeze_horizontal_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                    texture2d<float, access::write> outTexture [[texture(1)]],
                                                    uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dx = pos.x - center.x;

    const float strength = 0.6;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 - strength * normalizedX * normalizedX;
    float2 newPos = float2(center.x + dx * factor, pos.y);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squeeze_vertical
kernel void draw_grid_overlay_squeeze_vertical(texture2d<float, access::read> inTexture [[texture(0)]],
                                               texture2d<float, access::write> outTexture [[texture(1)]],
                                               uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dy = pos.y - center.y;

    const float strength = 1.4;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 - strength * normalizedY * normalizedY;
    float2 newPos = float2(pos.x, center.y + dy * factor);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squeeze_vertical_v1
kernel void draw_grid_overlay_squeeze_vertical_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dy = pos.y - center.y;

    const float strength = 0.6;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 - strength * normalizedY * normalizedY;
    float2 newPos = float2(pos.x, center.y + dy * factor);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squish_face
kernel void draw_grid_overlay_squish_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                          texture2d<float, access::write> outTexture [[texture(1)]],
                                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 1.1;

    float2 pos = float2(gid);
    float dy = (pos.y - centerY) * invHalfHeight;
    float squishFactor = 1.0 - strength * dy * dy;
    float newX = centerX + (pos.x - centerX) / squishFactor;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(pos.y, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for squish_face_v1
kernel void draw_grid_overlay_squish_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                             texture2d<float, access::write> outTexture [[texture(1)]],
                                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;

    const float xStrength = 0.5;
    const float yStrength = 0.3;

    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);

    float xFactor = 1.0 - xStrength * normalizedX * normalizedX;
    float yFactor = 1.0 + yStrength * normalizedY * normalizedY;

    float2 newPos = float2(center.x + dx * xFactor, center.y + dy * yFactor);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for stretch_face
kernel void draw_grid_overlay_stretch_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    const float strength = 1.4;

    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    float stretchFactor = 1.0 + strength * dx * dx;
    float newY = centerY + (pos.y - centerY) / stretchFactor;

    uint2 outPos = uint2(clamp(pos.x, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for stretch_face_v1
kernel void draw_grid_overlay_stretch_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dy = pos.y - center.y;

    const float strength = 1.4;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 + strength * normalizedY * normalizedY;

    float2 newPos = float2(pos.x, center.y + dy / factor);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for warp_face
kernel void draw_grid_overlay_warp_face(texture2d<float, access::read> inTexture [[texture(0)]],
                                        texture2d<float, access::write> outTexture [[texture(1)]],
                                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;
    float halfWidth = float(width) / 2.0;
    float halfHeight = float(height) / 2.0;
    float invHalfWidth = 1.0 / halfWidth;
    float invHalfHeight = 1.0 / halfHeight;
    const float strength = 0.8;

    float2 pos = float2(gid);
    float dx = (pos.x - centerX) * invHalfWidth;
    float dy = (pos.y - centerY) * invHalfHeight;

    float warpX = dx * (1.0 + strength * sin(dy * M_PI_F * 2.0));
    float warpY = dy * (1.0 + strength * cos(dx * M_PI_F * 2.0));
    float newX = centerX + warpX * halfWidth;
    float newY = centerY + warpY * halfHeight;

    uint2 outPos = uint2(clamp(newX, 0.0, float(width - 1)),
                         clamp(newY, 0.0, float(height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for warp_face_v1
kernel void draw_grid_overlay_warp_face_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                           texture2d<float, access::write> outTexture [[texture(1)]],
                                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);

    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;

    const float strength = 1.0;
    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);

    float warpX = normalizedX * (1.0 + strength * cos(normalizedY * M_PI_F * 3.0));
    float warpY = normalizedY * (1.0 + strength * sin(normalizedX * M_PI_F * 3.0));

    float2 newPos = float2(center.x + warpX * (width / 2.0), center.y + warpY * (height / 2.0));

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for wave_distortion
kernel void draw_grid_overlay_wave_distortion(texture2d<float, access::read> inTexture [[texture(0)]],
                                              texture2d<float, access::write> outTexture [[texture(1)]],
                                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float centerX = float(width) / 2.0;
    float centerY = float(height) / 2.0;

    float2 pos = float2(gid);
    float dx = pos.x - centerX;
    float dy = pos.y - centerY;
    float dist = sqrt(dx * dx + dy * dy);
    float angle = atan2(dy, dx);

    float waveX = sin(dist * 0.08 + angle * 2.0) * 6.0;
    float waveY = cos(dist * 0.06 - angle * 2.0) * 6.0;
    float2 newPos = pos + float2(waveX, waveY);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// Grid overlay for wave_distortion_v1
kernel void draw_grid_overlay_wave_distortion_v1(texture2d<float, access::read> inTexture [[texture(0)]],
                                                 texture2d<float, access::write> outTexture [[texture(1)]],
                                                 uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();

    float2 pos = float2(gid);
    const float amplitude = 15.0;
    const float frequency = 0.08;

    float offsetX = sin(pos.y * frequency + pos.x * 0.02) * amplitude;
    float offsetY = cos(pos.x * frequency + pos.y * 0.02) * amplitude;
    float2 newPos = pos + float2(offsetX, offsetY);

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}

// MARK: - Custom Bulge Filter Support

// Structure for custom bulge point
struct BulgePoint {
    float x;          // Normalized X position (0.0 to 1.0)
    float y;          // Normalized Y position (0.0 to 1.0)
    float radius;     // Normalized radius (0.0 to 1.0)
    float strength;   // Strength (-1.0 to 1.0, negative = pinch)
};

// Custom Bulge Filter - Supports multiple bulge/pinch points like Photoshop Liquify
kernel void custom_bulge(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        constant BulgePoint *bulgePoints [[buffer(0)]],
                        constant uint &pointCount [[buffer(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    float2 newPos = pos;
    
    // Apply each bulge point
    for (uint i = 0; i < pointCount; i++) {
        BulgePoint point = bulgePoints[i];
        
        // Convert normalized coordinates to pixel coordinates
        float2 center = float2(point.x * float(width), point.y * float(height));
        float bulgeRadius = point.radius * min(float(width), float(height));
        
        // Calculate distance to this bulge point
        float2 delta = newPos - center;
        float dist = length(delta);
        
        // Apply bulge/pinch effect
        if (dist < bulgeRadius && dist > 0.0) {
            float normalizedDist = dist / bulgeRadius;
            
            // Use smooth falloff curve
            float falloff = 1.0 - normalizedDist * normalizedDist;
            
            // Calculate displacement
            // Positive strength = bulge (push outward)
            // Negative strength = pinch (pull inward)
            float displacement = point.strength * falloff;
            
            // Apply displacement
            float2 direction = delta / dist;
            newPos += direction * displacement * bulgeRadius;
        }
    }
    
    // Sample from source texture
    uint2 sourcePos = uint2(clamp(newPos.x, 0.0, float(width - 1)),
                           clamp(newPos.y, 0.0, float(height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Grid overlay for custom_bulge - shows all bulge points
kernel void draw_grid_overlay_custom_bulge(texture2d<float, access::read> inTexture [[texture(0)]],
                                          texture2d<float, access::write> outTexture [[texture(1)]],
                                          constant BulgePoint *bulgePoints [[buffer(0)]],
                                          constant uint &pointCount [[buffer(1)]],
                                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    if (!isGridPoint(gid)) return;

    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    float2 newPos = pos;
    
    // Apply each bulge point (same logic as filter)
    for (uint i = 0; i < pointCount; i++) {
        BulgePoint point = bulgePoints[i];
        
        float2 center = float2(point.x * float(width), point.y * float(height));
        float bulgeRadius = point.radius * min(float(width), float(height));
        
        float2 delta = newPos - center;
        float dist = length(delta);
        
        if (dist < bulgeRadius && dist > 0.0) {
            float normalizedDist = dist / bulgeRadius;
            float falloff = 1.0 - normalizedDist * normalizedDist;
            float displacement = point.strength * falloff;
            float2 direction = delta / dist;
            newPos += direction * displacement * bulgeRadius;
        }
    }

    uint2 outPos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    outTexture.write(float4(1.0, 1.0, 0.0, 1.0), outPos);
}
