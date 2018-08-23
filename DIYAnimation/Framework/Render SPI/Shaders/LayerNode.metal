#include <metal_stdlib>
#include "LayerShaderBridge.h"
#include "RoundedRect.metal"
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

/// Emits a layer quad with texture mapping suitable for the below fragments.
vertex Varyings layer_emit_quad(constant GlobalNode& global [[buffer(BufferIndexGlobalNode)]],
                                constant LayerNode& layer [[buffer(BufferIndexLayerNode)]],
                                uint vid [[vertex_id]])
{
    // Apply model-view-projection transform to the current vertex:
    auto p = global.transform * layer.transform * float4(quad_vertices[vid].xy, 0, 1);
    
    // Submit vertex after adjusting `p` for the Metal NDC:
    Varyings output;
	output.position = p - float4(1, 1, 0, 0);
    output.texCoord = quad_vertices[vid].zw;
	return output;
}

/// Draws the layer background color with (optional) corner radius.
fragment float4 layer_background(Varyings input [[stage_in]],
                                 constant LayerNode& layer [[buffer(BufferIndexLayerNode)]])
{
    if (layer.cornerRadius > 0) {
        auto plane = float4(float2(0), layer.bounds.zw);
        auto exterior = RoundedRect(plane, layer.cornerRadius);
        auto ext_mix = exterior.contains(input.texCoord * plane.zw);
        return mix(layer.backgroundColor, float4(0), 1 - ext_mix);
    } else {
        return layer.backgroundColor;
    }
}

/// Draws the layer background color with (optional) corner radius.
/// Draws the layer contents texture; note that the origin quad may be larger
/// than the layer bounds and may require shape extrusion.
fragment float4 layer_contents(Varyings input [[stage_in]],
                               constant LayerNode& layer [[buffer(BufferIndexLayerNode)]],
                               texture2d<half> tex [[texture(TextureIndexContents)]],
                               sampler texSampler [[sampler(SamplerIndexContents)]])
{
    return float4(tex.sample(texSampler, input.texCoord, bias(layer.mipBias)));
}

/// Draws the layer border color with (optional) corner radius and set border width.
fragment float4 layer_border(Varyings input [[stage_in]],
                             constant LayerNode& layer [[buffer(BufferIndexLayerNode)]])
{
    if (layer.cornerRadius > 0) {
        auto plane = float4(float2(0), layer.bounds.zw);
        auto exterior = RoundedRect(plane, layer.cornerRadius);
        auto interior = exterior.inset(float4(layer.borderWidth));
        auto ext_mix = exterior.contains(input.texCoord * plane.zw);
        auto int_mix = interior.contains(input.texCoord * plane.zw);
        return mix(layer.borderColor, float4(0), 1 - clamp(ext_mix - int_mix, 0, 1));
    } else {
        auto plane = float4(float2(0), layer.bounds.zw);
        auto exterior = Rect(plane);
        auto interior = exterior.inset(float4(layer.borderWidth));
        auto ext_mix = exterior.contains(input.texCoord * plane.zw);
        auto int_mix = interior.contains(input.texCoord * plane.zw);
        return mix(layer.borderColor, float4(0), 1 - clamp(ext_mix - int_mix, 0, 1));
    }
}
