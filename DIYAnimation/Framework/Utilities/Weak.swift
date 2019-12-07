
/// Wraps a weak value element.
internal class Weak<Element: AnyObject>: Codable {
    internal weak var value: Element? = nil
    internal init(_ value: Element) {
        self.value = value
    }
    
    required init(from decoder: Decoder) throws {
        // TODO
    }
    
    func encode(to encoder: Encoder) throws {
        // TODO
    }
}

extension Weak: Equatable where Element: Equatable {
    static func ==(lhs: Weak<Element>, rhs: Weak<Element>) -> Bool {
        return lhs.value == rhs.value
    }
}

extension Weak: Hashable where Element: Hashable {
	func hash(into hasher: inout Hasher) {
		hasher.combine(self.value)
	}
}

internal extension Hasher {
    
    /// Feed `values` to this hasher, mixing their essential parts into
    /// the hasher state.
    @inline(__always)
	mutating func combine<A: Hashable, B: Hashable>(_ a: A, _ b: B) {
        self.combine(a)
        self.combine(b)
    }
    
    /// Feed `values` to this hasher, mixing their essential parts into
    /// the hasher state.
    @inline(__always)
	mutating func combine<A: Hashable, B: Hashable, C: Hashable>(_ a: A, _ b: B, _ c: C) {
        self.combine(a)
        self.combine(b)
        self.combine(c)
    }
    
    /// Feed `values` to this hasher, mixing their essential parts into
    /// the hasher state.
    @inline(__always)
	mutating func combine<A: Hashable, B: Hashable, C: Hashable, D: Hashable>(_ a: A, _ b: B, _ c: C, _ d: D) {
        self.combine(a)
        self.combine(b)
        self.combine(c)
        self.combine(d)
    }
    
    /// Feed `values` to this hasher, mixing their essential parts into
    /// the hasher state.
    @inline(__always)
	mutating func combine<A: Hashable, B: Hashable, C: Hashable, D: Hashable, E: Hashable>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E) {
        self.combine(a)
        self.combine(b)
        self.combine(c)
        self.combine(d)
        self.combine(e)
    }
    
    /// Feed `values` to this hasher, mixing their essential parts into
    /// the hasher state.
    @inline(__always)
	mutating func combine<A: Hashable, B: Hashable, C: Hashable, D: Hashable, E: Hashable, F: Hashable>(_ a: A, _ b: B, _ c: C, _ d: D, _ e: E, _ f: F) {
        self.combine(a)
        self.combine(b)
        self.combine(c)
        self.combine(d)
        self.combine(e)
        self.combine(f)
    }
}

///
/// Swift 4.3+ Shims:
///

extension Comparable {
    @inline(__always)
    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }
}
extension Strideable where Stride: BinaryInteger {
    @inline(__always)
    func clamped(to range: Range<Self>) -> Self {
        return clamped(to: range.lowerBound...range.upperBound
                .advanced(by: range.lowerBound == range.upperBound ? 0 : -1))
    }
}

internal extension Array {
	subscript(_ idx: Index, default defaultValue: @autoclosure () -> Element) -> Element {
        guard (self.startIndex..<self.endIndex).contains(idx) else {
            return defaultValue()
        }
        return self[idx]
    }
}
