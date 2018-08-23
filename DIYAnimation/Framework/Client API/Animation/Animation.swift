import Foundation

// TODO: need mapAnimationTime (at begining of Basic, Keyframe)
// Animation.getFlags, setFlags -> used to check delegate called or commit levels

///
public protocol AnimationDelegate: class {
    
    ///
    func animationDidStart(_ anim: Animation)
    
    ///
    func animationDidStop(_ anim: Animation, _ finished: Bool)
}

///
public class Animation: MediaTiming, Action, CustomStringConvertible {
    
    ///
    public enum FillMode: Int, Codable {
        
        ///
        case forwards
        
        ///
        case backwards
        
        ///
        case both
        
        ///
        case removed
    }
    
    ///
    public private(set) lazy var values = AttributeList(values: [:], self)
    
    ///
    public weak var delegate: AnimationDelegate? = nil
    
    ///
    public var beginTime: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var duration: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var speed: TimeInterval { 
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var timeOffset: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var repeatCount: Int {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var repeatDuration: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var autoreverses: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var fillMode: FillMode {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var timingFunction: TimingFunction {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var removedOnCompletion: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var isEnabled: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    ///
    /// **Note:** A value of `0` causes dynamic interval calculation.
    public var frameInterval: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Default values of an `Animation`'s keyPaths.
    public class func defaultValue(forKey keyPath: String) -> Any? {
        switch keyPath {
        case "speed": return 1.0 as TimeInterval
        case "fillMode": return FillMode.removed
        case "timingFunction": return TimingFunction.default
        case "removedOnCompletion": return true
        case "isEnabled": return true
        default: return nil
        }
    }
    
    /// Apply the receiver to the provided `Layer`.
    internal func apply(to layer: Layer, at time: TimeInterval) {
        // no-op
    }
    
    public var description: String {
        return "\(type(of: self)){\(self.values)}"
    }
    
    /// If no `key` is provided to store the receiver in a `Layer`, this value
    /// is used instead, as a fallback.
    internal var fallbackIdentifier: String {
        return "\(type(of: self)).\(ObjectIdentifier(self).hashValue)"
    }
    
    func willSet(_ attributeSet: AttributeList, forKey: String, willChange: Bool) {
        // no-op
    }
    
    func didSet(_ attributeSet: AttributeList, forKey: String, didChange: Bool) {
        // no-op
    }
}

///
public class PropertyAnimation: Animation {
    
    ///
    public var keyPath: String? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var additive: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var cumulative: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public init(keyPath: String? = nil) {
        super.init()
        self.keyPath = keyPath
    }
    
    /// Apply the receiver to the provided `Layer`.
    internal override func apply(to layer: Layer, at time: TimeInterval) {
        // no-op
    }
}

public class BasicAnimation: PropertyAnimation {
    
    ///
    public var fromValue: Any? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var byValue: Any? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var toValue: Any? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var valueFunction: ValueFunction? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// Apply the receiver to the provided `Layer`.
    internal override func apply(to layer: Layer, at time: TimeInterval) {
        let value = Float((0.1 * time).truncatingRemainder(dividingBy: 1.0))
        
        // value = value via solved timingfunction!!
        // consider mediatiming mapped time
        
        switch (self.fromValue as? Animatable,
                self.byValue as? Animatable,
                self.toValue as? Animatable)
        {
        
        // From + To:
        case (.some(let from), .none, .some(let to)):
            layer.values[self.keyPath!] = mix(from: from, to: to, value)
        
        // From: By:
        case (.some(let from), .some(let by), .none):
            layer.values[self.keyPath!] = mix(from: from, by: by, value)
        
        // By + To:
        case (.none, .some(let by), .some(let to)):
            layer.values[self.keyPath!] = mix(by: by, to: to, value)
        
        default: break // need at least two values!
        }
    }
}

///
public class KeyframeAnimation: PropertyAnimation {
    
    ///
    public enum CalculationMode {
        
        ///
        case linear
        
        ///
        case discrete
        
        ///
        case paced
        
        ///
        case cubic
        
        ///
        case cubicPaced
    }
    
    ///
    public enum RotationMode {
        
        ///
        case auto
        
        ///
        case autoreverse
    }
    
    ///
    public var keyframeValues: [Any]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var path: CGPath? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var keyTimes: [Double]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var timingFunctions: [TimingFunction]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var tensionValues: [Double]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var continuityValues: [Double]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var biasValues: [Double]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var calculationMode: CalculationMode {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var rotationMode: RotationMode? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// Default values of an `Animation`'s keyPaths.
    public class override func defaultValue(forKey keyPath: String) -> Any? {
        if keyPath == "calculationMode" {
            return CalculationMode.linear
        }
        return super.defaultValue(forKey: keyPath)
    }
    
    /// Apply the receiver to the provided `Layer`.
    internal override func apply(to layer: Layer, at time: TimeInterval) {
        // no-op
    }
}

///
public class GroupAnimation: Animation {
    
    ///
    public var animations: [Animation]? {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    // TODO: Apparently Animation.defaultDuration exists too?
    
    ///
    public var defaultDuration: TimeInterval {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Apply the receiver to the provided `Layer`.
    internal override func apply(to layer: Layer, at time: TimeInterval) {
        self.animations?.forEach { $0.apply(to: layer, at: time) }
    }
}

extension Animation {
    
    /// Adds the receiver as an animation on the `layer`.
    public func run(forKey event: String, on layer: Layer, with args: [String : Any]?) {
        layer.addAnimation(self, forKey: event)
    }
}
