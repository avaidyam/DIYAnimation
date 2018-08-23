#include <metal_stdlib>
using namespace metal;

/// If `1`, `RoundRect` uses `smoothstep()` to anti-alias corner edges.
#define SMOOTH_CORNERS 0

#if SMOOTH_CORNERS
#define AASTEP(x) smoothstep(0.0, 1.0, x)
#else
#define AASTEP(x) (x)/*step(0.5, x)*/
#endif

/// Describes a rectangle shape.
struct Rect {
public:
    float4 bounds;
    
    /// Create a new `Rect` with shape `bounds`.
    Rect(float4 bounds): bounds(bounds) {}
    
    /// Returns a smoothed boolean determining whether the given point is within
    /// the receiver's bounds.
    float contains(float2 p) {
        float2 s = step(this->bounds.xy, p) - step(this->bounds.zw, p);
        return s.x * s.y;
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` value.
    Rect inset(float inset) {
        return Rect(this->bounds + float4(1.0, 1.0, -1.0, -1.0) * inset);
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` coordinates.
    Rect inset(float4 inset) {
        return Rect(this->bounds + float4(1.0, 1.0, -1.0, -1.0) * inset.wxyz);
    }
};

/// Describes a rounded rectangle shape.
struct RoundedRect {
public:
    float4 bounds;
    float radius;
    
    /// Create a new `RoundedRect` with shape `bounds` and `radius`.
    RoundedRect(float4 bounds, float radius): bounds(bounds), radius(radius) {}
    
    /// Converts the `Rect` into a `RoundedRect` with given corner `radius`.
    RoundedRect(Rect rect, float radius): bounds(rect.bounds), radius(radius) {}
    
    /// Returns a smoothed boolean determining whether the given point is within
    /// the receiver's *corner-clipped* bounds.
    float contains(float2 p) {
        float2 size = this->bounds.zw - this->bounds.xy;
        float2 pos = p - this->bounds.xy - (size * 0.5);
        
        float r = max(min(min(abs(this->radius * 2.0), abs(size.x)), abs(size.y)), 1e-5);
        float2 uv = abs((pos) * 2.0 - 1.0) - size + r;
        float d = length(max(float2(0.0), uv)) / r;
        return clamp(((1.0 - d) / fwidth(d)), 0.0, 1.0);
        
        /* // simple rect:
        float2 d = abs(p * 2 - 1) - size;
        return clamp(min(1 - d / fwidth(d)), 0, 1);
        */
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` value.
    RoundedRect inset(float inset) {
        float4 new_bounds = this->bounds + float4(1.0, 1.0, -1.0, -1.0) * inset;
        return RoundedRect(new_bounds, max(this->radius - inset, 0.0));
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` coordinates.
    /// The radius inset is determined only by the `w` component.
    RoundedRect inset(float4 inset) {
        float4 new_bounds = this->bounds + float4(1.0, 1.0, -1.0, -1.0) * inset.wxyz;
        return RoundedRect(new_bounds, max(this->radius - inset.w, 0.0));
    }
    
    /// Converts the receiver into a `Rect`, losing its corner parameters.
    Rect convert() {
        return Rect(this->bounds);
    }
};

/// Describes an extended rounded rectangle (not a squircle!) shape.
/// Compared to `RoundedRect`, the `ExtendedRoundedRect` further provides
/// individual corner widths and heights to completely control rendered shape.
///
/// Note: this incurs about a ~20% GPU processing penalty.
struct ExtendedRoundedRect {
public:
    float4 bounds;
    float4 cwidths;
    float4 cheights;
    
    /// Create a new `ExtendedRoundedRect` with shape `bounds` and `radius`.
    ExtendedRoundedRect(float4 bounds, float4 radius):
        bounds(bounds), cwidths(float4(radius)), cheights(float4(radius)) {}
    
    /// Create a new `ExtendedRoundedRect` with shape `bounds` and individually
    /// specified corner widths and heights.
    ExtendedRoundedRect(float4 bounds, float4 cwidths, float4 cheights):
        bounds(bounds), cwidths(cwidths), cheights(cheights) {}
    
    /// Converts the `Rect` into a `ExtendedRoundedRect` with given `radius`.
    ExtendedRoundedRect(Rect rect, float radius):
        bounds(rect.bounds), cwidths(float4(radius)), cheights(float4(radius)) {}
    
    /// Converts the `Rect` into a `ExtendedRoundedRect` with given corner parameters.
    ExtendedRoundedRect(Rect rect, float4 cwidths, float4 cheights):
        bounds(rect.bounds), cwidths(cwidths), cheights(cheights) {}
    
    /// Converts the `RoundedRect` into a `ExtendedRoundedRect` with given corner
    /// parameters.
    ExtendedRoundedRect(RoundedRect rect):
        bounds(rect.bounds), cwidths(float4(rect.radius)),
        cheights(float4(rect.radius)) {}
    
    /// Returns a smoothed boolean determining whether the given point is within
    /// the receiver's *corner-clipped* bounds.
    float contains(float2 p) {
        if (p.x < this->bounds.x || p.y < this->bounds.y ||
            p.x >= this->bounds.z || p.y >= this->bounds.w)
            return 0.0;
        
        auto rad_tl = float2(this->cwidths.x, this->cheights.x);
        auto rad_tr = float2(this->cwidths.y, this->cheights.y);
        auto rad_br = float2(this->cwidths.z, this->cheights.z);
        auto rad_bl = float2(this->cwidths.w, this->cheights.w);
        
        auto ref_tl = this->bounds.xy + float2( this->cwidths.x,  this->cheights.x);
        auto ref_tr = this->bounds.zy + float2(-this->cwidths.y,  this->cheights.y);
        auto ref_br = this->bounds.zw + float2(-this->cwidths.z, -this->cheights.z);
        auto ref_bl = this->bounds.xw + float2( this->cwidths.w, -this->cheights.w);
        
        auto d_tl = ellipsis_contains(p, ref_tl, rad_tl);
        auto d_tr = ellipsis_contains(p, ref_tr, rad_tr);
        auto d_br = ellipsis_contains(p, ref_br, rad_br);
        auto d_bl = ellipsis_contains(p, ref_bl, rad_bl);
        
        auto corner_coverages = 1.0 - float4(d_tl, d_tr, d_br, d_bl);
        auto is_out = float4(p.x < ref_tl.x && p.y < ref_tl.y,
                             p.x > ref_tr.x && p.y < ref_tr.y,
                             p.x > ref_br.x && p.y > ref_br.y,
                             p.x < ref_bl.x && p.y > ref_bl.y);
        
        auto val = 1.0 - dot(is_out, corner_coverages);
        return AASTEP(val);
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` value.
    ExtendedRoundedRect inset(float inset) {
        return this->inset(float4(inset));
    }
    
    /// Returns a copy of the receiver shrunk by the provided `inset` coordinates.
    ExtendedRoundedRect inset(float4 inset) {
        float4 new_bounds = this->bounds + float4(1.0, 1.0, -1.0, -1.0) * inset.wxyz;
        float4 new_widths = max(this->cwidths - inset.wyyw, 0.0);
        float4 new_heights = max(this->cheights - inset.xxzz, 0.0);
        return ExtendedRoundedRect(new_bounds, new_widths, new_heights);
    }
    
    /// Converts the receiver into a `RoundRect`, using only its first corner's
    /// width as the total radius.
    RoundedRect convert_rounded() {
        return RoundedRect(this->bounds, this->cwidths.x);
    }
    
    /// Converts the receiver into a `Rect`, losing its corner parameters.
    Rect convert() {
        return Rect(this->bounds);
    }
    
private:
    
    /// Determines whether the ellipse portioned by `center` and `radius` contain
    /// `point`. Computes elliptical distance.
    float ellipsis_contains(float2 point, float2 center, float2 radius) {
        if (radius.x == 0 && radius.y == 0)
            return 0.5;
        float2 p0 = (point - center) / radius;
        return clamp(0.5 - ((dot(p0, p0) - 1.0) / length(2.0 * p0 / radius)), 0.0, 1.0);
    }
};
