import simd
import CoreGraphics

///
///
/// **Note:** Do not confuse this type with `CGVector`, a 2D type.
public struct Vector3D: Codable, CustomStringConvertible, Hashable {
    
    /// The underlying `SIMD` type.
    internal var v: SIMD4<Float>
    
    ///
    public init() {
        self.v = SIMD4<Float>()
    }
    
    ///
    public init(_ v1: Float = 0.0, _ v2: Float = 0.0,
                _ v3: Float = 0.0, _ v4: Float = 0.0) {
        self.v = SIMD4<Float>(v1, v2, v3, v4)
    }
    
    ///
    internal init(simd v: SIMD4<Float>) {
        self.v = v
    }
    
    ///
    public subscript(index: Int) -> Float {
        get { return self.v[index] }
        set { self.v[index] = newValue }
    }
    
    ///
    public static prefix func +(_ lhs: Vector3D) -> Vector3D {
        return lhs
    }
    
    ///
    public static prefix func -(_ lhs: Vector3D) -> Vector3D {
        return Vector3D(simd: -lhs.v)
    }
    
    ///
    public static func +(_ lhs: Vector3D, _ rhs: Float) -> Vector3D {
        return Vector3D(simd: SIMD4<Float>(lhs.v.x + rhs, lhs.v.y + rhs,
										   lhs.v.z + rhs, lhs.v.w + rhs))
    }
    
    ///
    public static func -(_ lhs: Vector3D, _ rhs: Float) -> Vector3D {
        return Vector3D(simd: SIMD4<Float>(lhs.v.x - rhs, lhs.v.y - rhs,
										   lhs.v.z - rhs, lhs.v.w - rhs))
    }
    
    ///
    public static func *(_ lhs: Vector3D, _ rhs: Float) -> Vector3D {
        return Vector3D(simd: lhs.v * rhs)
    }
    
    ///
    public static func /(_ lhs: Vector3D, _ rhs: Float) -> Vector3D {
        return Vector3D(simd: lhs.v / rhs)
    }
    
    ///
    public static func +(_ lhs: Vector3D, _ rhs: Vector3D) -> Vector3D {
        return Vector3D(simd: lhs.v + rhs.v)
    }
    
    ///
    public static func -(_ lhs: Vector3D, _ rhs: Vector3D) -> Vector3D {
        return Vector3D(simd: lhs.v - rhs.v)
    }
    
    ///
    public static func *(_ lhs: Vector3D, _ rhs: Vector3D) -> Vector3D {
        return Vector3D(simd: lhs.v * rhs.v)
    }
    
    ///
    public static func /(_ lhs: Vector3D, _ rhs: Vector3D) -> Vector3D {
        return Vector3D(simd: lhs.v / rhs.v)
    }
    
    ///
    public static func +=(_ lhs: inout Vector3D, _ rhs: Float) {
        lhs.v = SIMD4<Float>(lhs.v.x + rhs, lhs.v.y + rhs,
							 lhs.v.z + rhs, lhs.v.w + rhs)
    }
    
    ///
    public static func -=(_ lhs: inout Vector3D, _ rhs: Float) {
        lhs.v = SIMD4<Float>(lhs.v.x - rhs, lhs.v.y - rhs,
							 lhs.v.z - rhs, lhs.v.w - rhs)
    }
    
    ///
    public static func *=(_ lhs: inout Vector3D, _ rhs: Float) {
        lhs.v *= rhs
    }
    
    ///
    public static func /=(_ lhs: inout Vector3D, _ rhs: Float) {
        lhs.v /= rhs
    }
    
    ///
    public static func +=(_ lhs: inout Vector3D, _ rhs: Vector3D) {
        lhs.v += rhs.v
    }
    
    ///
    public static func -=(_ lhs: inout Vector3D, _ rhs: Vector3D) {
        lhs.v -= rhs.v
    }
    
    ///
    public static func *=(_ lhs: inout Vector3D, _ rhs: Vector3D) {
        lhs.v *= rhs.v
    }
    
    ///
    public static func /=(_ lhs: inout Vector3D, _ rhs: Vector3D) {
        lhs.v /= rhs.v
    }
    
    ///
    public static func ==(_ lhs: Vector3D, _ rhs: Vector3D) -> Bool {
        return lhs.v == rhs.v
    }
    
    ///
    public var description: String {
        return "Transform3D(\(self.values))"
    }
    
    ///
	public func hash(into hasher: inout Hasher) {
		hasher.combine(self.values)
	}
}

/// Compatibility for CoreAnimation.
public extension Vector3D {
    
    ///
	var x: CGFloat {
        get { return CGFloat(self[0]) }
        set { self[0] = Float(newValue) }
    }
    
    ///
	var y: CGFloat {
        get { return CGFloat(self[1]) }
        set { self[1] = Float(newValue) }
    }
    
    ///
	var z: CGFloat {
        get { return CGFloat(self[2]) }
        set { self[2] = Float(newValue) }
    }
    
    ///
	var w: CGFloat {
        get { return CGFloat(self[3]) }
        set { self[3] = Float(newValue) }
    }
    
    ///
	var values: [Float] {
		return [self.v].flatMap { [$0.x, $0.y, $0.z, $0.w] }
    }
    
    ///
	var xy: CGPoint {
        get { return CGPoint(x: CGFloat(self[0]), y: CGFloat(self[1])) }
        set {
            self[0] = Float(newValue.x)
            self[1] = Float(newValue.y)
        }
    }
    
    ///
	var zw: CGSize {
        get { return CGSize(width: CGFloat(self[2]), height: CGFloat(self[3])) }
        set {
            self[2] = Float(newValue.width)
            self[3] = Float(newValue.height)
        }
    }
    
    ///
	init(_ p: CGPoint, z: CGFloat = 0.0) {
        self.v = SIMD4<Float>()
        self.xy = p
        self.z = z
        self.w = 1
    }
    
    ///
	init(_ r: CGRect) {
        self.v = SIMD4<Float>()
        self.xy = r.origin
        self.zw = r.size
    }
}
