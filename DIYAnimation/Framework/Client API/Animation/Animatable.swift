import Foundation

///
public protocol Animatable {
    
    ///
    @inline(__always)
    static func add(_ lhs: Animatable, _ rhs: Animatable) -> Self
    
    ///
    @inline(__always)
    static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Self
    
    ///
    @inline(__always)
    static func multiply(_ lhs: Animatable, _ rhs: Float) -> Self
}

///
@inline(__always)
public func mix(from: Animatable, to: Animatable, _ fraction: Float) -> Animatable {
    let x = type(of: from)
    return x.add(x.multiply(from, 1.0 - fraction), x.multiply(to, fraction))
}

///
@inline(__always)
public func mix(from: Animatable, by: Animatable, _ fraction: Float) -> Animatable {
    let x = type(of: from)
    return x.add(from, x.multiply(by, fraction))
}

///
@inline(__always)
public func mix(by: Animatable, to: Animatable, _ fraction: Float) -> Animatable {
    let x = type(of: to)
    return x.subtract(to, x.multiply(by, fraction))
}

//
// MARK: - Builtins
//

extension Bool: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Bool {
        let lhs = lhs as! Bool, rhs = rhs as! Bool
        return lhs || rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Bool {
        let lhs = lhs as! Bool, rhs = rhs as! Bool
        return lhs && rhs
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Bool {
        let lhs = lhs as! Bool
        return ((lhs ? 1.0 : 0.0) * rhs) > 0.0
    }
}
extension Animatable where Self: BinaryInteger {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! Self, rhs = rhs as! Self
        return lhs + rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! Self, rhs = rhs as! Self
        return lhs - rhs
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Self {
        let lhs = lhs as! Self
        return Self(Float(lhs) * rhs)
    }
}
extension Int: Animatable {}
extension UInt: Animatable {}
extension Int8: Animatable {}
extension UInt8: Animatable {}
extension Int16: Animatable {}
extension UInt16: Animatable {}
extension Int32: Animatable {}
extension UInt32: Animatable {}
extension Int64: Animatable {}
extension UInt64: Animatable {}
extension Animatable where Self: FloatingPoint {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! Self, rhs = rhs as! Self
        return lhs + rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! Self, rhs = rhs as! Self
        return lhs - rhs
    }
}
extension Float: Animatable {
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Float {
        let lhs = lhs as! Float
        return lhs * rhs
    }
}
extension Double: Animatable {
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Double {
        let lhs = lhs as! Double
        return lhs * Double(rhs)
    }
}
extension Float80: Animatable {
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Float80 {
        let lhs = lhs as! Float80
        return lhs * Float80(rhs)
    }
}
extension CGFloat: Animatable {
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGFloat {
        let lhs = lhs as! CGFloat
        return lhs * CGFloat(rhs)
    }
}
extension CGPoint: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> CGPoint {
        let lhs = lhs as! CGPoint, rhs = rhs as! CGPoint
        return CGPoint(x: lhs.x + rhs.x, y: lhs.y + rhs.y)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> CGPoint {
        let lhs = lhs as! CGPoint, rhs = rhs as! CGPoint
        return CGPoint(x: lhs.x - rhs.x, y: lhs.y - rhs.y)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGPoint {
        let lhs = lhs as! CGPoint
        return CGPoint(x: lhs.x * CGFloat(rhs), y: lhs.y * CGFloat(rhs))
    }
}
extension CGSize: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> CGSize {
        let lhs = lhs as! CGSize, rhs = rhs as! CGSize
        return CGSize(width: lhs.width + rhs.width, height: lhs.height + rhs.height)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> CGSize {
        let lhs = lhs as! CGSize, rhs = rhs as! CGSize
        return CGSize(width: lhs.width - rhs.width, height: lhs.height - rhs.height)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGSize {
        let lhs = lhs as! CGSize
        return CGSize(width: lhs.width * CGFloat(rhs), height: lhs.height * CGFloat(rhs))
    }
}
extension CGVector: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> CGVector {
        let lhs = lhs as! CGVector, rhs = rhs as! CGVector
        return CGVector(dx: lhs.dx + rhs.dx, dy: lhs.dy + rhs.dy)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> CGVector {
        let lhs = lhs as! CGVector, rhs = rhs as! CGVector
        return CGVector(dx: lhs.dx - rhs.dx, dy: lhs.dy - rhs.dy)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGVector {
        let lhs = lhs as! CGVector
        return CGVector(dx: lhs.dx * CGFloat(rhs), dy: lhs.dy * CGFloat(rhs))
    }
}
extension CGRect: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> CGRect {
        let lhs = lhs as! CGRect, rhs = rhs as! CGRect
        return CGRect(origin: CGPoint.add(lhs.origin, rhs.origin),
                      size: CGSize.add(lhs.size, rhs.size))
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> CGRect {
        let lhs = lhs as! CGRect, rhs = rhs as! CGRect
        return CGRect(origin: CGPoint.subtract(lhs.origin, rhs.origin),
                      size: CGSize.subtract(lhs.size, rhs.size))
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGRect {
        let lhs = lhs as! CGRect
        return CGRect(origin: CGPoint.multiply(lhs.origin, rhs),
                      size: CGSize.multiply(lhs.size, rhs))
    }
}
extension CGColor: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! CGColor, rhs = rhs as! CGColor
        return self.init(colorSpace: CGColor._space,
                         components: zip(lhs.rgba, rhs.rgba).map { $0 + $1 })!
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Self {
        let lhs = lhs as! CGColor, rhs = rhs as! CGColor
        return self.init(colorSpace: CGColor._space,
                         components: zip(lhs.rgba, rhs.rgba).map { $0 - $1 })!
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Self {
        let lhs = lhs as! CGColor
        return self.init(colorSpace: CGColor._space,
                         components: lhs.rgba.map { $0 * CGFloat(rhs) })!
    }
}
extension Bounds: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Bounds {
        let lhs = lhs as! Bounds, rhs = rhs as! Bounds
        return Bounds(x: lhs.x + rhs.x, y: lhs.y + rhs.y,
                      w: lhs.w + rhs.w, h: lhs.h + rhs.h)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Bounds {
        let lhs = lhs as! Bounds, rhs = rhs as! Bounds
        return Bounds(x: lhs.x - rhs.x, y: lhs.y - rhs.y,
                      w: lhs.w - rhs.w, h: lhs.h - rhs.h)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Bounds {
        let lhs = lhs as! Bounds
        return Bounds(x: Int(Float(lhs.x) * rhs), y: Int(Float(lhs.y) * rhs),
                      w: Int(Float(lhs.w) * rhs), h: Int(Float(lhs.h) * rhs))
    }
}
extension Volume: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Volume {
        let lhs = lhs as! Volume, rhs = rhs as! Volume
        return Volume(x: lhs.x + rhs.x, y: lhs.y + rhs.y,
                      z: lhs.z + rhs.z, w: lhs.w + rhs.w,
                      h: lhs.h + rhs.h, d: lhs.d + rhs.d)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Volume {
        let lhs = lhs as! Volume, rhs = rhs as! Volume
        return Volume(x: lhs.x - rhs.x, y: lhs.y - rhs.y,
                      z: lhs.z - rhs.z, w: lhs.w - rhs.w,
                      h: lhs.h - rhs.h, d: lhs.d - rhs.d)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Volume {
        let lhs = lhs as! Volume
        return Volume(x: lhs.x * Double(rhs), y: lhs.y * Double(rhs),
                      z: lhs.z * Double(rhs), w: lhs.w * Double(rhs),
                      h: lhs.h * Double(rhs), d: lhs.d * Double(rhs))
    }
}
extension Vector3D: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Vector3D {
        let lhs = lhs as! Vector3D, rhs = rhs as! Vector3D
        return lhs + rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Vector3D {
        let lhs = lhs as! Vector3D, rhs = rhs as! Vector3D
        return lhs - rhs
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Vector3D {
        let lhs = lhs as! Vector3D
        return lhs * rhs
    }
}
extension CGAffineTransform: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> CGAffineTransform {
        let lhs = lhs as! CGAffineTransform, rhs = rhs as! CGAffineTransform
        return CGAffineTransform( a: lhs.a + rhs.a,    b: lhs.b + rhs.b,
                                  c: lhs.c + rhs.c,    d: lhs.d + rhs.d,
                                 tx: lhs.tx + rhs.tx, ty: lhs.ty + rhs.ty)
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> CGAffineTransform {
        let lhs = lhs as! CGAffineTransform, rhs = rhs as! CGAffineTransform
        return CGAffineTransform( a: lhs.a - rhs.a,    b: lhs.b - rhs.b,
                                  c: lhs.c - rhs.c,    d: lhs.d - rhs.d,
                                  tx: lhs.tx - rhs.tx, ty: lhs.ty - rhs.ty)
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> CGAffineTransform {
        let lhs = lhs as! CGAffineTransform
        return CGAffineTransform( a: lhs.a * CGFloat(rhs),    b: lhs.b * CGFloat(rhs),
                                  c: lhs.c * CGFloat(rhs),    d: lhs.d * CGFloat(rhs),
                                  tx: lhs.tx * CGFloat(rhs), ty: lhs.ty * CGFloat(rhs))
    }
}
extension Transform3D: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Transform3D {
        let lhs = lhs as! Transform3D, rhs = rhs as! Transform3D
        return lhs + rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Transform3D {
        let lhs = lhs as! Transform3D, rhs = rhs as! Transform3D
        return lhs - rhs
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Transform3D {
        let lhs = lhs as! Transform3D
        return lhs * rhs
    }
}
extension ColorMatrix: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> ColorMatrix {
        let lhs = lhs as! ColorMatrix, rhs = rhs as! ColorMatrix
        return lhs + rhs
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> ColorMatrix {
        let lhs = lhs as! ColorMatrix, rhs = rhs as! ColorMatrix
        return lhs - rhs
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> ColorMatrix {
        let lhs = lhs as! ColorMatrix
        return lhs * rhs
    }
}
extension Array: Animatable where Element: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Array<Element> {
        let lhs = lhs as! Array, rhs = rhs as! Array
        return zip(lhs, rhs).map { Element.add($0, $1) }
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Array<Element> {
        let lhs = lhs as! Array, rhs = rhs as! Array
        return zip(lhs, rhs).map { Element.subtract($0, $1) }
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Array<Element> {
        let lhs = lhs as! Array
        return lhs.map { Element.multiply($0, rhs) }
    }
}
extension Set: Animatable where Element: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Set<Element> {
        let lhs = lhs as! Set, rhs = rhs as! Set
        return Set(zip(lhs, rhs).map { Element.add($0, $1) })
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Set<Element> {
        let lhs = lhs as! Set, rhs = rhs as! Set
        return Set(zip(lhs, rhs).map { Element.subtract($0, $1) })
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Set<Element> {
        let lhs = lhs as! Set
        return Set(lhs.map { Element.multiply($0, rhs) })
    }
}
extension Dictionary: Animatable where Value: Animatable {
    @inline(__always)
    public static func add(_ lhs: Animatable, _ rhs: Animatable) -> Dictionary<Key, Value> {
        let lhs = lhs as! Dictionary, rhs = rhs as! Dictionary
        return lhs.merging(rhs) { Value.add($0, $1) }
    }
    @inline(__always)
    public static func subtract(_ lhs: Animatable, _ rhs: Animatable) -> Dictionary<Key, Value> {
        let lhs = lhs as! Dictionary, rhs = rhs as! Dictionary
        return lhs.merging(rhs) { Value.subtract($0, $1) }
    }
    @inline(__always)
    public static func multiply(_ lhs: Animatable, _ rhs: Float) -> Dictionary<Key, Value> {
        let lhs = lhs as! Dictionary
        return lhs.mapValues { Value.multiply($0, rhs) }
    }
}
/*
extension CGPath: Animatable, Initializable {
    public static func +(lhs: CGMutablePath, rhs: CGMutablePath) -> Self {
        return self.init()
    }
    public static func -(lhs: CGMutablePath, rhs: CGMutablePath) -> Self {
        return self.init()
    }
    public static func *(lhs: CGMutablePath, rhs: Float) -> Self {
        return self.init()
    }
}
extension CGMutablePath: Animatable, Initializable {
    public static func +(lhs: CGMutablePath, rhs: CGMutablePath) -> Self {
        return self.init()
    }
    public static func -(lhs: CGMutablePath, rhs: CGMutablePath) -> Self {
        return self.init()
    }
    public static func *(lhs: CGMutablePath, rhs: Float) -> Self {
        return self.init()
    }
}
#if canImport(AppKit)
import AppKit
extension NSBezierPath: Animatable, Initializable {
    public static func +(lhs: NSBezierPath, rhs: NSBezierPath) -> Self {
        return self.init()
    }
    public static func -(lhs: NSBezierPath, rhs: NSBezierPath) -> Self {
        return self.init()
    }
    public static func *(lhs: NSBezierPath, rhs: Float) -> Self {
        return self.init()
    }
}
#endif
*/
