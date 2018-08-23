import Foundation

/// An interface that allows objects to respond to actions triggered by a
/// `Layer` change.
///
/// When queried with an action identifier (a key path, external action name, or
/// predefined action identifier) a layer returns the appropriate action (which
/// must implement the `Action` protocol) and calls its `run(for:on:with:)`.
public protocol Action {
    
    /// Called to trigger the action specified by the identifier `event`.
    func run(forKey event: String, on layer: Layer, with args: [String: Any]?)
}

///
public struct CustomAction: Action {
    
    ///
    private var action: (String, Layer, [String: Any]?) -> ()
    
    ///
    public init(_ action: @escaping (String, Layer, [String: Any]?) -> ()) {
        self.action = action
    }
    
    ///
    public func run(forKey event: String, on layer: Layer, with args: [String: Any]?) {
        self.action(event, layer, args)
    }
}

extension NSNull: Action {
    
    /// The "NSNull" action has a special meaning: the action will be ignored.
    ///
    /// In comparison, a `nil` action implies that the provider of the action
    /// does not explicitly handle this action, and so other providers may be
    /// queried to provide an action for the `key`.
    public func run(forKey: String, on: Layer, with: [String: Any]?) {}
}
