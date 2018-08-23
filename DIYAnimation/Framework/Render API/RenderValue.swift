import Foundation

// empty wrapper
internal struct Render {
    private init() {}
    
    ///
    internal static var notificationCenter = NotificationCenter()
}

///
internal protocol RenderValue: Codable, Hashable {}

///
internal protocol RenderConvertible {
    
    ///
    var renderValue: Any { get }
}

///
extension RenderValue where Self: AnyObject {
    internal static func ==(_ lhs: Self, _ rhs: Self) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
    internal var hashValue: Int {
        return ObjectIdentifier(self).hashValue
    }
}

//
// Builtins:
//

extension CGFloat: RenderValue {}
extension CGPoint: RenderValue {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(x, y)
    }
}
extension CGSize: RenderValue {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(width, height)
    }
}
extension CGVector: RenderValue {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(dx, dy)
    }
}
extension CGRect: RenderValue {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(origin, size)
    }
}

extension Float: RenderValue {}
extension Double: RenderValue {}
//extension Float80: RenderValue {}

extension Int: RenderValue {}
extension UInt: RenderValue {}
extension Int8: RenderValue {}
extension UInt8: RenderValue {}
extension Int16: RenderValue {}
extension UInt16: RenderValue {}
extension Int32: RenderValue {}
extension UInt32: RenderValue {}
extension Int64: RenderValue {}
extension UInt64: RenderValue {}

extension Bounds: RenderValue {}
extension Volume: RenderValue {}
extension Vector3D: RenderValue {}
extension Transform3D: RenderValue {}
extension ColorMatrix: RenderValue {}

extension MachPort: RenderValue {}

extension Array: RenderValue where Element: RenderValue {}
extension Set: RenderValue where Element: RenderValue {}
extension Dictionary: RenderValue where Key: RenderValue, Value: RenderValue {}



// convert color:
//  1. if alpha == 0: return 0,0,0,0
//  2. if color only: convert to RGB via colorspace
//  3. if pattern: create Pattern(imageObj)
//        - keep pattern cache!
//  OR somehow conform CGPattern to Codable?
//  CA somehow draws it through OGL...?


