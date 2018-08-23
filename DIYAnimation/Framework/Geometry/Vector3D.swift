import simd
import CoreGraphics

///
///
/// **Note:** Do not confuse this type with `CGVector`, a 2D type.
public struct Vector3D: Codable, CustomStringConvertible, Hashable {
    
    /// The underlying `SIMD` type.
    internal var v: float4
    
    ///
    public init() {
        self.v = float4()
    }
    
    ///
    public init(_ v1: Float = 0.0, _ v2: Float = 0.0,
                _ v3: Float = 0.0, _ v4: Float = 0.0) {
        self.v = float4(v1, v2, v3, v4)
    }
    
    ///
    internal init(simd v: float4) {
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
        return Vector3D(simd: float4(lhs.v.x + rhs, lhs.v.y + rhs,
                                     lhs.v.z + rhs, lhs.v.w + rhs))
    }
    
    ///
    public static func -(_ lhs: Vector3D, _ rhs: Float) -> Vector3D {
        return Vector3D(simd: float4(lhs.v.x - rhs, lhs.v.y - rhs,
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
        lhs.v = float4(lhs.v.x + rhs, lhs.v.y + rhs,
                       lhs.v.z + rhs, lhs.v.w + rhs)
    }
    
    ///
    public static func -=(_ lhs: inout Vector3D, _ rhs: Float) {
        lhs.v = float4(lhs.v.x - rhs, lhs.v.y - rhs,
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
    public var hashValue: Int {
        return self.values.hashValue
    }
}

/// Compatibility for CoreAnimation.
public extension Vector3D {
    
    ///
    public var x: CGFloat {
        get { return CGFloat(self[0]) }
        set { self[0] = Float(newValue) }
    }
    
    ///
    public var y: CGFloat {
        get { return CGFloat(self[1]) }
        set { self[1] = Float(newValue) }
    }
    
    ///
    public var z: CGFloat {
        get { return CGFloat(self[2]) }
        set { self[2] = Float(newValue) }
    }
    
    ///
    public var w: CGFloat {
        get { return CGFloat(self[3]) }
        set { self[3] = Float(newValue) }
    }
    
    ///
    public var values: [Float] {
        return self.v.map { $0 }
    }
    
    ///
    public var xy: CGPoint {
        get { return CGPoint(x: CGFloat(self[0]), y: CGFloat(self[1])) }
        set {
            self[0] = Float(newValue.x)
            self[1] = Float(newValue.y)
        }
    }
    
    ///
    public var zw: CGSize {
        get { return CGSize(width: CGFloat(self[2]), height: CGFloat(self[3])) }
        set {
            self[2] = Float(newValue.width)
            self[3] = Float(newValue.height)
        }
    }
    
    ///
    public init(_ p: CGPoint, z: CGFloat = 0.0) {
        self.v = float4()
        self.xy = p
        self.z = z
        self.w = 1
    }
    
    ///
    public init(_ r: CGRect) {
        self.v = float4()
        self.xy = r.origin
        self.zw = r.size
    }
}
