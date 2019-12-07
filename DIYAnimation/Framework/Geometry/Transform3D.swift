import simd
import CoreGraphics

// TODO: Compose/Decompose don't correctly work as translated from WebCore!

///
public struct Transform3D: Codable, CustomStringConvertible, Hashable {
    
    ///
    internal struct Components: Equatable {
        var scale: SIMD3<Float>
        var skew: SIMD3<Float> // xy, xz, yz
        var quaternion: simd_quatf
        var translate: SIMD3<Float>
        var perspective: SIMD4<Float>
        internal init(scale: SIMD3<Float> = SIMD3<Float>(), skew: SIMD3<Float> = SIMD3<Float>(),
                      quaternion: simd_quatf = simd_quatf(),
                      translate: SIMD3<Float> = SIMD3<Float>(), perspective: SIMD4<Float> = SIMD4<Float>())
        {
            self.scale = scale
            self.skew = skew
            self.quaternion = quaternion
            self.translate = translate
            self.perspective = perspective
        }
    }
    
    /// The underlying `SIMD` type.
    internal var m: float4x4
    
    ///
    /// The default value is an identity matrix.
    public init() {
        self.m = float4x4()
    }
    
    ///
    public init(_ m11: Float, _ m12: Float, _ m13: Float, _ m14: Float,
                _ m21: Float, _ m22: Float, _ m23: Float, _ m24: Float,
                _ m31: Float, _ m32: Float, _ m33: Float, _ m34: Float,
                _ m41: Float, _ m42: Float, _ m43: Float, _ m44: Float)
    {
        self.m = float4x4(columns: (SIMD4<Float>(m11, m12, m13, m14),
                                    SIMD4<Float>(m21, m22, m23, m24),
                                    SIMD4<Float>(m31, m32, m33, m34),
                                    SIMD4<Float>(m41, m42, m43, m44)))
    }
    
    ///
    internal init(simd m: float4x4) {
        self.m = m
    }
    
    ///
    public var inverse: Transform3D {
        return Transform3D(simd: self.m.inverse)
    }
    
    ///
    public var transpose: Transform3D {
        return Transform3D(simd: self.m.transpose)
    }
    
    ///
    public var determinant: Float {
        return self.m.determinant
    }
    
    ///
    public subscript(column: Int) -> Vector3D {
        get { return Vector3D(simd: self.m[column]) }
        set { self.m[column] = newValue.v }
    }
    
    ///
    public subscript(column: Int, row: Int) -> Float {
        get { return self.m[column, row] }
        set { self.m[column, row] = newValue }
    }
    
    /// Semantically equivalent to `self.m *= other.m`.
    public mutating func concatenate(_ other: Transform3D) {
        self.m *= other.m
    }
    
    /// Semantically equivalent to `self.m * other.m`.
    public func concatenated(_ other: Transform3D) -> Transform3D {
        return Transform3D(simd: self.m * other.m)
    }
    
    ///
    @discardableResult
    public mutating func translated(x: Float = 0, y: Float = 0, z: Float = 0) -> Transform3D {
        self.m *= Transform3D.translation(x: x, y: y, z: z).m
        return self
    }
    
    ///
    @discardableResult
    public mutating func rotated(angle: Float, x: Float = 0, y: Float = 0, z: Float = 0) -> Transform3D {
        self.m *= Transform3D.rotation(angle: angle, x: x, y: y, z: z).m
        return self
    }
    
    ///
    @discardableResult
    public mutating func scaled(x: Float = 1, y: Float = 1, z: Float = 1) -> Transform3D {
        self.m *= Transform3D.scale(x: x, y: y, z: z).m
        return self
    }
    
    /// The identity transform that has no effect when applied to coordinates.
    public static let identity = Transform3D(simd: matrix_identity_float4x4)
    
    /// Create a transform that represents a perspective projection on the x, y,
    /// and z axes.
    public static func perspective(fov o: Float, aspect a: Float, zFar f: Float,
                                   zNear n: Float) -> Transform3D {
        return Transform3D(
            f / a,  0,              0,                  0,
            0,      1 / tan(o / 2), 0,                  0,
            0,      0,              f / (f - n),        1,
            0,      0,              -(n * f) / (f - n), 0
        )
    }
    
    /// Create a transform that represents an orthographic projection on the x,
    /// y, and z axes.
    public static func orthographic(left l: Float, right r: Float,
                                    bottom b: Float, top t: Float,
                                    zNear n: Float, zFar f: Float) -> Transform3D {
        return Transform3D(
            2 / (r - l), 0,           0,            0,
            0,           2 / (t - b), 0,            0,
            0,           0,           1 / (f - n),  0,
            0,           0,           -n / (f - n), 1
        )
    }
    
    /// Create a transform that represents a translation operation on the x, y,
    /// and z axes.
    public static func translation(x: Float = 0, y: Float = 0, z: Float = 0) -> Transform3D {
        return Transform3D(
            1, 0, 0, 0,
            0, 1, 0, 0,
            0, 0, 1, 0,
            x, y, z, 1
        )
    }
    
    /// Shortcut for internal use with SIMD variant types.
    @inline(__always)
    internal static func translation(_ vec: SIMD3<Float>) -> Transform3D {
        return Transform3D.translation(x: vec.x, y: vec.y, z: vec.z)
    }
    
    /// Create a transform that represents a rotation operation on the x, y,
    /// and z axes.
    public static func rotation(angle: Float, x: Float = 0, y: Float = 0, z: Float = 0) -> Transform3D {
        let n = simd_normalize(SIMD3<Float>(x, y, z))
        let c = cos(angle), s = sin(angle), ci = 1 - c
        return Transform3D(
            n.x*n.x*ci+c,       n.x*n.y*ci+n.z*s,   n.x*n.z*ci-n.y*s,   0,
            n.y*n.x*ci-n.z*s,   n.y*n.y*ci+c,       n.y*n.z*ci+n.x*s,   0,
            n.z*n.x*ci+n.y*s,   n.z*n.y*ci-n.x*s,   n.z*n.z*ci+c,       0,
            0,                  0,                  0,                  1
        )
    }
    
    /// Shortcut for internal use with SIMD variant types.
    @inline(__always)
    internal static func rotation(angle: Float, _ vec: SIMD3<Float>) -> Transform3D {
        return Transform3D.rotation(angle: angle, x: vec.x, y: vec.y, z: vec.z)
    }
    
    /// Create a transform that represents a scale operation on the x, y, and z
    /// axes.
    public static func scale(x: Float = 1, y: Float = 1, z: Float = 1) -> Transform3D {
        return Transform3D(
            x, 0, 0, 0,
            0, y, 0, 0,
            0, 0, z, 0,
            0, 0, 0, 1
        )
    }
    
    /// Shortcut for internal use with SIMD variant types.
    @inline(__always)
    internal static func scale(_ vec: SIMD3<Float>) -> Transform3D {
        return Transform3D.scale(x: vec.x, y: vec.y, z: vec.z)
    }
    
    /// Returns the receiver.
    public static prefix func +(_ lhs: Transform3D) -> Transform3D {
        return lhs
    }
    
    /// Returns the negative of all elements of the receiver.
    public static prefix func -(_ lhs: Transform3D) -> Transform3D {
        return Transform3D(simd: -lhs.m)
    }
    
    /// Multiply every element of the `Transform3D` by a scalar.
    public static func *(_ lhs: Float, _ rhs: Transform3D) -> Transform3D {
        return Transform3D(simd: lhs * rhs.m)
    }
    
    /// Multiply every element of the `Transform3D` by a scalar.
    public static func *(_ lhs: Transform3D, _ rhs: Float) -> Transform3D {
        return Transform3D(simd: lhs.m * rhs)
    }
    
    /// Add one `Transform3D` to another.
    public static func +(_ lhs: Transform3D, _ rhs: Transform3D) -> Transform3D {
        return Transform3D(simd: lhs.m + rhs.m)
    }
    
    /// Subtract one `Transform3D` from another.
    public static func -(_ lhs: Transform3D, _ rhs: Transform3D) -> Transform3D {
        return Transform3D(simd: lhs.m - rhs.m)
    }
    
    /// Concatenate one `Transform3D` with another. Multiplicative order matters.
    public static func *(_ lhs: Transform3D, _ rhs: Transform3D) -> Transform3D {
        return Transform3D(simd: lhs.m * rhs.m)
    }
    
    /// Add one `Transform3D` to another.
    public static func +=(_ lhs: inout Transform3D, _ rhs: Transform3D) {
        lhs.m += rhs.m
    }
    
    /// Subtract one `Transform3D` from another.
    public static func -=(_ lhs: inout Transform3D, _ rhs: Transform3D) {
        lhs.m -= rhs.m
    }
    
    /// Concatenate one `Transform3D` with another. Multiplicative order matters.
    public static func *=(_ lhs: inout Transform3D, _ rhs: Transform3D) {
        lhs.m *= rhs.m
    }
    
    /// Determine equality between two `Transform3D`s.
    public static func ==(_ lhs: Transform3D, _ rhs: Transform3D) -> Bool {
        return lhs.m == rhs.m
    }
    
    /// Apply the `Transform3D` to a `Vector3D`. Multiplicative order matters.
    public static func *(_ lhs: Vector3D, _ rhs: Transform3D) -> Vector3D {
        return Vector3D(simd: lhs.v * rhs.m)
    }
    
    /// Apply the `Transform3D` to a `Vector3D`. Multiplicative order matters.
    public static func *(_ lhs: Transform3D, _ rhs: Vector3D) -> Vector3D {
        return Vector3D(simd: lhs.m * rhs.v)
    }
    
    /// Describes the receiver as a string value.
    public var description: String {
        return "Transform3D(\(self.values))"
    }
    
    ///
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.values)
	}
}

/// Compatibility with CoreAnimation.
extension Transform3D {
    
    /// The value contained in the transformation matrix at position 1,1.
    public var m11: Float {
        get { return self.m[0, 0] }
        set { self.m[0, 0] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 1,2.
    public var m12: Float {
        get { return self.m[0, 1] }
        set { self.m[0, 1] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 1,3.
    public var m13: Float {
        get { return self.m[0, 2] }
        set { self.m[0, 2] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 1,4.
    public var m14: Float {
        get { return self.m[0, 3] }
        set { self.m[0, 3] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 2,1.
    public var m21: Float {
        get { return self.m[1, 0] }
        set { self.m[1, 0] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 2,2.
    public var m22: Float {
        get { return self.m[1, 1] }
        set { self.m[1, 1] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 2,3.
    public var m23: Float {
        get { return self.m[1, 2] }
        set { self.m[1, 2] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 2,4.
    public var m24: Float {
        get { return self.m[1, 3] }
        set { self.m[1, 3] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 3,1.
    public var m31: Float {
        get { return self.m[2, 0] }
        set { self.m[2, 0] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 3,2.
    public var m32: Float {
        get { return self.m[2, 1] }
        set { self.m[2, 1] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 3,3.
    public var m33: Float {
        get { return self.m[2, 2] }
        set { self.m[2, 2] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 3,4.
    public var m34: Float {
        get { return self.m[2, 3] }
        set { self.m[2, 3] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 4,1.
    public var m41: Float {
        get { return self.m[3, 0] }
        set { self.m[3, 0] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 4,2.
    public var m42: Float {
        get { return self.m[3, 1] }
        set { self.m[3, 1] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 4,3.
    public var m43: Float {
        get { return self.m[3, 2] }
        set { self.m[3, 2] = newValue }
    }
    
    /// The value contained in the transformation matrix at position 4,4.
    public var m44: Float {
        get { return self.m[3, 3] }
        set { self.m[3, 3] = newValue }
    }
    
    /// All the values of the transformation matrix as 16-element array.
    public var values: [Float] {
		return [
			self.m.columns.0,
			self.m.columns.1,
			self.m.columns.2,
			self.m.columns.3
		].flatMap { [$0.x, $0.y, $0.z, $0.w] }
    }
    
    /// Determines whether this transformation can be represented affine-ly.
    public var isAffine: Bool {
        return
            (self[0, 2] == 0 && self[0, 3] == 0) &&
            (self[1, 2] == 0 && self[1, 3] == 0) &&
            (self[2, 0] == 0 && self[2, 1] == 0) &&
            (self[2, 2] == 1 && self[2, 3] == 0) &&
            (self[3, 2] == 0 && self[3, 3] == 1)
    }
    
    /// Attempts to return an affine transform representing the receiver.
    public var affineTransform: CGAffineTransform {
        return CGAffineTransform(a: CGFloat(self[0, 0]),  b: CGFloat(self[0, 1]),
                                 c: CGFloat(self[1, 0]),  d: CGFloat(self[1, 1]),
                                 tx: CGFloat(self[3, 0]), ty: CGFloat(self[3, 1]))
    }
    
    /// Creates a `Transform3D` representing the affine transform provided.
    public init(affine a: CGAffineTransform) {
        self.init(Float(a.a),  Float(a.b),  0, 0,
                  Float(a.c),  Float(a.d),  0, 0,
                  0,           0,           1, 0,
                  Float(a.tx), Float(a.ty), 0, 1)
    }
}

internal extension Transform3D {
    
    /// Normalize the inner SIMD variant matrix.
    fileprivate func normalize() -> float4x4? {
        guard self.m[3, 3] != 0 else { return nil }
        var m = self.m
        for i in 0..<4 {
            for j in 0..<4 {
                m[i, j] /= m[3, 3]
            }
        }
        return m
    }
    
    ///
	func decompose() -> Components? {
        guard var m = self.normalize() else { return nil }
        m = m.transpose
        var result = Components()
        
        // perspectiveMatrix is used to solve for perspective, but it also provides
        // an easy way to test for singularity of the upper 3x3 component.
        // If the perspective matrix is not invertible, we are also unable to
        // decompose, so we'll bail early.
        var p = m
        p[0, 3] = 0; p[1, 3] = 0; p[2, 3] = 0; p[3, 3] = 1
        if abs(p.determinant) < 1e-8 /*epsilon*/ {
            return nil
        }
        
        // First, isolate perspective. This is the messiest.
        if m[0, 3] != 0 || m[1, 3] != 0 || m[2, 3] != 0 {
            // Solve the equation by inverting perspectiveMatrix and multiplying
            // rightHandSide by the inverse.
            //
            // Clear the perspective partition
            result.perspective = m.transpose.columns.3 * p.inverse.transpose
            m[0, 3] = 0; m[1, 3] = 0; m[2, 3] = 0; m[3, 3] = 1
        } else {
            // No perspective.
            result.perspective = SIMD4<Float>(0, 0, 0, 1)
        }
        
        // Next take care of translation (easy).
        result.translate = SIMD3<Float>(m[3, 0], m[3, 1], m[3, 2])
        m[3, 0] = 0; m[3, 1] = 0; m[3, 2] = 0
        
        // Now get scale and shear. // TODO: use float3x3!
        var row = [SIMD3<Float>(), SIMD3<Float>(), SIMD3<Float>()]
        for i in 0..<3 {
            row[i][0] = m[i, 0]
            row[i][1] = m[i, 1]
            row[i][2] = m[i, 2]
        }
        
        // Compute X scale factor and normalize first row.
        result.scale.x = simd_length(row[0])
        row[0] = simd_normalize(row[0])
        
        // Compute XY shear factor and make 2nd row orthogonal to 1st.
        result.skew.x = simd_dot(row[0], row[1])
        row[1] = simd_linear_combination(1.0, row[1], -result.skew.x, row[0])
        
        // Now, compute Y scale and normalize 2nd row.
        result.scale.y = simd_length(row[1])
        row[1] = simd_normalize(row[1])
        result.skew.x /= result.scale.y
        
        // Compute XZ and YZ shears, orthogonalize 3rd row.
        result.skew.y = simd_dot(row[0], row[2])
        row[2] = simd_linear_combination(1.0, row[2], -result.skew.y, row[0])
        result.skew.z = simd_dot(row[1], row[2])
        row[2] = simd_linear_combination(1.0, row[2], -result.skew.z, row[1])
        
        // Next, get Z scale and normalize 3rd row.
        result.scale.z = simd_length(row[2])
        row[2] = simd_normalize(row[2])
        result.skew.y /= result.scale.z
        result.skew.z /= result.scale.z
        
        // At this point, the matrix (in rows[]) is orthonormal.
        // Check for a coordinate system flip. If the determinant
        // is -1, then negate the matrix and the scaling factors.
        if simd_dot(row[0], simd_cross(row[1], row[2])) < 0 {
            result.scale *= -1
            for i in 0..<3 {
                row[i] *= -1
            }
        }
        
        // Now, get the rotations out, as described in the gem.
        let f3 = float3x3(rows: row)
        result.quaternion = simd_quatf(f3)
        return result
    }
    
    ///
	static func compose(_ components: Components) -> Transform3D {
        var m = matrix_identity_float4x4
        m.columns.3 = components.perspective
        m *= Transform3D.translation(components.translate).m
        m *= Transform3D.rotation(quaternion: components.quaternion).m
        m *= Transform3D.skew(yz: components.skew.z).m
        m *= Transform3D.skew(xz: components.skew.y).m
        m *= Transform3D.skew(xy: components.skew.x).m
        m *= Transform3D.scale(components.scale).m
        return Transform3D(simd: m)
    }
    
    ///
	static func interpolate(from _from: Transform3D, to _to: Transform3D, _ fraction: Float) -> Transform3D
    {
        guard var from = _from.decompose(), let to = _to.decompose() else {
            return fraction < 0.5 ? _from : _to
        }
		from.scale = simd_mix(from.scale, to.scale, SIMD3<Float>(repeating: fraction))
        from.skew = simd_mix(from.skew, to.skew, SIMD3<Float>(repeating: fraction))
        from.translate = simd_mix(from.translate, to.translate, SIMD3<Float>(repeating: fraction))
        from.perspective = simd_mix(from.perspective, to.perspective, SIMD4<Float>(repeating: fraction))
        from.quaternion = simd_slerp(from.quaternion, to.quaternion, fraction)
        return Transform3D.compose(from)
    }
    
    /// Shortcut for quaternion-based matrix rotation.
	static func rotation(quaternion: simd_quatf) -> Transform3D {
        return Transform3D(simd: float4x4(quaternion))
    }
    
    /// TODO: not exactly valid!
    fileprivate static func skew(xy: Float) -> Transform3D {
        var m = matrix_identity_float4x4
        if xy > 0.0 {
            m[0, 1] = xy
        }
        return Transform3D(simd: m)
    }
    
    /// TODO: not exactly valid!
    fileprivate static func skew(xz: Float) -> Transform3D {
        var m = matrix_identity_float4x4
        if xz > 0.0 {
            m[0, 2] = xz
        }
        return Transform3D(simd: m)
    }
    
    /// TODO: not exactly valid!
    fileprivate static func skew(yz: Float) -> Transform3D {
        var m = matrix_identity_float4x4
        if yz > 0.0 {
            m[1, 2] = yz
        }
        return Transform3D(simd: m)
    }
}


//
// MARK: - SIMD Utilities
//


@inline(__always) // since there's no `simd_linear_combination` for `float3`...
fileprivate func simd_linear_combination(_ __a: Float, _ __x: simd_float3, _ __b: Float, _ __y: simd_float3) -> simd_float3 {
    return simd_linear_combination(__a, float2x3(columns: (__x, __x)),
                                   __b, float2x3(columns: (__y, __y))).columns.0
}
