
// TODO: flesh out KeyValueCodable
// TODO: custom KeyPath or Event object?
// TODO: create a cache of [AttributeListOwner.Type: DefaultValues]
// TODO: willSet and didSet not called!!! (and make sure Transaction locking works)

///
internal protocol AttributeListOwner: class {
    
    ///
    static func defaultValue(forKey: String) -> Any?
    
    ///
    func willSet(_ attributeSet: AttributeList, forKey: String, willChange: Bool)
    
    ///
    func didSet(_ attributeSet: AttributeList, forKey: String, didChange: Bool)
}

extension AttributeListOwner {
    static func defaultValue(forKey: String) -> Any? { return nil }
    func willSet(_ attributeSet: AttributeList, forKey: String, willChange: Bool) {}
    func didSet(_ attributeSet: AttributeList, forKey: String, didChange: Bool) {}
}

/*
@propertyWrapper
struct LayerProperty<T> {
	let owner: Weak<Layer>
	let keyPath: ReferenceWritableKeyPath<Layer, T>
    let `default`: T
	init(_ layer: inout Layer, _ keyPath: ReferenceWritableKeyPath<Layer, T>, default: T) {
		self.owner = Weak(layer)
		self.keyPath = keyPath
        self.default = `default`
    }
    var wrappedValue: T {
        get { return self.owner.value.values[self.keyPath] as? T ?? self.default }
        set { self.owner.value.values[self.keyPath] = value }
    }
}
class Test: Layer {
	@LayerProperty(&self, \.testing, default: "")
	var testing: String
}
*/

///
///
///
@dynamicMemberLookup
public final class AttributeList: CustomStringConvertible, CustomDebugStringConvertible, ExpressibleByDictionaryLiteral {
    
    public typealias Key = String
    public typealias Value = Any
    public typealias Element = Any
    
    ///
    public struct Disposition: OptionSet {
        public let rawValue: Int
        public init(rawValue: Int) {
            self.rawValue = rawValue
        }
        public init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///
        public static let initial = Disposition(1 << 0)
        
        ///
        public static let willSet = Disposition(1 << 1)
        
        ///
        public static let didSet = Disposition(1 << 2)
    }
    
    ///
    public typealias Handler<T> = (_ oldValue: T?, _ newValue: T?,
                                              _ type: Disposition) -> ()
    
    ///
    private class AnyObservation {
        private static var vendor = (0..<Int.max).makeIterator()
        fileprivate let id: Int = AnyObservation.vendor.next()!
    }
    
    ///
    private final class Observation<T>: AnyObservation {
        fileprivate let handler: Handler<T>
        fileprivate let release: (Observation<T>) -> ()
        fileprivate init(_ handler: @escaping Handler<T>,
                         _ release: @escaping (Observation<T>) -> ())
        {
            self.handler = handler
            self.release = release
        }
        deinit {
            self.release(self)
        }
    }
    
    ///
    private weak var owner: AttributeListOwner? = nil
    
    ///
    private var values: [String: Any] = [:]
    
    ///
    private var willSetters: [String: [Int: Weak<AnyObservation>]] = [:]
    
    ///
    private var didSetters: [String: [Int: Weak<AnyObservation>]] = [:]
    
    ///
    internal init(values: [String: Any] = [:], _ owner: AttributeListOwner? = nil) {
        self.values = values
        self.owner = owner
    }
    
    ///
    internal init(referencing other: AttributeList, _ owner: AttributeListOwner? = nil) {
        self.values = other.values
        self.owner = owner
    }
    
    ///
    internal init(copying other: AttributeList, requiring: [String] = [],
                  _ owner: AttributeListOwner? = nil)
    {
        self.values = other.values
        self.owner = owner
        
        // Deep copy the required keys from `other`'s `owner`:
        if let o = other.owner {
            for keyPath in requiring {
                if self.values[keyPath] == nil {
                    self.values[keyPath] = self.defaultValue(forKey: keyPath, from: o)
                }
            }
        }
    }
    
    public init(dictionaryLiteral elements: (String, Any)...) {
        self.values = Dictionary(elements) {
            return $1
        }
    }
    
    ///
    public subscript<T>(dynamicMember keyPath: String) -> T? {
        get { return self[keyPath] }
        set { self[keyPath] = newValue }
    }
    
    // TODO: make this work with key paths "x.y.z..."
    public subscript<T>(_ keyPath: String) -> T? {
        get {
            
            // If we have `nil` for the key, call `defaultValue(forKey:)`:
            if let value = self.values[keyPath] as! T? {
                return value
            }
            return self.defaultValue(forKey: keyPath)
        }
        set {
            
            // Accumulate current willSet and didSet handlers:
            var willSets = [Handler<T>]()
            for (_, o) in self.willSetters[keyPath] ?? [:] {
                guard let observation = o.value as? Observation<T> else { break }
                willSets.append(observation.handler)
            }
            var didSets = [Handler<T>]()
            for (_, o) in self.didSetters[keyPath] ?? [:] {
                guard let observation = o.value as? Observation<T> else { break }
                didSets.append(observation.handler)
            }
            let oldValue = self.values[keyPath] as? T
            
            // Perform operation:
            willSets.forEach {
                $0(oldValue, newValue, .willSet)
            }
            self.values[keyPath] = newValue
            didSets.forEach {
                $0(oldValue, newValue, .didSet)
            }
        }
    }
    
    ///
    public func observe<T>(keyPath: String, type: Disposition,
                             _ handler: @escaping Handler<T>) -> Any
    {
        assert(type.contains(.willSet) || type.contains(.didSet),
               "Observer must register for either willSet or didSet!")
        
        // Create observation that removes itself upon deinitialization:
        let obs = Observation(handler) { o in
            self.willSetters[keyPath]?[o.id] = nil
            self.didSetters[keyPath]?[o.id] = nil
        }
        
        // Store the observation in the right spot, weakly; call it if needed:
        if type.contains(.willSet) {
            self.willSetters[keyPath, default: [:]][obs.id] = Weak(obs)
        }
        if type.contains(.didSet) {
            self.didSetters[keyPath, default: [:]][obs.id] = Weak(obs)
        }
        if type.contains(.initial) {
            obs.handler(nil, self.values[keyPath] as! T?, .initial)
        }
        return obs
    }
    
    /// Trigger the observation handlers for `keyPath` with an arbitrary `value`.
    internal func trigger<T>(_ keyPath: String, _ value: T, _ type: Disposition) {
        if type.contains(.willSet) {
            for (_, o) in self.willSetters[keyPath] ?? [:] {
                guard let observation = o.value as? Observation<T> else { break }
                observation.handler(nil, value, .willSet)
            }
        }
        if type.contains(.didSet) {
            for (_, o) in self.didSetters[keyPath] ?? [:] {
                guard let observation = o.value as? Observation<T> else { break }
                observation.handler(nil, value, .didSet)
            }
        }
    }
    
    /// Thunk for grabbing a default value.
    private func defaultValue<T>(forKey keyPath: String,
                                 from owner: AttributeListOwner? = nil) -> T?
    {
        if let o = (owner ?? self.owner),
            let x = type(of: o).defaultValue(forKey: keyPath) as? T {
            return x
        } else if let x = T.self as? DefaultPropertyType.Type {
            return (x.identityValue() as! T)
        } else {
            return nil
        }
    }
    
    /// Returns the pretty-printed representation of the receiver.
    public var description: String {
        return self.values.description
    }
    
    /// Returns the standalone representation of the receiver.
    public var debugDescription: String {
        return "AttributeList{\(self.values.debugDescription)}"
    }
}

// FIXME: Apparently, compile order of files for the Swift compiler matters here.
//        See [SR-0631] @ https://bugs.swift.org/browse/SR-631
extension Render.Layer: AttributeListOwner {}
extension Layer: AttributeListOwner {}
extension Animation: AttributeListOwner {}





// TODO: compatibility with NSObject...
protocol KeyValueCodable {
    func value(forKey key: String) -> Any?
    func setValue(_ value: Any?, forKey key: String)
    
    func value(forKeyPath keyPath: String) -> Any?
    func setValue(_ value: Any?, forKeyPath keyPath: String)
    
    func value(forUndefinedKey key: String) -> Any?
    func setValue(_ value: Any?, forUndefinedKey key: String)
    
    func setNilValueForKey(_ key: String)
    func setValuesForKeys(_ keyedValues: [String : Any])
    func dictionaryWithValues(forKeys keys: [String]) -> [String : Any]
    
    func willChangeValue(forKey key: String)
    func didChangeValue(forKey key: String)
    
    // TODO: observe(...)/add/remove stuff
}
