import Foundation

///
public protocol Initializable {
    init()
}

///
public protocol DefaultPropertyType {
    
    /// The `identity` value of the receiver.
    static func identityValue() -> Self
}

public extension DefaultPropertyType where Self: Initializable {
	static func identityValue() -> Self {
        return self.init()
    }
}

//
// MARK: - Builtins
//

extension Bool: DefaultPropertyType, Initializable {}
extension Int: DefaultPropertyType, Initializable {}
extension UInt: DefaultPropertyType, Initializable {}
extension Int8: DefaultPropertyType, Initializable {}
extension UInt8: DefaultPropertyType, Initializable {}
extension Int16: DefaultPropertyType, Initializable {}
extension UInt16: DefaultPropertyType, Initializable {}
extension Int32: DefaultPropertyType, Initializable {}
extension UInt32: DefaultPropertyType, Initializable {}
extension Int64: DefaultPropertyType, Initializable {}
extension UInt64: DefaultPropertyType, Initializable {}
extension Float: DefaultPropertyType, Initializable {}
extension Double: DefaultPropertyType, Initializable {}
extension Float80: DefaultPropertyType, Initializable {}
extension CGFloat: DefaultPropertyType, Initializable {}
extension CGPoint: DefaultPropertyType, Initializable {}
extension CGSize: DefaultPropertyType, Initializable {}
extension CGVector: DefaultPropertyType, Initializable {}
extension CGRect: DefaultPropertyType, Initializable {}
extension Array: DefaultPropertyType, Initializable
        where Element: DefaultPropertyType & Initializable {}
extension Set: DefaultPropertyType, Initializable
        where Element: DefaultPropertyType & Initializable {}
extension Dictionary: DefaultPropertyType, Initializable
        where Value: DefaultPropertyType & Initializable {}
extension CGAffineTransform: DefaultPropertyType {
    public static func identityValue() -> CGAffineTransform {
        return self.identity
    }
}
extension CGColor: DefaultPropertyType {
    public static func identityValue() -> Self {
        return self.init(red: 0, green: 0, blue: 0, alpha: 0)
    }
}
extension ColorMatrix: DefaultPropertyType {
    public static func identityValue() -> ColorMatrix {
        return self.identity
    }
}
extension Transform3D: DefaultPropertyType {
    public static func identityValue() -> Transform3D {
        return self.identity
    }
}
