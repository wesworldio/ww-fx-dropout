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

// Bulge Eyes
kernel void bulge_eyes(texture2d<float, access::read> inTexture [[texture(0)]],
                      texture2d<float, access::write> outTexture [[texture(1)]],
                      uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.5;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.6;
    const float effectRadius = radius * 0.6;
    
    float2 newPos = pos;
    if (dist < effectRadius) {
        float factor = 1.0 - (dist / effectRadius) * strength;
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funhouse Mirror
kernel void funhouse_mirror(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    
    const float strength = 0.4;
    float normalizedX = dx / (width / 2.0);
    float stretch = 1.0 + strength * sin(normalizedX * M_PI_F);
    
    float2 newPos = float2(center.x + dx * stretch, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Pinch Cheeks
kernel void pinch_cheeks(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 3.0;
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 0.4;
    float2 newPos = pos;
    
    if (dist < radius) {
        float normalizedDist = dist / radius;
        float factor = pow(normalizedDist, strength);
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Radial Wobble
kernel void radial_wobble(texture2d<float, access::read> inTexture [[texture(0)]],
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
    float angle = atan2(delta.y, delta.x);
    
    const float strength = 0.3;
    float normalizedDist = dist / radius;
    float wobble = sin(angle * 6.0) * strength * (1.0 - normalizedDist);
    float factor = 1.0 + wobble;
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Water Ripple
kernel void water_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
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
    const float ripples = 6.0;
    float offset = sin(dist / strength) * ripples;
    
    float2 newPos = pos + normalize(delta) * offset;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);
    
    const float strength = 0.5;
    float warpX = sin(angle * 4.0 + dist * 0.02) * strength * 20.0;
    float warpY = cos(angle * 4.0 + dist * 0.02) * strength * 20.0;
    
    float2 newPos = pos + float2(warpX, warpY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Wobble Face
kernel void wobble_face(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    
    float2 pos = float2(gid);
    
    const float strength = 10.0;
    const float frequency = 0.05;
    float offsetX = sin(pos.y * frequency) * strength;
    float offsetY = cos(pos.x * frequency) * strength;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Complex Ripple
kernel void complex_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float angle = atan2(delta.y, delta.x);
    
    const float strength = 20.0;
    float ripple1 = sin(dist * 0.1) * strength;
    float ripple2 = cos(angle * 5.0) * strength * 0.5;
    
    float2 newPos = pos + normalize(delta) * (ripple1 + ripple2);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Elastic Face
kernel void elastic_face(texture2d<float, access::read> inTexture [[texture(0)]],
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
    float factor = 1.0 + strength * sin(normalizedDist * M_PI_F * 3.0) * 0.3;
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Funny Squash
kernel void funny_squash(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float strength = 0.4;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 - strength * normalizedY * normalizedY;
    
    float2 newPos = float2(center.x + dx / factor, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funny Stretch
kernel void funny_stretch(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float strength = 1.2;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 + strength * normalizedX * normalizedX;
    
    float2 newPos = float2(pos.x, center.y + dy / factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Gentle Ripple
kernel void gentle_ripple(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    const float strength = 8.0;
    float offset = sin(dist * 0.1) * strength;
    
    float2 newPos = pos + normalize(delta) * offset;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Smush Face
kernel void smush_face(texture2d<float, access::read> inTexture [[texture(0)]],
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
    float factor = 1.0 - strength * normalizedDist;
    
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    
    const float strength = 0.5;
    float normalizedX = dx / (width / 2.0);
    float factor = 1.0 - strength * abs(normalizedX);
    
    float2 newPos = float2(center.x + dx * factor, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dy = pos.y - center.y;
    
    const float strength = 0.5;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 - strength * abs(normalizedY);
    
    float2 newPos = float2(pos.x, center.y + dy * factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Squish Face
kernel void squish_face(texture2d<float, access::read> inTexture [[texture(0)]],
                       texture2d<float, access::write> outTexture [[texture(1)]],
                       uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float xStrength = 0.4;
    const float yStrength = 0.2;
    
    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);
    
    float xFactor = 1.0 - xStrength * abs(normalizedX);
    float yFactor = 1.0 + yStrength * abs(normalizedY);
    
    float2 newPos = float2(center.x + dx * xFactor, center.y + dy * yFactor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Stretch Face
kernel void stretch_face(texture2d<float, access::read> inTexture [[texture(0)]],
                        texture2d<float, access::write> outTexture [[texture(1)]],
                        uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dy = pos.y - center.y;
    
    const float strength = 0.9;
    float normalizedY = dy / (height / 2.0);
    float factor = 1.0 + strength * abs(normalizedY);
    
    float2 newPos = float2(pos.x, center.y + dy / factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// Warp Face
kernel void warp_face(texture2d<float, access::read> inTexture [[texture(0)]],
                     texture2d<float, access::write> outTexture [[texture(1)]],
                     uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    
    float2 pos = float2(gid);
    float dx = pos.x - center.x;
    float dy = pos.y - center.y;
    
    const float strength = 0.8;
    float normalizedX = dx / (width / 2.0);
    float normalizedY = dy / (height / 2.0);
    
    float warpX = normalizedX * (1.0 + strength * sin(normalizedY * M_PI_F * 2.0));
    float warpY = normalizedY * (1.0 + strength * cos(normalizedX * M_PI_F * 2.0));
    
    float2 newPos = float2(center.x + warpX * (width / 2.0), center.y + warpY * (height / 2.0));
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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
    
    float2 pos = float2(gid);
    
    const float amplitude = 20.0;
    const float frequency = 0.05;
    
    float offsetX = sin(pos.y * frequency) * amplitude;
    float offsetY = cos(pos.x * frequency) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
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

// MARK: - Elastic Warp Filters (14 variants)

kernel void elastic_warp_1(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    float normalized = dist / maxDist;
    
    float factor = 1.0 + 0.3 * sin(normalized * 6.28) * (1.0 - normalized);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_2(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    float normalized = dist / maxDist;
    
    float factor = 1.0 + 0.4 * cos(normalized * 3.14) * (1.0 - normalized);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_3(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.25 * sin(dist * 0.01) * exp(-dist * 0.002);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_4(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float factor = 1.0 + 0.35 * sin(normalized * 8.0) * (1.0 - pow(normalized, 2.0));
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_5(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.2 * pow(sin(dist * 0.015), 2.0) * exp(-dist * 0.0015);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_6(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float wave = sin(normalized * 4.0 + atan2(delta.y, delta.x)) * 0.3;
    float factor = 1.0 + wave * (1.0 - normalized);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_7(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.28 * sin(dist * 0.008) * cos(atan2(delta.y, delta.x) * 2.0);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_8(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float factor = pow(1.0 - (dist / maxDist), 1.5) * 0.4 + (1.0 - sin(dist * 0.01) * 0.2);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_9(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.32 * cos(dist * 0.012) * sin(atan2(delta.y, delta.x) * 3.0);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_10(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float factor = 1.0 + 0.3 * sin(normalized * 5.0) * cos(normalized * 3.0) * (1.0 - normalized);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_11(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float factor = 1.0 + 0.25 * sin(dist * 0.009 + angle * 4.0) * exp(-dist * 0.002);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_12(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.38 * sin(dist * 0.007) * pow(cos(atan2(delta.y, delta.x)), 2.0);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_13(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float factor = 1.0 + 0.35 * cos(normalized * 6.28) * sin(normalized * 3.14);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void elastic_warp_14(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float factor = 1.0 + 0.3 * sin(dist * 0.011 + angle * 2.0) * cos(angle * 2.0);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// MARK: - Stretch Distortion Filters (14 variants)

kernel void stretch_distort_1(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float stretchX = 1.0 + 0.4 * abs(sin(delta.y * 0.01));
    float stretchY = 1.0 + 0.3 * abs(cos(delta.x * 0.01));
    
    float2 newPos = center + float2(delta.x * stretchX, delta.y * stretchY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_2(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float dist = length(delta);
    float stretch = 1.0 + 0.5 * sin(dist * 0.01);
    
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_3(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float normalized = dist / maxDist;
    float stretch = 1.0 + 0.45 * pow(sin(normalized * 3.14), 2.0);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_4(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float stretch = 1.0 + 0.4 * sin(angle * 4.0);
    
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_5(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float stretchX = 1.0 + 0.35 * sin(delta.x * 0.008);
    float stretchY = 1.0 + 0.35 * cos(delta.y * 0.008);
    
    float2 newPos = center + float2(delta.x * stretchX, delta.y * stretchY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_6(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float stretch = 1.0 + 0.48 * sin(dist * 0.009) * cos(dist * 0.005);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_7(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float stretch = 1.0 + 0.5 * cos(normalized * 6.28) * (1.0 - normalized);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_8(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float stretch = 1.0 + 0.42 * sin(angle * 3.0) * cos(angle * 2.0);
    
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_9(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float stretch = 1.0 + 0.38 * pow(sin(dist * 0.012), 2.0);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_10(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float stretchX = 1.0 + 0.45 * sin(delta.y * 0.012);
    float stretchY = 1.0 + 0.45 * cos(delta.x * 0.012);
    
    float2 newPos = center + float2(delta.x * stretchX, delta.y * stretchY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_11(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float stretch = 1.0 + 0.4 * sin(dist * 0.008) * exp(-dist * 0.001);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_12(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float stretch = 1.0 + 0.44 * sin(angle * 6.0);
    
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_13(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float stretch = 1.0 + 0.48 * sin((dist / maxDist) * 4.0);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void stretch_distort_14(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float stretchX = 1.0 + 0.4 * cos(delta.y * 0.01);
    float stretchY = 1.0 + 0.4 * sin(delta.x * 0.01);
    
    float2 newPos = center + float2(delta.x * stretchX, delta.y * stretchY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// MARK: - Bulge Funhouse Filters (14 variants)

kernel void bulge_funhouse_1(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float bulge = 1.0 - 0.5 * pow(1.0 - normalized, 2.0);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_2(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float bulge = 1.0 - 0.45 * sin(dist * 0.01) * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_3(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float bulge = 1.0 - 0.4 * abs(sin(delta.x * 0.01)) * abs(cos(delta.y * 0.01));
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_4(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float bulge = 1.0 - 0.55 * pow(normalized, 1.5);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_5(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float bulge = 1.0 - 0.48 * cos(dist * 0.012) * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_6(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float bulge = 1.0 - 0.42 * sin(angle * 4.0);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_7(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float bulge = 1.0 - 0.5 * pow(sin((dist / maxDist) * 3.14), 2.0);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_8(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float bulge = 1.0 - 0.38 * abs(sin(delta.x * 0.012)) * abs(sin(delta.y * 0.012));
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_9(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float bulge = 1.0 - 0.45 * sin(dist * 0.008) * cos(atan2(delta.y, delta.x));
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_10(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float bulge = 1.0 - 0.52 * normalized * (1.0 - normalized);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_11(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float bulge = 1.0 - 0.44 * cos(angle * 3.0);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_12(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float bulge = 1.0 - 0.46 * pow(sin(dist * 0.011), 2.0);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_13(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float bulge = 1.0 - 0.4 * sin(delta.y * 0.008) * cos(delta.x * 0.008);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_funhouse_14(texture2d<float, access::read> inTexture [[texture(0)]],
                             texture2d<float, access::write> outTexture [[texture(1)]],
                             uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float bulge = 1.0 - 0.5 * (dist / maxDist) * (1.0 - sin(atan2(delta.y, delta.x) * 2.0) * 0.3);
    float2 newPos = center + delta / bulge;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// MARK: - Favorite Filter Variations (36 new variations)

// Bulge Eyes Variations
kernel void bulge_eyes_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float radius = min(width, height) / 2.8;
    
    float strength = 0.75;
    float effectRadius = radius * 0.7;
    float factor = 1.0 - (dist / effectRadius) * strength * 0.8;
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_eyes_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float radius = min(width, height) / 2.2;
    
    float effectRadius = radius * 0.5;
    float factor = 1.0 - pow(dist / effectRadius, 1.2) * 0.5;
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_eyes_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 - 0.55 * sin(dist * 0.008) * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void bulge_eyes_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float factor = 1.0 - 0.65 * pow(1.0 - normalized, 1.5);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funhouse Mirror Variations
kernel void funhouse_mirror_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float dy = pos.y - center.y;
    
    float strength = 0.5;
    float normalizedY = dy / (height / 2.0);
    float stretch = 1.0 + strength * cos(normalizedY * M_PI_F);
    
    float2 newPos = float2(pos.x, center.y + dy * stretch);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funhouse_mirror_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float strength = 0.35;
    float normalizedX = delta.x / (width / 2.0);
    float stretch = 1.0 + strength * sin(normalizedX * M_PI_F * 2.0);
    
    float2 newPos = float2(center.x + delta.x * stretch, pos.y);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funhouse_mirror_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float strength = 0.32;
    float stretch = 1.0 + strength * sin(dist * 0.01);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funhouse_mirror_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                              texture2d<float, access::write> outTexture [[texture(1)]],
                              uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float stretch = 1.0 + 0.28 * sin(angle * 3.0);
    float2 newPos = center + delta * stretch;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Funny Squash Variations
kernel void funny_squash_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float squash = 1.0 - 0.4 * pow(normalized, 1.3);
    float2 newPos = center + delta * squash;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funny_squash_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float squashX = 1.0 - 0.35 * abs(sin(delta.y * 0.008));
    float squashY = 1.0 - 0.35 * abs(cos(delta.x * 0.008));
    float2 newPos = center + float2(delta.x * squashX, delta.y * squashY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funny_squash_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float squash = 1.0 - 0.48 * cos(dist * 0.009);
    float2 newPos = center + delta * squash;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void funny_squash_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float squash = 1.0 - 0.42 * sin(angle * 4.0);
    float2 newPos = center + delta * squash;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Pinch Cheeks Variations
kernel void pinch_cheeks_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 2.8;
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float strength = 0.5;
    float2 newPos = pos;
    if (dist < radius) {
        float normalizedDist = dist / radius;
        float factor = pow(normalizedDist, strength * 1.2);
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pinch_cheeks_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float radius = min(width, height) / 3.5;
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float2 newPos = pos;
    if (dist < radius) {
        float normalizedDist = dist / radius;
        float factor = normalizedDist * normalizedDist;
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pinch_cheeks_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float radius = min(width, height) / 2.5;
    
    float strength = 0.35;
    float2 newPos = pos;
    if (dist < radius) {
        float normalizedDist = dist / radius;
        float factor = 1.0 - sin(normalizedDist * 1.57) * strength;
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pinch_cheeks_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float radius = min(width, height) / 3.0;
    
    float2 newPos = pos;
    if (dist < radius) {
        float normalizedDist = dist / radius;
        float factor = pow(1.0 - normalizedDist, 1.8);
        newPos = center + delta * factor;
    }
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Pincushion Variations
kernel void pincushion_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float factor = 1.0 + 0.35 * pow(dist / maxDist, 2.0);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pincushion_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float factor = 1.0 + 0.28 * sin(dist * 0.011);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pincushion_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = min(width, height) / 2.0;
    
    float normalized = dist / maxDist;
    float factor = 1.0 + 0.32 * pow(normalized, 1.8);
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void pincushion_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                         texture2d<float, access::write> outTexture [[texture(1)]],
                         uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float dist = length(delta);
    float factor = 1.0 + 0.25 * sin(angle * 2.0) * (dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta * factor;
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Radial Wobble Variations
kernel void radial_wobble_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float wobble = sin(angle * 4.0) * 0.08;
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void radial_wobble_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float wobble = cos(angle * 6.0) * 0.06 * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(sourcePos);
}

kernel void radial_wobble_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float angle = atan2(delta.y, delta.x);
    float wobble = sin(angle * 3.0) * cos(angle * 2.0) * 0.07;
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void radial_wobble_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                            texture2d<float, access::write> outTexture [[texture(1)]],
                            uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float wobble = sin(angle * 8.0) * 0.05 * exp(-dist * 0.002);
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Ultimate Distortion Variations
kernel void ultimate_distortion_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float complex = sin(dist * 0.012) * cos(angle * 5.0) * 0.35;
    float2 newPos = center + delta * (1.0 + complex);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void ultimate_distortion_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    float maxDist = length(float2(width, height)) / 2.0;
    
    float factor = pow(dist / maxDist, 1.2) * 0.4 + sin(atan2(delta.y, delta.x) * 4.0) * 0.2;
    float2 newPos = center + delta * (1.0 + factor);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void ultimate_distortion_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float complex = sin(delta.x * 0.009) * cos(delta.y * 0.009) * 0.38;
    float2 newPos = center + delta * (1.0 + complex);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void ultimate_distortion_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                                  texture2d<float, access::write> outTexture [[texture(1)]],
                                  uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float complex = sin(dist * 0.01) * sin(angle * 3.0) * 0.32;
    float2 newPos = center + delta * (1.0 + complex);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Water Ripple Variations
kernel void water_ripple_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 pos = float2(gid);
    
    float amplitude = 12.0;
    float frequency = 0.04;
    
    float offsetX = sin(pos.y * frequency) * amplitude;
    float offsetY = cos(pos.x * frequency) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void water_ripple_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 pos = float2(gid);
    
    float amplitude = 18.0;
    float frequency = 0.07;
    
    float offsetX = sin(pos.y * frequency + pos.x * 0.03) * amplitude;
    float offsetY = cos(pos.x * frequency - pos.y * 0.03) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void water_ripple_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 pos = float2(gid);
    float2 center = float2(width / 2.0, height / 2.0);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float amplitude = 10.0 * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float frequency = 0.05;
    
    float offsetX = sin(pos.y * frequency) * amplitude;
    float offsetY = cos(pos.x * frequency) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void water_ripple_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                           texture2d<float, access::write> outTexture [[texture(1)]],
                           uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 pos = float2(gid);
    
    float amplitude = 14.0;
    float frequency = 0.06;
    float phase = sin(pos.x * 0.01);
    
    float offsetX = sin(pos.y * frequency + phase) * amplitude;
    float offsetY = cos(pos.x * frequency + phase) * amplitude;
    
    float2 newPos = pos + float2(offsetX, offsetY);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

// Wobble Face Variations
kernel void wobble_face_v2(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float wobble = sin(delta.y * 0.008) * 0.12;
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void wobble_face_v3(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float wobble = sin(dist * 0.009) * cos(atan2(delta.y, delta.x)) * 0.11;
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void wobble_face_v4(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    
    float wobble = cos(delta.x * 0.008) * 0.1;
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}

kernel void wobble_face_v5(texture2d<float, access::read> inTexture [[texture(0)]],
                          texture2d<float, access::write> outTexture [[texture(1)]],
                          uint2 gid [[thread_position_in_grid]]) {
    if (gid.x >= outTexture.get_width() || gid.y >= outTexture.get_height()) return;
    
    uint width = inTexture.get_width();
    uint height = inTexture.get_height();
    float2 center = float2(width / 2.0, height / 2.0);
    float2 pos = float2(gid);
    float2 delta = pos - center;
    float dist = length(delta);
    
    float angle = atan2(delta.y, delta.x);
    float wobble = sin(angle * 4.0) * 0.09 * (1.0 - dist / (length(float2(width, height)) / 2.0));
    float2 newPos = center + delta * (1.0 + wobble);
    
    uint2 sourcePos = uint2(clamp(newPos, float2(0.0), float2(width - 1, height - 1)));
    float4 color = inTexture.read(sourcePos);
    outTexture.write(color, gid);
}
