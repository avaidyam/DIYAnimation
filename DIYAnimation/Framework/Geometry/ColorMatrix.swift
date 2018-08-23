
// TODO: *, *=, values, hueRotate

/// Describes a color matrix used for blending transformations.
///
/// The color matrix transformation applies to an RGBA color like so:
/// | R' |     | m11 m12 m13 m14 m15 |   | R |
/// | G' |     | m21 m22 m23 m24 m25 |   | G |
/// | B' |  =  | m31 m32 m33 m34 m35 | * | B |
/// | A' |     | m41 m42 m43 m44 m45 |   | A |
/// | 1  |     |  0   0   0   0   1  |   | 1 |
///
public struct ColorMatrix: CustomStringConvertible, Codable, Hashable {
    
    ///
    public static let identity = ColorMatrix(
        1, 0, 0, 0, 0,
        0, 1, 0, 0, 0,
        0, 0, 1, 0, 0,
        0, 0, 0, 1, 0
    )
    
    /// Affects the saturation of colors. A `value` of `0` is grayscale. A value
    /// of `1` is identity. Anything greater than `1` over-saturates the color.
    public static func saturation(_ s: Float) -> ColorMatrix {
        let i = 1 - s, r = 0.213 * i, g = 0.715 * i, b = 0.072 * i
        return ColorMatrix(
            r+s, g,   b,   0, 0,
            r,   g+s, b,   0, 0,
            r,   g,   b+s, 0, 0,
            0,   0,   0,   1, 0
        )
    }
    
    /// Affects the hue of colors.
    public static func hueRotate(_ v: Float) -> ColorMatrix {
        return .identity
    }
    
    /// Converts luminance to alpha.
    public static let luminanceToAlpha = ColorMatrix(
        0,      0,      0,      0, 0,
        0,      0,      0,      0, 0,
        0,      0,      0,      0, 0,
        0.2125, 0.7154, 0.0721, 0, 0
    )
    
    /// Converts RGB to YUV color.
    public static let rgb2yuv = ColorMatrix(
        +0.29900, +0.58700, +0.11400, 0, 0,
        -0.16874, -0.33126, +0.50000, 0, 0,
        +0.50000, -0.41869, -0.08131, 0, 0,
        0,        0,        0,        1, 0
    )
    
    /// Converts RGB to YUV color.
    public static let yuv2rgb = ColorMatrix(
        0, 0,        +1.40200, 0, 0,
        1, -0.34414, -0.71414, 0, 0,
        1, 1.772000, 0,        0, 0,
        0, 0,        0,        1, 0
    )
    
    /// The underlying `SIMD` type for the first 4 columns.
    internal var m: float4x4
    
    /// The underlying `SIMD` type for the last column.
    internal var v: float4
    
    /// Create a new `ColorMatrix`.
    public init() {
        self.m = float4x4()
        self.v = float4()
    }
    
    /// Create a new `ColorMatrix`.
    public init(_ m11: Float, _ m12: Float, _ m13: Float, _ m14: Float, _ m15: Float,
                _ m21: Float, _ m22: Float, _ m23: Float, _ m24: Float, _ m25: Float,
                _ m31: Float, _ m32: Float, _ m33: Float, _ m34: Float, _ m35: Float,
                _ m41: Float, _ m42: Float, _ m43: Float, _ m44: Float, _ m45: Float)
    {
        self.m = float4x4(columns: (float4(m11, m12, m13, m14),
                                    float4(m21, m22, m23, m24),
                                    float4(m31, m32, m33, m34),
                                    float4(m41, m42, m43, m44)))
        self.v = float4(m15, m25, m35, m45)
    }
    
    /// Create a new `ColorMatrix` from the provided internal types.
    internal init(simd m: float4x4, _ v: float4) {
        self.m = m
        self.v = v
    }
    
    /// Applies the receiver to the provided `color`, returning a transformed
    /// color in the device RGB color space.
    ///
    /// The input `color` must be represented in the RGBA format.
    public func apply(_ color: CGColor) -> CGColor {
        var x = float4(color.rgba.map { Float($0) })
        x = self.m * x
        x += self.v
        return CGColor(red: CGFloat(x.x), green: CGFloat(x.y),
                       blue: CGFloat(x.z), alpha: CGFloat(x.w))
    }
    
    /// Returns the receiver.
    public static prefix func +(_ lhs: ColorMatrix) -> ColorMatrix {
        return lhs
    }
    
    /// Returns the negative of all elements of the receiver.
    public static prefix func -(_ lhs: ColorMatrix) -> ColorMatrix {
        return ColorMatrix(simd: -lhs.m, -lhs.v)
    }
    
    /// Add one `ColorMatrix` to another.
    public static func +(_ lhs: ColorMatrix, _ rhs: ColorMatrix) -> ColorMatrix {
        return ColorMatrix(simd: lhs.m + rhs.m, lhs.v + rhs.v)
    }
    
    /// Subtract one `ColorMatrix` from another.
    public static func -(_ lhs: ColorMatrix, _ rhs: ColorMatrix) -> ColorMatrix {
        return ColorMatrix(simd: lhs.m - rhs.m, lhs.v - rhs.v)
    }
    
    /// Multiply a `ColorMatrix` with a `Float`.
    public static func *(_ lhs: ColorMatrix, _ rhs: Float) -> ColorMatrix {
        return ColorMatrix(simd: lhs.m * rhs, lhs.v * rhs)
    }
    
    /// Concatenate one `ColorMatrix` with another. Multiplicative order matters.
    /*public static func *(_ lhs: ColorMatrix, _ rhs: ColorMatrix) -> ColorMatrix {
        return ColorMatrix(simd: lhs.m * rhs.m, lhs.v * rhs.v)
    }*/
    
    /// Add one `ColorMatrix` to another.
    public static func +=(_ lhs: inout ColorMatrix, _ rhs: ColorMatrix) {
        lhs.m += rhs.m
        lhs.v += rhs.v
    }
    
    /// Subtract one `ColorMatrix` from another.
    public static func -=(_ lhs: inout ColorMatrix, _ rhs: ColorMatrix) {
        lhs.m -= rhs.m
        lhs.v -= rhs.v
    }
    
    /// Concatenate one `ColorMatrix` with another. Multiplicative order matters.
    /*public static func *=(_ lhs: inout ColorMatrix, _ rhs: ColorMatrix) {
        lhs.m *= rhs.m
        lhs.v += rhs.v
    }*/
    
    /// Multiply a `ColorMatrix` with a `Float`.
    public static func *=(_ lhs: inout ColorMatrix, _ rhs: Float) {
        lhs.m *= rhs
        lhs.v *= rhs
    }
    
    /// Determine equality between two `ColorMatrix`s.
    public static func ==(_ lhs: ColorMatrix, _ rhs: ColorMatrix) -> Bool {
        return lhs.m == rhs.m && lhs.v == rhs.v
    }
    
    /// Describes the receiver as a string value.
    public var description: String {
        return "ColorMatrix()"//(\(self.values))"
    }
    
    ///
    public var hashValue: Int {
        return self.values.hashValue
    }
}

/// Compatibility with CoreAnimation.
extension ColorMatrix {
    
    /// The value contained in the color matrix at position 1,1.
    public var m11: Float {
        get { return self.m[0, 0] }
        set { self.m[0, 0] = newValue }
    }
    
    /// The value contained in the color matrix at position 1,2.
    public var m12: Float {
        get { return self.m[0, 1] }
        set { self.m[0, 1] = newValue }
    }
    
    /// The value contained in the color matrix at position 1,3.
    public var m13: Float {
        get { return self.m[0, 2] }
        set { self.m[0, 2] = newValue }
    }
    
    /// The value contained in the color matrix at position 1,4.
    public var m14: Float {
        get { return self.m[0, 3] }
        set { self.m[0, 3] = newValue }
    }
    
    /// The value contained in the color matrix at position 1,5.
    public var m15: Float {
        get { return self.v[0] }
        set { self.v[0] = newValue }
    }
    
    /// The value contained in the color matrix at position 2,1.
    public var m21: Float {
        get { return self.m[1, 0] }
        set { self.m[1, 0] = newValue }
    }
    
    /// The value contained in the color matrix at position 2,2.
    public var m22: Float {
        get { return self.m[1, 1] }
        set { self.m[1, 1] = newValue }
    }
    
    /// The value contained in the color matrix at position 2,3.
    public var m23: Float {
        get { return self.m[1, 2] }
        set { self.m[1, 2] = newValue }
    }
    
    /// The value contained in the color matrix at position 2,4.
    public var m24: Float {
        get { return self.m[1, 3] }
        set { self.m[1, 3] = newValue }
    }
    
    /// The value contained in the color matrix at position 2,5.
    public var m25: Float {
        get { return self.v[1] }
        set { self.v[1] = newValue }
    }
    
    /// The value contained in the color matrix at position 3,1.
    public var m31: Float {
        get { return self.m[2, 0] }
        set { self.m[2, 0] = newValue }
    }
    
    /// The value contained in the color matrix at position 3,2.
    public var m32: Float {
        get { return self.m[2, 1] }
        set { self.m[2, 1] = newValue }
    }
    
    /// The value contained in the color matrix at position 3,3.
    public var m33: Float {
        get { return self.m[2, 2] }
        set { self.m[2, 2] = newValue }
    }
    
    /// The value contained in the color matrix at position 3,4.
    public var m34: Float {
        get { return self.m[2, 3] }
        set { self.m[2, 3] = newValue }
    }
    
    /// The value contained in the color matrix at position 3,5.
    public var m35: Float {
        get { return self.v[2] }
        set { self.v[2] = newValue }
    }
    
    /// The value contained in the color matrix at position 4,1.
    public var m41: Float {
        get { return self.m[3, 0] }
        set { self.m[3, 0] = newValue }
    }
    
    /// The value contained in the color matrix at position 4,2.
    public var m42: Float {
        get { return self.m[3, 1] }
        set { self.m[3, 1] = newValue }
    }
    
    /// The value contained in the color matrix at position 4,3.
    public var m43: Float {
        get { return self.m[3, 2] }
        set { self.m[3, 2] = newValue }
    }
    
    /// The value contained in the color matrix at position 4,4.
    public var m44: Float {
        get { return self.m[3, 3] }
        set { self.m[3, 3] = newValue }
    }
    
    /// The value contained in the color matrix at position 4,5.
    public var m45: Float {
        get { return self.v[3] }
        set { self.v[3] = newValue }
    }
    
    /// All the values of the color matrix as 20-element array.
    ///
    /// The first 16 elements represent the multiplicative matrix, and the last
    /// four represent the added offset vector.
    public var values: [Float] {
        return self.v.map { $0 } +
            self.m.columns.0.map { $0 } +
            self.m.columns.1.map { $0 } +
            self.m.columns.2.map { $0 } +
            self.m.columns.3.map { $0 }
    }
}
