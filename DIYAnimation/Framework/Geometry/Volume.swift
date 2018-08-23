
// TODO: Most of these functions aren't complete or may be incorrect.

///
public struct Volume: Codable, Hashable {
    
    ///
    public static let null = Volume(x: 0, y: 0, z: 0, w: 0, h: 0, d: 0)
    
    ///
    public var x: Double
    
    ///
    public var y: Double
    
    ///
    public var z: Double
    
    ///
    public var w: Double
    
    ///
    public var h: Double
    
    ///
    public var d: Double
    
    ///
    public var rect: CGRect {
        return CGRect(x: self.x, y: self.y, width: self.w, height: self.h)
    }
    
    ///
    public var bounds: Bounds {
        return Bounds(self.rect)
    }
    
    ///
    public init() {
        self.init(x: 0, y: 0, z: 0, w: 0, h: 0, d: 0)
    }
    
    ///
    public init(x: Double = 0.0, y: Double = 0.0, z: Double = 0.0,
                w: Double = 0.0, h: Double = 0.0, d: Double = 0.0)
    {
        self.x = x
        self.y = y
        self.z = z
        self.w = w
        self.h = h
        self.d = d
    }
    
    ///
    public mutating func translate(x: Double, y: Double, z: Double) {
        
    }
    
    ///
    public func translating(x: Double, y: Double, z: Double) -> Volume {
        return self
    }
    
    ///
    public mutating func union(_ volume: Volume) {
        
    }
    
    ///
    public func unioning(_ volume: Volume) -> Volume {
        return self
    }
    
    ///
    public mutating func transform(_ transform: Transform3D) {
        
    }
    
    ///
    public func transforming(_ transform: Transform3D) -> Volume {
        return self
    }
}
