import simd

enum SIMDCodingKeys: CodingKey {
    case values
}

extension float2: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SIMDCodingKeys.self)
        self.init(try container.decode([Float].self, forKey: .values))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SIMDCodingKeys.self)
        try container.encode(self.map { $0 }, forKey: .values)
    }
}

extension float3: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SIMDCodingKeys.self)
        self.init(try container.decode([Float].self, forKey: .values))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SIMDCodingKeys.self)
        try container.encode(self.map { $0 }, forKey: .values)
    }
}

extension float4: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SIMDCodingKeys.self)
        self.init(try container.decode([Float].self, forKey: .values))
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SIMDCodingKeys.self)
        try container.encode(self.map { $0 }, forKey: .values)
    }
}

extension float4x4: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SIMDCodingKeys.self)
        let values = try container.decode([[Float]].self, forKey: .values)
        self.init(values.map { float4($0) })
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SIMDCodingKeys.self)
        let values = [self.columns.0, self.columns.1, self.columns.2, self.columns.3]
        try container.encode(values.map { $0.map { $0 } }, forKey: .values)
    }
}

internal extension CGPoint {
    @inline(__always)
    internal init(_ value: float2) {
        self.init(x: CGFloat(value.x), y: CGFloat(value.y))
    }
}
internal extension CGSize {
    @inline(__always)
    internal init(_ value: float2) {
        self.init(width: CGFloat(value.x), height: CGFloat(value.y))
    }
}
internal extension CGRect {
    @inline(__always)
    internal init(_ value: float4) {
        self.init(x: CGFloat(value.x), y: CGFloat(value.y),
                  width: CGFloat(value.z), height: CGFloat(value.w))
    }
}
internal extension float2 {
    @inline(__always)
    internal init(_ value: CGPoint) {
        self.init(Float(value.x), Float(value.y))
    }
    @inline(__always)
    internal init(_ value: CGSize) {
        self.init(Float(value.width), Float(value.height))
    }
}
internal extension float4 {
    @inline(__always)
    internal init(_ value: CGRect) {
        self.init(Float(value.minX), Float(value.minY),
                  Float(value.width), Float(value.height))
    }
    @inline(__always)
    internal init(_ value: CGColor) {
        self.init(value.rgba.map { Float($0) })
    }
}
