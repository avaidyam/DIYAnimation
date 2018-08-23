
// TODO: Most of these functions aren't complete or may be incorrect.

///
public struct Bounds: Codable, Hashable {
    
    ///
    public static let zero = Bounds(x: 0, y: 0, w: 0, h: 0)
    
    ///
    public static let infinity = Bounds(x: .min, y: .min, w: .max, h: .max)
    
    ///
    public var x: Int
    
    ///
    public var y: Int
    
    ///
    public var w: Int
    
    ///
    public var h: Int
    
    ///
    public var rect: CGRect {
        return CGRect(x: self.x, y: self.y, width: self.w, height: self.h)
    }
    
    ///
    public init() {
        self.init(x: 0, y: 0, w: 0, h: 0)
    }
    
    ///
    public init(x: Int = 0, y: Int = 0, w: Int = 0, h: Int = 0) {
        self.x = x
        self.y = y
        self.w = w
        self.h = h
    }
    
    public init(_ rect: CGRect) {
        self.x = Int(rect.origin.x.rounded())
        self.y = Int(rect.origin.y.rounded())
        self.w = Int(rect.size.width.rounded())
        self.h = Int(rect.size.height.rounded())
    }
    
    ///
    public func contains(_ bounds: Bounds) -> Bool {
        return false
    }
    
    ///
    public func contains(x: Int, y: Int) -> Bool {
        return false
    }
    
    ///
    public mutating func inset(x: Int, y: Int) {
        
    }
    
    ///
    public mutating func intersect(_ bounds: Bounds) {
        
    }
    
    ///
    public mutating func union(_ bounds: Bounds) {
        
    }
    
    ///
    public func insetting(x: Int, y: Int) -> Bounds {
        return self
    }
    
    ///
    public func intersecting(_ bounds: Bounds) -> Bounds {
        return self
    }
    
    ///
    public func unioning(_ bounds: Bounds) -> Bounds {
        return self
    }
    
    ///
    public mutating func setInterior(_ rect: CGRect) {
        // TODO
    }
}
