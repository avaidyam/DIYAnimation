
///
internal protocol RenderStackable {
    static var identity: Self { get }
    static func *(_ lhs: Self, _ rhs: Self) -> Self
}

///
internal struct RenderStack<Element: RenderStackable> {
    internal init() {}
    
    ///
    private var elements: [Element] = [.identity]
    
    ///
    internal mutating func push(_ other: Element, replace: Bool = false) {
        self.elements.append(replace ? other : self.current * other)
    }
    
    ///
    internal mutating func pop(_ other: Element) {
        _ = self.elements.popLast()
        assert(self.elements.count > 0, "No elements on the stack!")
    }
    
    ///
    internal var current: Element {
        assert(self.elements.count > 0, "No elements on the stack!")
        return self.elements.last!
    }
}

///
internal typealias TransformStack = RenderStack<Transform3D>

///
internal typealias AlphaStack = RenderStack<CGFloat>

extension Transform3D: RenderStackable {}
extension CGFloat: RenderStackable {
    internal static var identity: CGFloat { return 1.0 }
}
