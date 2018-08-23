#include <simd/simd.h>

///
/// NOTE: Declarations present in this file will be visible to both the shaders
///       and the Swift code importing the file in its bridging headers.
///

#if !defined(SWIFT_ENUM)
#define SWIFT_ENUM(_type, _name) enum _name : _type _name; enum _name : _type
#endif

/// The vertex and fragment shader input buffer indices.
typedef SWIFT_ENUM(int, BufferIndex) {
    
    /// The `GlobalNode` buffer index.
    BufferIndexGlobalNode = 0,
    
    /// The `LayerNode` buffer index.
    BufferIndexLayerNode = 1,
};

/// The fragment shader texture input buffer indices.
typedef SWIFT_ENUM(int, TextureIndex) {
    
    /// The contents texture index.
    TextureIndexContents = 0,
    
    /// The composite texture index. This is pre-rendered.
    TextureIndexComposite = 1,
    
    /// The shadow texture index. This is pre-rendered.
    TextureIndexShadow = 2,
    
    /// The mask texture index. This is pre-rendered.
    TextureIndexMask = 3,
};

/// The fragment shader sampler input buffer indices.
typedef SWIFT_ENUM(int, SamplerIndex) {
    
    /// The contents sampler index.
    SamplerIndexContents = 0,
};

/// The layer node to be rendered.
struct LayerNode {
    matrix_float4x4 transform;
    matrix_float4x4 contentsTransform;
    vector_float2 position;
    vector_float2 anchorPoint;
    vector_float4 bounds;
    vector_float4 backgroundColor;
    vector_float4 borderColor;
    float borderWidth;
    float cornerRadius;
    float mipBias;
    vector_float4 shadowColor;
    vector_float2 shadowOffset;
    float shadowRadius;
    float shadowOpacity;
    
    // 256 byte padding follows:
    //float pad000;
    vector_float4 pad01;
};

/// The global node encompassing the rendering scene.
struct GlobalNode {
    matrix_float4x4 transform;
    vector_float4 viewport;
    
    // 256 byte padding follows:
    vector_float4 pad01;
    vector_float4 pad02;
    vector_float4 pad03;
    matrix_float4x4 pad1;
    matrix_float4x4 pad2;
};
