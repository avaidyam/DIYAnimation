import simd

enum SIMDCodingKeys: CodingKey {
    case values
}

extension SIMD4 where Scalar == Float {
    public func map<T>(transform: (Float) -> T) -> Array<T> {
        return [x, y, z, w].map(transform)
    }
}

extension float4x4: Codable {
    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: SIMDCodingKeys.self)
        let values = try container.decode([[Float]].self, forKey: .values)
        self.init(values.map { SIMD4<Float>($0) })
    }
    public func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: SIMDCodingKeys.self)
        let values = [self.columns.0, self.columns.1, self.columns.2, self.columns.3]
		try container.encode(values.map { [$0].compactMap { [$0.x, $0.y, $0.z, $0.w] } }, forKey: .values)
    }
}

internal extension CGPoint {
    @inline(__always)
	init(_ value: SIMD2<Float>) {
        self.init(x: CGFloat(value.x), y: CGFloat(value.y))
    }
}
internal extension CGSize {
    @inline(__always)
	init(_ value: SIMD2<Float>) {
        self.init(width: CGFloat(value.x), height: CGFloat(value.y))
    }
}
internal extension CGRect {
    @inline(__always)
	init(_ value: SIMD4<Float>) {
        self.init(x: CGFloat(value.x), y: CGFloat(value.y),
                  width: CGFloat(value.z), height: CGFloat(value.w))
    }
}
internal extension SIMD2 where Scalar == Float {
    @inline(__always)
	init(_ value: CGPoint) {
        self.init(Float(value.x), Float(value.y))
    }
    @inline(__always)
	init(_ value: CGSize) {
        self.init(Float(value.width), Float(value.height))
    }
}
internal extension SIMD4 where Scalar == Float {
    @inline(__always)
	init(_ value: CGRect) {
        self.init(Float(value.minX), Float(value.minY),
                  Float(value.width), Float(value.height))
    }
    @inline(__always)
	init(_ value: CGColor) {
        self.init(value.rgba.map { Float($0) })
    }
}
