#include <metal_stdlib>
#include "LayerShaderBridge.h"
#include "RoundedRect.metal"
#include "BlendComposite.metal"
using namespace metal;

// TODO: switch to half values instead of float!

/// Quad vertices lookup table. XY = position, ZW = texCoords.
/// This reduces the need to buffer the static quad vertices over from the CPU.
constant float4 quad_vertices[] = {
    float4(+1.0, -1.0, 1.0, 1.0), // t0.0
    float4(-1.0, -1.0, 0.0, 1.0), // t0.1
    float4(-1.0, +1.0, 0.0, 0.0), // t0.2
    float4(+1.0, -1.0, 1.0, 1.0), // t1.0
    float4(-1.0, +1.0, 0.0, 0.0), // t1.1
    float4(+1.0, +1.0, 1.0, 0.0), // t1.2
};

/// The interpolated data pssed from the vertex shader to any fragment shaders.
struct Varyings {
    
    /// The pixel screen coordinate of the current fragment.
    float4 position [[position]];
    
    /// The unit space coordinate of the fragment's texture.
    float2 texCoord [[user(texturecoord)]];
};

/// Emits a full-scene texture mapping.
vertex Varyings scene_emit_quad(uint vid [[vertex_id]])
{
    // Submit vertex without adjustment:
    Varyings output;
    output.position = float4(quad_vertices[vid].xy, 0, 1);
    output.texCoord = quad_vertices[vid].zw;
    return output;
}

/// Composite an existing scene saved as a texture.
fragment float4 scene_composite(Varyings input [[stage_in]],
                                texture2d<float> tex [[texture(TextureIndexComposite)]])
{
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);
    return tex.sample(texSampler, input.texCoord);
}

/// Composite an existing scene saved as a texture with its pre-rendered shadow.
fragment float4 scene_shadow(Varyings input [[stage_in]],
                             constant LayerNode& layer [[buffer(BufferIndexLayerNode)]],
                             texture2d<float> texture [[texture(TextureIndexComposite)]],
                             texture2d<float> shadow [[texture(TextureIndexShadow)]])
{
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);
    auto s = shadow.sample(texSampler, input.texCoord - layer.shadowOffset);
    auto c = texture.sample(texSampler, input.texCoord);
    
    // Source-over composite the two textures, applying the shadow parameters:
    auto color = float4(0);
    color.rgb = c.rgb + (float3(layer.shadowColor) * (1.0 - c.a));
    color.a = c.a + (s.a * layer.shadowOpacity * (1.0 - c.a));
    return color;
}

/// Composite an existing scene against a layer's bounds.
fragment float4 scene_mask_bounds_only(Varyings input [[stage_in]],
                                       texture2d<float> tex [[texture(TextureIndexComposite)]])
{
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);
    auto c = tex.sample(texSampler, input.texCoord);
    //
    return c;
}

/// Composite an existing scene against a layer's mask, pre-rendered as a texture.
fragment float4 scene_mask_layer_only(Varyings input [[stage_in]],
                                      texture2d<float> tex [[texture(TextureIndexComposite)]],
                                      texture2d<float> mask [[texture(TextureIndexShadow)]])
{
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);
    auto c = tex.sample(texSampler, input.texCoord);
    auto m = mask.sample(texSampler, input.texCoord);
    return c * m.a; // TODO: source-over
}

/// Composite an existing scene against a layer's mask, pre-rendered as a texture,
/// and its bounds, together.
fragment float4 scene_mask_and_bounds(Varyings input [[stage_in]],
                                      texture2d<float> tex [[texture(TextureIndexComposite)]],
                                      texture2d<float> mask [[texture(TextureIndexShadow)]])
{
    constexpr sampler texSampler(filter::linear, address::clamp_to_edge);
    auto c = tex.sample(texSampler, input.texCoord);
    auto m = mask.sample(texSampler, input.texCoord);
    return c * m.a; // TODO: source-over
}
