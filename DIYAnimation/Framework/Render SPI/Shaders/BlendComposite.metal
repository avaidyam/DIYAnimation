#include <metal_stdlib>
using namespace metal;


//
// MARK: - Composite Modes
//


/// Macro to premultiply source and destination, and then unpremultiply the result.
#define composite_op(x) \
auto s = float4(Sp.rgb * Sp.a, Sp.a); \
auto d = float4(Dp.rgb * Dp.a, Dp.a); \
auto r = float4(0); \
x;\
return float4(r.rgb / r.a, r.a);

///
inline float4 composite_clear(float4 Sp, float4 Dp) {
    return float4(0);
}

///
inline float4 composite_source_copy(float4 Sp, float4 Dp) {
    return Sp;
}

///
inline float4 composite_source_over(float4 Sp, float4 Dp) {
    composite_op(r = d * (1 - s.a) + s);
}

///
inline float4 composite_source_in(float4 Sp, float4 Dp) {
    composite_op(r = s * d.a);
}

///
inline float4 composite_source_out(float4 Sp, float4 Dp) {
    composite_op(r = s * (1 - d.a));
}

///
inline float4 composite_source_atop(float4 Sp, float4 Dp) {
    //Rca = Sca * Da + Dca * (1 - Sa);
    //Ra = Da;
    composite_op(r = s * d.a + d * (1 - s.a));
}

///
inline float4 composite_destination_copy(float4 Sp, float4 Dp) {
    return Dp;
}

///
inline float4 composite_destination_over(float4 Sp, float4 Dp) {
    composite_op(r = s * (1 - d.a) + d);
}

///
inline float4 composite_destination_in(float4 Sp, float4 Dp) {
    composite_op(r = d * s.a);
}

///
inline float4 composite_destination_out(float4 Sp, float4 Dp) {
    composite_op(r = d * (1 - s.a));
}

///
inline float4 composite_destination_atop(float4 Sp, float4 Dp) {
    //Rca = Dca * Sa + Sca * (1 - Da);
    //Ra = Sa;
    composite_op(r = s * (1 - d.a) + d * s.a);
}

///
inline float4 composite_xor(float4 Sp, float4 Dp) {
    //Rca = Sca * (1 - Da) + Dca * (1 - Sa);
    //Ra = Sa + Da - 2 * Sa * Da;
    composite_op(r = s * (1 - d.a) + d * (1 - s.a));
}

///
inline float4 composite_plus_darker(float4 Sp, float4 Dp) {
    composite_op(r = max(0, 1 - ((1 - d) + (1 - s))));
}

///
inline float4 composite_plus_lighter(float4 Sp, float4 Dp) {
    composite_op(r = min(1, s + d));
}


//
// MARK: - Blend Modes
//


/// Macro to premultiply source and destination, and then unpremultiply the result.
#define blend_op(x) \
auto base = float3(baseIn.rgb * baseIn.a); \
auto blend = float3(blendIn.rgb * blendIn.a); \
auto out = float3(0); \
x;\
auto _alpha = baseIn.a + (blendIn.a - (baseIn.a * blendIn.a)); \
return float4(out / _alpha, _alpha);

///
inline float4 blend_normal(float4 baseIn, float4 blendIn) {
    blend_op(out = blend; base = base/*unused*/);
}

///
inline float4 blend_multiply(float4 baseIn, float4 blendIn) {
    blend_op(out = base * blend);
}

///
inline float4 blend_screen(float4 baseIn, float4 blendIn) {
    blend_op(out = 1.0 - (1.0 - blend) * (1.0 - base));
}

///
inline float4 blend_overlay(float4 baseIn, float4 blendIn) {
    blend_op(
        auto result1 = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
        auto result2 = 2.0 * base * blend;
        auto zeroOrOne = step(base, 0.5);
        out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
    );
}

///
inline float4 blend_darken(float4 baseIn, float4 blendIn) {
    blend_op(out = min(blend, base));
}

///
inline float4 blend_lighten(float4 baseIn, float4 blendIn) {
    blend_op(out = max(blend, base));
}

///
inline float4 blend_color_dodge(float4 baseIn, float4 blendIn) {
    blend_op(out = base / (1.0 - blend));
}

///
inline float4 blend_color_burn(float4 baseIn, float4 blendIn) {
    blend_op(out = 1.0 - (1.0 - blend) / base);
}

///
inline float4 blend_soft_light(float4 baseIn, float4 blendIn) {
    blend_op(
        auto result1 = 2.0 * base * blend + base * base * (1.0 - 2.0 * blend);
        auto result2 = sqrt(base) * (2.0 * blend - 1.0) + 2.0 * base * (1.0 - blend);
        auto zeroOrOne = step(0.5, blend);
        out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
    );
}

///
inline float4 blend_hard_light(float4 baseIn, float4 blendIn) {
    blend_op(
        auto result1 = 1.0 - 2.0 * (1.0 - base) * (1.0 - blend);
        auto result2 = 2.0 * base * blend;
        auto zeroOrOne = step(blend, 0.5);
        out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
    );
}

///
inline float4 blend_hard_mix(float4 baseIn, float4 blendIn) {
    blend_op(out = step(1 - base, blend));
}

///
inline float4 blend_difference(float4 baseIn, float4 blendIn) {
    blend_op(out = abs(blend - base));
}

///
inline float4 blend_exclusion(float4 baseIn, float4 blendIn) {
    blend_op(out = blend + base - (2.0 * blend * base));
}

///
inline float4 blend_subtract(float4 baseIn, float4 blendIn) {
    blend_op(out = base - blend);
}

///
inline float4 blend_negation(float4 baseIn, float4 blendIn) {
    blend_op(out = 1.0 - abs(1.0 - blend - base));
}

///
inline float4 blend_divide(float4 baseIn, float4 blendIn) {
    blend_op(out = base / (blend + 0.000000000001));
}

///
inline float4 blend_linear_burn(float4 baseIn, float4 blendIn) {
    blend_op(out = base + blend - 1.0);
}

///
inline float4 blend_linear_dodge(float4 baseIn, float4 blendIn) {
    blend_op(out = base + blend);
}

///
inline float4 blend_linear_light(float4 baseIn, float4 blendIn) {
    blend_op(
         for(int i = 0; i < 3; i++) {
             out[i] = blend[i] < 0.5 ?
                      max(base[i] + (2 * blend[i]) - 1, 0.0) :
                      min(base[i] + 2 * (blend[i] - 0.5), 1.0);
         }
    );
}

///
inline float4 blend_pin_light(float4 baseIn, float4 blendIn) {
    blend_op(
        auto check = step(0.5, blend);
        auto result1 = check * max(2.0 * (base - 0.5), blend);
        out = result1 + (1.0 - check) * min(2.0 * base, blend);
    );
}

///
inline float4 blend_vivid_light(float4 baseIn, float4 blendIn) {
    blend_op(
        auto result1 = 1.0 - (1.0 - blend) / (2.0 * base);
        auto result2 = blend / (2.0 * (1.0 - base));
        auto zeroOrOne = step(0.5, base);
        out = result2 * zeroOrOne + (1 - zeroOrOne) * result1;
    );
}


//
// MARK: - Color Modes
//


///
inline float3 gamma_correct(float3 color, float gamma) {
    return pow(color, 1.0 / gamma);
}

///
inline float4 desaturate(float3 color, float desaturation) {
    float3 grayXfer = float3(0.3, 0.59, 0.11);
    float3 gray = float3(dot(grayXfer, color));
    return float4(mix(color, gray, desaturation), 1.0);
}

///
inline float3 RGBToHSL(float3 color) {
    float3 hsl = float3(0);
    float _fmin = min(min(color.r, color.g), color.b);    //Min. value of RGB
    float _fmax = max(max(color.r, color.g), color.b);    //Max. value of RGB
    float delta = _fmax - _fmin;             //Delta RGB value
    hsl.z = (_fmax + _fmin) / 2.0; // Luminance
    if (delta == 0.0) {        //This is a gray, no chroma...
        hsl.x = 0.0;    // Hue
        hsl.y = 0.0;    // Saturation
    } else {                                   //Chromatic data...
        if (hsl.z < 0.5)
             hsl.y = delta / (_fmax + _fmin); // Saturation
        else hsl.y = delta / (2.0 - _fmax - _fmin); // Saturation
        
        float deltaR = (((_fmax - color.r) / 6.0) + (delta / 2.0)) / delta;
        float deltaG = (((_fmax - color.g) / 6.0) + (delta / 2.0)) / delta;
        float deltaB = (((_fmax - color.b) / 6.0) + (delta / 2.0)) / delta;
        
        if (color.r == _fmax )
            hsl.x = deltaB - deltaG; // Hue
        else if (color.g == _fmax)
            hsl.x = (1.0 / 3.0) + deltaR - deltaB; // Hue
        else if (color.b == _fmax)
            hsl.x = (2.0 / 3.0) + deltaG - deltaR; // Hue
        if (hsl.x < 0.0)
            hsl.x += 1.0; // Hue
        else if (hsl.x > 1.0)
            hsl.x -= 1.0; // Hue
    }
    return hsl;
}

///
inline float HSLToRGB_component(float f1, float f2, float hue) {
    if (hue < 0.0)
        hue += 1.0;
    else if (hue > 1.0)
        hue -= 1.0;
    float res;
    if ((6.0 * hue) < 1.0)
        res = f1 + (f2 - f1) * 6.0 * hue;
    else if ((2.0 * hue) < 1.0)
        res = f2;
    else if ((3.0 * hue) < 2.0)
        res = f1 + (f2 - f1) * ((2.0 / 3.0) - hue) * 6.0;
    else
        res = f1;
    return res;
}

///
inline float3 HSLToRGB(float3 hsl) {
    float3 rgb;
    if (hsl.y == 0.0) {
        rgb = float3(hsl.z);
    } else {
        float f2;
        if (hsl.z < 0.5)
             f2 = hsl.z * (1.0 + hsl.y);
        else f2 = (hsl.z + hsl.y) - (hsl.y * hsl.z);
        
        float f1 = 2.0 * hsl.z - f2;
        rgb.r = HSLToRGB_component(f1, f2, hsl.x + (1.0/3.0));
        rgb.g = HSLToRGB_component(f1, f2, hsl.x);
        rgb.b = HSLToRGB_component(f1, f2, hsl.x - (1.0/3.0));
    }
    return rgb;
}

///
inline float3 contrast_saturation_brightness(float3 color, float brt, float sat,
                                             float con)
{
    const float3 coeff = float3(0.2125, 0.7154, 0.0721);
    const float3 avg_lum = float3(0.5, 0.5, 0.5);
    
    float3 brtColor = color * brt;
    float3 intensity = float3(dot(brtColor, coeff));
    float3 satColor = mix(intensity, brtColor, sat);
    float3 conColor = mix(avg_lum, satColor, con);
    return conColor;
}

///
inline float3 blend_hue(float3 base, float3 blend) {
    float3 baseHSL = RGBToHSL(base);
    return HSLToRGB(float3(RGBToHSL(blend).r, baseHSL.g, baseHSL.b));
}

///
inline float3 blend_saturation(float3 base, float3 blend) {
    float3 baseHSL = RGBToHSL(base);
    return HSLToRGB(float3(baseHSL.r, RGBToHSL(blend).g, baseHSL.b));
}

///
inline float3 blend_color(float3 base, float3 blend) {
    float3 blendHSL = RGBToHSL(blend);
    return HSLToRGB(float3(blendHSL.r, blendHSL.g, RGBToHSL(base).b));
}

///
inline float3 blend_luminosity(float3 base, float3 blend) {
    float3 baseHSL = RGBToHSL(base);
    return HSLToRGB(float3(baseHSL.r, baseHSL.g, RGBToHSL(blend).b));
}
