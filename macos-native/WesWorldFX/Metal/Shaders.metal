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
