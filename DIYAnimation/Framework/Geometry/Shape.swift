
// TODO: Most of these functions aren't complete or may be incorrect.
// TODO: Turn most of the mutating methods into operators.

// Use CGRegion!!

/// A `Shape` describes a complex 2D shape composed of multiple rects.
public struct Shape: Sequence, Codable, Hashable, CustomStringConvertible {
    
    /// The `Iterator` type for a `Shape`.
    public typealias Iterator = IndexingIterator<[CGRect]>
    
    /// The `Shape` with no components.
    public static let empty = Shape()
    
    ///
    fileprivate struct Span: Codable {
        
        ///
        fileprivate let y: Int
        
        ///
        fileprivate let idx: Int
        
        ///
        fileprivate init(_ y: Int, _ idx: Int) {
            self.y = y
            self.idx = idx
        }
    }
    
    ///
    fileprivate struct Segment: Codable {
        
        ///
        fileprivate let x: Int
        
        ///
        fileprivate init(_ x: Int) {
            self.x = x
        }
    }
    
    ///
    private var spans: [Span] = []
    
    ///
    private var segments: [Segment] = []
    
    /// The `components` that compose the receiver.
    public /*private(set)*/ var components: [CGRect] = []
    
    /// Create a new `Shape` with the provided `rects`.
    public init(_ rects: [CGRect]) {
        self.components = rects
    }
    
    /// Create a new `Shape` with the provided `rects`.
    public init(_ rects: CGRect...) {
        self.components = rects
    }
    
    /// Create a roughly-equivalent `Shape` with the provided quadrangle points.
    public init(quadrangle p1: CGPoint, _ p2: CGPoint, _ p3: CGPoint, _ p4: CGPoint) {
        // FIXME
    }
    
    /// Offset the receiver by the given vector.
    public mutating func offset(by: CGVector) {
        
    }
    
    /// Inset the receiver by the given vector.
    public mutating func inset(by: CGVector) {
        
    }
    
    /// Intersect the receiver with the given rect.
    public mutating func intersect(with rect: CGRect) {
        self.intersect(with: Shape(rect))
    }
    
    /// Combine (union) the receiver with the given rect.
    public mutating func union(with rect: CGRect) {
        self.union(with: Shape(rect))
    }
    
    /// Intersect the receiver with the given region.
    public mutating func intersect(with: Shape) {
        
    }
    
    /// Combine (union) the receiver with the given region.
    public mutating func union(with: Shape) {
        
    }
    
    /// Diff (subtract) the receiver with the given region.
    public mutating func diff(with: Shape) {
        
    }
    
    /// XOR the receiver with the given region.
    public mutating func xor(with: Shape) {
        
    }
    
    /// Creates a simplified (i.e. fewer components) representation of the receiver.
    public mutating func simplify(_ exterior: Bool) {
        self.components.removeAll {
            $0.isEmpty || $0.isNull
        }
        
        // Remove all completely overlapped rects:
        for (i1, x) in self.components.enumerated() {
            for (i2, y) in self.components.enumerated() where i1 != i2 {
                if x.contains(y) {
                    self.components.remove(at: i2)
                } else if y.contains(x) {
                    self.components.remove(at: i1)
                }
            }
        }
    }
    
    /// Returns the bounding box that contains all the receiver's components.
    public var boundingBox: CGRect {
        var r = CGRect.zero
        for x in self.components {
            r = r.union(x)
        }
        return r
    }
    
    /// Returns whether the receiver has any components.
    public var isEmpty: Bool {
        return self.components.isEmpty
    }
    
    /// Returns whether the region is rectangular.
    public var isRectangular: Bool {
        return self.components.count == 1
    }
    
    /// Returns whether the receiver intersects the `rect`.
    public func intersects(_ rect: CGRect) -> Bool {
        return false
    }
    
    /// Returns whether the reciever intersects the `region`.
    public func intersects(_ region: Shape) -> Bool {
        return false
    }
    
    /// Returns whether the receiver contains the given point.
    public func contains(_ point: CGPoint) -> Bool {
        return false
    }
    
    /// Returns whether the receiver contains the given rect.
    public func contains(_ rect: CGRect) -> Bool {
        return false
    }
    
    /// Returns whether the receiver contains the given region.
    public func contains(_ region: Shape) -> Bool {
        return false
    }
    
    /// Provide access to the components of a `Shape` for indexed iteration.
    public func makeIterator() -> Shape.Iterator {
        // TODO: support left->right and top->bottom iteration order
        return self.components.lazy.makeIterator()
    }
    
    /// Hash the receiver.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.spans.count, self.segments.count)
    }
    
    /// Two `Shape`s are equal iff their components are equal.
    public static func ==(_ lhs: Shape, _ rhs: Shape) -> Bool {
        return lhs.components == rhs.components
    }
    
    /// The string-representation of the receiving `Shape`.
    public var description: String {
        let rects = self.components.map {
            "(\($0.minX), \($0.minY), \($0.width), \($0.height))"
        }
        return "Shape{count=\(rects.count);components=\(rects)}"
    }
}

internal extension CGRect {
    
    ///
	static let unit = CGRect(x: 0, y: 0, width: 1, height: 1)
    
    ///
	func constrain(_ other: CGRect) -> CGRect {
        return CGRect(x: max(self.origin.x, other.origin.x),
                      y: max(self.origin.y, other.origin.y),
                      width: min(self.size.width, other.size.width),
                      height: min(self.size.height, other.size.height))
    }
    
    ///
	func constrain(_ other: CGSize) -> CGRect {
        return self.constrain(CGRect(origin: .zero, size: other))
    }
}
