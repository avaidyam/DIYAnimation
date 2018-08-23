#include <metal_stdlib>
using namespace metal;


//
// MARK: - Color Matrix Filters
//


///
inline float4 color_matrix(float4 color, float4x4 blend, float4 offset) {
    return blend * color + offset;
}


//
// MARK: - Lanczos Resize
//



//
// MARK: - Gaussian Blur
//


