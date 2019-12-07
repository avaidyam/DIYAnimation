import Foundation
import CoreImage.CIFilter

//
// TODO: read-only (presentation), c-o-w mode (applying anims!)
// TODO: dynamic member lookup
//

/// Methods your app can implement to respond to layer-related events.
/// You can implement the methods of this protocol to provide the layer’s
/// content, handle the layout of sublayers, and provide custom animation
/// actions to perform. The object that implements this protocol must be
/// assigned to the delegate property of the layer object.
public protocol LayerDelegate: class {
    
    /// Notifies the delegate of an imminent draw.
    ///
    /// The `layerWillDraw(_:)` method is called before `draw(_:in:)`. You
    /// can use this method to configure any layer state affecting contents
    /// prior to `draw(_:in:)` such as `contentsFormat` and `isOpaque`.
    ///
    /// This method is not called if the delegate implements `display(_:)`.
    func layerWillDraw(_ layer: Layer)
    
    /// Tells the delegate to implement the display process using the layer's
    /// CGContext.
    ///
    /// The `draw(_:in:)` method is called when the layer is marked for its
    /// content to be reloaded, typically with the `setNeedsDisplay()` method.
    /// It is not called if the delegate implements the `display(_:)` method.
    /// You can use the context to draw vectors, such as curves and lines, or
    /// images with the `draw(_:in:byTiling:)` method.
    ///
    /// This method is not called if the delegate implements `display(_:)`.
    func draw(_ layer: Layer, in ctx: CGContext)
    
    /// Tells the delegate a layer's bounds have changed.
    ///
    /// This method is called when a layer's bounds have changed, for example
    /// by changing its frame's size. You can implement this method if you need
    /// precise control over the layout of your layer's sublayers.
    func layoutSublayers(of layer: Layer)
    
    /// Returns the default action of the `action(forKey:)` method, if any.
    ///
    /// A layer's delegate that implements this method returns an action for a
    /// specified key and stops any further searches (i.e. actions for the same
    /// key in the layer's actions dictionary or specified by
    /// `defaultAction(forKey:)` are not returned).
    func action(for layer: Layer, forKey: String) -> Action? /*Action?*/
}

public protocol LayerDisplayDelegate: LayerDelegate {
    
    /// Tells the delegate to implement the display process.
    ///
    /// The `display(_:)` delegate method is invoked when the layer is marked
    /// for its content to be reloaded, typically initiated by the
    /// `setNeedsDisplay()` method. The typical technique for updating is to set
    /// the layer's `contents` property.
    func display(_ layer: Layer)
}

extension LayerDelegate {
    func layerWillDraw(_ layer: Layer) {}
    func draw(_ layer: Layer, in ctx: CGContext) {}
    func layoutSublayers(of layer: Layer) {}
    func action(for layer: Layer, forKey: String) -> Action? { return nil }
}

/// An object that manages image-based content and allows you to perform
/// animations on that content.
///
/// Layers are often used to provide the backing store for views but can also
/// be used without a view to display content. A layer’s main job is to manage
/// the visual content that you provide but the layer itself has visual attributes
/// that can be set, such as a background color, border, and shadow. In addition
/// to managing visual content, the layer also maintains information about the
/// geometry of its content (such as its position, size, and transform) that is
/// used to present that content onscreen. Modifying the properties of the layer
/// is how you initiate animations on the layer’s content or geometry. A layer
/// object encapsulates the duration and pacing of a layer and its animations
/// by adopting the `MediaTiming` protocol, which defines the layer’s timing
/// information.
///
/// If the layer object was created by a view, the view typically assigns itself
/// as the layer’s delegate automatically, and you should not change that
/// relationship. For layers you create yourself, you can assign a delegate
/// object and use that object to provide the contents of the layer dynamically
/// and perform other tasks.
public class Layer: Hashable, MediaTiming {
    
    /// The `Layer.State` object holds all layer flag and subtree information that
    /// is separate from its `values` `AttributeList`. These are specially modified
    /// and should not be dynamically available to clients except `Render.Layer`.
    internal struct State: Hashable {
        
    }
    
    /// The identifier that represents the action taken when a layer draws to
    /// its managed backing store.
    public static let onDrawKey: String = "onDraw"
    
    /// The identifier that represents the action taken when on layer layout.
    public static let onLayoutKey: String = "onLayout"
    
    /// The identifier that represents the action taken when a layer becomes
    /// visible, either as a result being inserted into the visible layer
    /// hierarchy or the layer is no longer set as hidden.
    public static let onOrderInKey: String = "onOrderIn"
    
    /// The identifier that represents the action taken when the layer is
    /// removed from the layer hierarchy or is hidden.
    public static let onOrderOutKey: String = "onOrderOut"
    
    /// The identifier that represents a transition animation.
    public static let transitionKey: String = "transition"
    
    // TODO: use the `let fake: Void = ()` method for ^
    
    ///
    public enum ContentsFilter: Int, Codable {
        
        /// Linear interpolation filter.
        case linear
        
        /// Nearest neighbor interpolation filter.
        case nearest
        
        /// Trilinear minification filter. Enables mipmap generation.
        case trilinear
    }
    
    ///
    public enum ContentsFormat: Int, Codable {
        
        ///
        case RGBA8Uint
        
        ///
        case RGBA16Float
        
        ///
        case gray8Uint
    }
    
    /// The contents gravity constants specify the position of the content object
    /// when the layer bounds is larger than the bounds of the content object.
    public enum ContentsGravity: Int, Codable {
        
        /// The content is horizontally centered at the bottom-edge of the
        /// bounds rectangle.
        case bottom
        
        /// The content is positioned in the bottom-left corner of the bounds
        /// rectangle.
        case bottomLeft
        
        /// The content is positioned in the bottom-right corner of the bounds
        /// rectangle.
        case bottomRight
        
        /// The content is horizontally and vertically centered in the bounds
        /// rectangle.
        case center
        
        /// The content is vertically centered at the left-edge of the bounds
        /// rectangle.
        case left
        
        /// The content is resized to fit the entire bounds rectangle.
        case resize
        
        /// The content is resized to fit the bounds rectangle, preserving the
        /// aspect of the content. If the content does not completely fill the
        /// bounds rectangle, the content is centered in the partial axis.
        case resizeAspect
        
        /// The content is resized to completely fill the bounds rectangle,
        /// while still preserving the aspect of the content. The content is
        /// centered in the axis it exceeds.
        case resizeAspectFill
        
        /// The content is vertically centered at the right-edge of the bounds
        /// rectangle.
        case right
        
        /// The content is horizontally centered at the top-edge of the bounds
        /// rectangle.
        case top
        
        /// The content is positioned in the top-left corner of the bounds
        /// rectangle.
        case topLeft
        
        /// The content is positioned in the top-right corner of the bounds
        /// rectangle.
        case topRight
    }
    
    //
    //
    //
    
    ///
    private let layerId = UUID()
    
    ///
    public private(set) lazy var values = AttributeList(values: [:], self)
    
    /// The name of the receiver. The layer name is used by your application to
    /// identify a layer.
    public var name: String? = nil
    
    /// The layer’s delegate object.
    /// You can use a delegate object to provide the layer’s contents, handle
    /// the layout of any sublayers, and provide custom actions in response to
    /// layer-related changes. The object you assign to this property should
    /// implement one or more of the methods of the `LayerDelegate` protocol.
    public weak var delegate: LayerDelegate? = nil
    
    public var beginTime: TimeInterval = 0.0
    public var duration: TimeInterval = 0.0
    public var speed: TimeInterval = 1.0
    public var timeOffset: TimeInterval = 0.0
    public var repeatCount: Int = 0
    public var repeatDuration: TimeInterval = 0.0
    public var autoreverses: Bool = false
    public var fillMode: Animation.FillMode = .removed
    
    /// The layer’s position in its superlayer’s coordinate space. Animatable.
    ///
    /// The value of this property is specified in points and is always
    /// specified relative to the value in the anchorPoint property. For new
    /// standalone layers, the default position is set to (0.0, 0.0). Changing
    /// the frame property also updates the value in this property.
    public var position: CGPoint {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The layer’s position on the z axis. Animatable.
    ///
    /// The default value of this property is 0. Changing the value of this
    /// property changes the the front-to-back ordering of layers onscreen.
    /// Higher values place this layer visually closer to the viewer than
    /// layers with lower values. This can affect the visibility of layers whose
    /// frame rectangles overlap.
    ///
    /// The value of this property is measured in points. The range of this
    /// property is single-precision, floating-point `-.greatestFiniteMagnitude`
    /// to `.greatestFiniteMagnitude`.
    public var zPosition: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Defines the anchor point of the layer's bounds rectangle. Animatable.
    ///
    /// You specify the value for this property using the unit coordinate space.
    /// The value of this property represents the center of the layer’s bounds
    /// rectangle. All geometric manipulations to the view occur about the
    /// specified point. For example, applying a rotation transform to a layer
    /// with the default anchor point causes the layer to rotate around its center.
    /// Changing the anchor point to a different location would cause the layer
    /// to rotate around that new point.
    public var anchorPoint: CGPoint {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The anchor point for the layer’s position along the z axis. Animatable.
    ///
    /// This property specifies the anchor point on the z axis around which
    /// geometric manipulations occur. The point is expressed as a distance
    /// (measured in points) along the z axis.
    public var anchorPointZ: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The layer’s bounds rectangle. Animatable.
    ///
    /// The bounds rectangle is the origin and size of the layer in its own
    /// coordinate space. When you create a new standalone layer, the default
    /// value for this property is an empty rectangle, which you must change
    /// before using the layer. The values of each coordinate in the rectangle
    /// are measured in points.
    public var bounds: CGRect {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The layer’s frame rectangle.
    ///
    /// The frame rectangle is position and size of the layer specified in the
    /// superlayer’s coordinate space. For layers, the frame rectangle is a
    /// computed property that is derived from the values in the `bounds`,
    /// `anchorPoint` and `position` properties. When you assign a new value
    /// to this property, the layer changes its `position` and `bounds` properties
    /// to match the rectangle you specified. The values of each coordinate in
    /// the rectangle are measured in points.
    ///
    /// **Warning:** Do not set the frame if the transform property applies a
    /// rotation transform that is not a multiple of 90 degrees.
    ///
    /// **Note:** The frame property is not directly animatable. Instead you
    /// should animate the appropriate combination of the `bounds`, `anchorPoint`
    /// and `position` properties to achieve the desired result.
    public var frame: CGRect { // composite of position + bounds.size
        get { return CGRect(origin: self.position, size: self.bounds.size) }
        set { self.position = newValue.origin; self.bounds.size = newValue.size }
    }
    
    ///
    internal var frameTransform: CGAffineTransform {
        // TODO
        return .identity
    }
    
    /// The background color of the receiver. Animatable.
    public var backgroundColor: CGColor {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// An object that provides the contents of the layer. Animatable.
    ///
    /// If you are using the layer to display a static image, you can set this
    /// property to the `CGImage` or `NSImage` containing the image you want to
    /// display. Assigning a value to this property causes the layer to use your
    /// image rather than create a separate backing store.
    ///
    /// If the layer object is tied to a view object, you should avoid setting
    /// the contents of this property directly. The interplay between views and
    /// layers usually results in the view replacing the contents of this
    /// property during a subsequent update.
    public var contents: Drawable? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// The filter used when reducing the size of the content.
    public var minificationFilter: ContentsFilter = .linear
    
    /// The filter used when increasing the size of the content.
    public var magnificationFilter: ContentsFilter = .linear
    
    /// The bias factor used by the minification filter when it is set to
    /// `.trilinear` to determine the levels of detail.
    public var minificationFilterBias: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// A hint for the desired storage format of the layer contents.
    public var contentsFormat: ContentsFormat = .RGBA8Uint
    
    /// The rectangle that defines how the layer contents are scaled if the
    /// layer’s contents are resized. Animatable.
    ///
    /// You can use this property to subdivide the layer’s content into a 3x3
    /// grid. The value in this property specifies the location and size of the
    /// center rectangle in that grid. If the layer’s `contentsGravity` property
    /// is set to one of the resizing modes, resizing the layer causes scaling
    /// to occur differently in each rectangle of the grid. The center rectangle
    /// is stretched in both dimensions, the top-center and bottom-center
    /// rectangles are stretched only horizontally, the left-center and
    /// right-center rectangles are stretched only vertically, and the four
    /// corner rectangles are not stretched at all. Therefore, you can use this
    /// technique to implement stretchable backgrounds or images using a
    /// three-part or nine-part image.
    ///
    /// The value in this property is set to the unit rectangle (0.0,0.0) (1.0,1.0)
    /// by default, which causes the entire image to scale in both dimensions.
    /// If you specify a rectangle that extends outside the unit rectangle, the
    /// result is undefined. The rectangle you specify is applied only after the
    /// contentsRect property has been applied to the image.
    ///
    /// If the width or height of the rectangle in this property is very small
    /// or 0, the value is implicitly changed to the width or height of a single
    /// source pixel centered at the specified location.
    public var contentsCenter: CGRect {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The rectangle, in the unit coordinate space, that defines the portion of
    /// the layer’s contents that should be used. Animatable.
    ///
    /// Defaults to the unit rectangle (0.0, 0.0, 1.0, 1.0).
    ///
    /// If pixels outside the unit rectangle are requested, the edge pixels of
    /// the contents image will be extended outwards.
    ///
    /// If an empty rectangle is provided, the results are undefined.
    public var contentsRect: CGRect {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// A constant that specifies how the layer's contents are positioned or
    /// scaled within its bounds.
    ///
    /// The naming of contents gravity constants is based on the direction of
    /// the vertical axis. If you are using gravity constants with a vertical
    /// component, e.g. `.top`, you should also check the layer's
    /// `contentsAreFlipped`. When this is `true`, `.top` aligns contents to the
    /// bottom of the layer and `.bottom` aligns content to the top of the layer.
    public var contentsGravity: ContentsGravity {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The width of the layer’s border. Animatable.
    ///
    /// When this value is greater than 0.0, the layer draws a border using the
    /// current `borderColor` value. The border is drawn inset from the
    /// receiver’s bounds by the value specified in this property. It is
    /// composited above the receiver’s contents and sublayers and includes the
    /// effects of the cornerRadius property.
    public var borderWidth: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The color of the layer’s border. Animatable.
    public var borderColor: CGColor {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The radius to use when drawing rounded corners for the layer’s
    /// background. Animatable.
    ///
    /// Setting the radius to a value greater than `0.0` causes the layer to
    /// begin drawing rounded corners on its background. By default, the corner
    /// radius does not apply to the image in the layer’s contents property;
    /// it applies only to the background color and border of the layer.
    /// However, setting the masksToBounds property to `true` causes the content
    /// to be clipped to the rounded corners.
    public var cornerRadius: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var shadowColor: CGColor {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var shadowOpacity: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var shadowOffset: CGSize {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var shadowRadius: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// An array of Core Image filters to apply to the content immediately
    /// behind the layer. Animatable.
    ///
    /// Background filters affect the content behind the layer that shows
    /// through into the layer itself. Typically this content belongs to the
    /// superlayer that acts as the parent of the layer. These filters do not
    /// affect the content of the layer itself, including the layer’s background
    /// color and border.
    ///
    /// Changing the inputs of the `CIFilter` object directly after it is attached
    /// to the layer causes undefined behavior. It is possible to modify filter
    /// parameters after attaching them to the layer but you must use the
    /// layer’s `setValue(_:forKeyPath:)` method to do so. In addition, you must
    /// assign a name to the filter so that you can identify it in the array.
    public var backgroundFilters: [FilterType]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// A Core Image filter used to composite the layer and the content behind
    /// it. Animatable.
    ///
    /// The default value of this property is `nil`, which causes the layer to
    /// use source-over compositing. Although you can use any Core Image filter
    /// as a layer's compositing filter, for best results, use those in the
    /// `CICategoryCompositeOperation` category.
    ///
    /// Changing the inputs of the `CIFilter` object directly after it is attached
    /// to the layer causes undefined behavior. It is possible to modify filter
    /// parameters after attaching them to the layer but you must use the
    /// layer’s `setValue(_:forKeyPath:)` method to do so. In addition, you must
    /// assign a name to the filter so that you can identify it in the array.
    public var compositingFilter: FilterType? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// An array of Core Image filters to apply to the contents of the layer
    /// and its sublayers. Animatable.
    ///
    /// The filters you add to this property affect the content of the layer,
    /// including its border, filled background and sublayers.
    ///
    /// Changing the inputs of the `CIFilter` object directly after it is attached
    /// to the layer causes undefined behavior. It is possible to modify filter
    /// parameters after attaching them to the layer but you must use the
    /// layer’s `setValue(_:forKeyPath:)` method to do so. In addition, you must
    /// assign a name to the filter so that you can identify it in the array.
    public var filters: [FilterType]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var masksToBounds: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var mask: Layer? = nil {
        willSet {
            assert(newValue?.superlayer == nil, "Mask may not have a superlayer!")
        }
        didSet {
            oldValue?._isMask = false
            self.mask?._isMask = true
        }
    }
    
    ///
    public var transform: Transform3D? {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var sublayerTransform: Transform3D? {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var affineTransform: CGAffineTransform? {
        get { return self.transform?.affineTransform }
        set { self.transform = newValue.flatMap { Transform3D(affine: $0) } }
    }
    
    ///
    public private(set) weak var superlayer: Layer? = nil
    
    ///
    public private(set) var sublayers: [Layer] = []
    
    ///
    public var isDoubleSided: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// A Boolean value indicating whether the layer contains completely opaque
    /// content.
    ///
    /// If your app draws completely opaque content that fills the layer’s
    /// bounds, setting this property to `true` allows optimizing the rendering
    /// behavior for the layer. Specifically, when the layer creates the backing
    /// store for your drawing commands, the backing store's alpha channel is
    /// omitted. Doing so can improve the performance of compositing operations.
    /// If you set the value of this property to `true`, you must fill the
    /// layer’s bounds with opaque content.
    ///
    /// Setting this property affects only the managed backing store. If you
    /// assign an image with an alpha channel to the layer’s contents property,
    /// that image retains its alpha channel regardless of the value of this
    /// property.
    public var isOpaque: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var isHidden: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var opacity: Float {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    ///
    private var animations: [String: Animation] = [:]
    
    /// An optional dictionary used to store property values that aren't
    /// explicitly defined by the layer.
    ///
    /// This dictionary may in turn have a style key, forming a hierarchy of
    /// default values. In the case of hierarchical style dictionaries the
    /// shallowest value for a property is used. For example, the value for
    /// “style.someValue” takes precedence over “style.style.someValue”.
    ///
    /// If the style dictionary does not define a value for an attribute, the
    /// receiver’s `defaultValue(forKey:)` method is called. The default value
    /// of this property is `nil`. The style dictionary is not consulted for
    /// `bounds` or `frame`.
    ///
    /// **Warning:** If the style dictionary or any of its ancestors are
    /// modified, the values of the layer's properties are undefined until the
    /// style property is reset.
    public var style: [String: Any]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    ///
    public var actions: [String: Action]? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    //
    // MARK: - Context
    //
    
    ///
    public var context: Context? = nil {
        willSet {
            guard self.context != newValue else { return }
            assert(self.superlayer == nil,
                   "This layer has a superlayer, and thus cannot be assigned a context!")
            
            // Mark ourselves against a locked `Transaction` with the proper state:
            Transaction.ensure()
            Transaction.lock()
        }
        didSet {
            guard self.context != oldValue else { return }
            
            // We are now becoming visible in our context:
            if self.context != nil && oldValue == nil {
                Transaction.ensure().add(.addRoot(self))
                self.mark(contextChanged: oldValue)
                
            // We are relinquishing visibility in our context:
            } else if self.context == nil && oldValue != nil {
                self.mark(visible: false)
            }
            Transaction.unlock()
        }
    }
    
    ///
    internal func mark(contextChanged oldContext: Context?) {
        self.markAll()
        self.mark()
    }
    
    ///
    internal func markAll() {
        
    }
    
    ///
    internal func mark() {
        self.setNeedsCommit()
        Transaction.ensure().add(.addRoot(self))
    }
    
    //
    // MARK: - Initializers
    //
    
    ///
    public required init() {
        // no-op
    }
    
    ///
    public required init(layer: Layer) {
        self.origin = layer
        self.isReadOnly = true
        self.values = AttributeList(referencing: layer.values, self)
    }
    
    ///
    private var isReadOnly: Bool = false
    
    ///
    private weak var origin: Layer? = nil
    
    //
    // MARK: - Ancestor & Sublayer Conversion
    //
    
    ///
    internal func ancestorShared(with: Layer) -> Layer? {
        return nil
    }
    
    ///
    public func convert(_ point: CGPoint, to: Layer?) -> CGPoint {
        return point
    }
    
    ///
    public func convert(_ point: CGPoint, from: Layer?) -> CGPoint {
        return point
    }
    
    ///
    public func convert(_ rect: CGRect, to: Layer?) -> CGRect {
        return rect
    }
    
    ///
    public func convert(_ rect: CGRect, from: Layer?) -> CGRect {
        return rect
    }
    
    ///
    public func convert(_ time: TimeInterval, to: Layer?) -> TimeInterval {
        return time
    }
    
    ///
    public func convert(_ time: TimeInterval, from: Layer?) -> TimeInterval {
        return time
    }
    
    ///
    internal func mapGeometry(_ other: Layer) {
        
    }
    
    ///
    internal func mapTiming(_ other: Layer) {
        
    }
    
    //
    // MARK: - Sublayer Ordering
    //
    
    ///
    internal var _isMask: Bool = false
    
    public func removeFromSuperlayer() {
        self.ensureModel()
        guard self.superlayer != nil else { return }
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            
            if let idx = self.superlayer?.sublayers.firstIndex(of: self) {
                self.superlayer!.sublayers.remove(at: idx)
            }
            self.superlayer = nil
            
            self.endChange("sublayers", a1)
        }
    }
    
    public func addSublayer(_ layer: Layer) {
        self.ensureModel()
        layer.ensureModel()
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            let a2 = layer.beginChange("sublayers")
            
            self.sublayers.append(layer)
            if let idx = layer.superlayer?.sublayers.firstIndex(of: layer) {
                layer.superlayer!.sublayers.remove(at: idx)
            }
            layer.superlayer = self
            
            layer.endChange("sublayers", a2)
            self.endChange("sublayers", a1)
        }
    }
    
    public func insertSublayer(_ layer: Layer, at idx: Int) {
        self.ensureModel()
        layer.ensureModel()
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            let a2 = layer.beginChange("sublayers")
            
            self.sublayers.insert(layer, at: idx)
            if let idx = layer.superlayer?.sublayers.firstIndex(of: layer) {
                layer.superlayer!.sublayers.remove(at: idx)
            }
            layer.superlayer = self
            
            layer.endChange("sublayers", a2)
            self.endChange("sublayers", a1)
        }
    }
    
    public func insertSublayer(_ layer: Layer, below sibling: Layer?) {
        self.ensureModel()
        layer.ensureModel()
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            let a2 = layer.beginChange("sublayers")
            
			if let sibling = sibling, let idx = self.sublayers.firstIndex(of: sibling) {
                self.sublayers.insert(layer, at: idx)
            } else {
                self.sublayers.insert(layer, at: 0)
            }
            if let idx = layer.superlayer?.sublayers.firstIndex(of: layer) {
                layer.superlayer!.sublayers.remove(at: idx)
            }
            layer.superlayer = self
            
            layer.endChange("sublayers", a2)
            self.endChange("sublayers", a1)
        }
    }
    
    public func insertSublayer(_ layer: Layer, above sibling: Layer?) {
        self.ensureModel()
        layer.ensureModel()
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            let a2 = layer.beginChange("sublayers")
            
			if let sibling = sibling, let idx = self.sublayers.firstIndex(of: sibling) {
                self.sublayers.insert(layer, at: idx + 1)
            } else {
                self.sublayers.append(layer)
            }
            if let idx = layer.superlayer?.sublayers.firstIndex(of: layer) {
                layer.superlayer!.sublayers.remove(at: idx)
            }
            layer.superlayer = self
            
            layer.endChange("sublayers", a2)
            self.endChange("sublayers", a1)
        }
    }
    
    public func replaceSublayer(_ layer1: Layer, with layer2: Layer) {
        self.ensureModel()
        layer1.ensureModel()
        layer2.ensureModel()
        Transaction.ensure()
        
        Transaction.whileLocked {
            let a1 = self.beginChange("sublayers")
            let a2 = layer1.beginChange("sublayers")
            let a3 = layer2.beginChange("sublayers")
            
			guard let idx = self.sublayers.firstIndex(of: layer1) else { return }
            self.sublayers[idx] = layer2
            if let idx = layer1.superlayer?.sublayers.firstIndex(of: layer1) {
                layer1.superlayer!.sublayers.remove(at: idx)
            }
            layer1.superlayer = nil
            if let idx = layer2.superlayer?.sublayers.firstIndex(of: layer2) {
                layer2.superlayer!.sublayers.remove(at: idx)
            }
            layer2.superlayer = self
            
            layer2.endChange("sublayers", a3)
            layer1.endChange("sublayers", a2)
            self.endChange("sublayers", a1)
        }
    }
    
    ///
    public func layerDidBecomeVisible(_ flag: Bool) {
        
    }
    
    ///
    public func layerDidChangeDisplay(_ display: Any?) {
        
    }
    
    ///
    internal func mark(visible: Bool) {
        Transaction.ensure()
        // ret if self.visible is same
        self.layerDidBecomeVisible(visible)
        self.perform { $0.mark(visible: visible) }
        
        // Run the `onOrder{In, Out}` action:
        if !Transaction.disableActions {
            let event = visible ? Layer.onOrderInKey : Layer.onOrderOutKey
            let action = self.action(forKey: event)
            action?.run(forKey: event, on: self, with: nil)
        }
    }
    
    /// Sort sublayers by `zPosition`, where matching `zPosition` defers to
    /// sorting by sublayer index; this flattens the rendered layer tree.
    internal func orderedSublayers() -> [Layer] {
        return self.sublayers.sorted { l, r in
			let l_idx = self.sublayers.firstIndex(of: l)!
			let r_idx = self.sublayers.firstIndex(of: l)!
            return (l.zPosition == r.zPosition) ? (l_idx > r_idx) : (l.zPosition > r.zPosition)
        }
    }
    
    /// Return recursive sublayer count, including the mask, and excluding the
    /// receiver.
    internal func sublayerCount() -> Int {
        let initial = self.sublayers.count + (self.mask != nil ? 1 : 0)
        return self.sublayers.map { $0.sublayerCount() }.reduce(initial, +)
    }
    
    ///
    internal func collectSubtree() -> [Weak<Layer>] {
        var layers: [Weak<Layer>] = []
        self.perform {
            layers.append(Weak($0))
        }
        return layers
    }
    
    /// Perform an action on the reciever and any sublayers.
    /// If `recursively` is `true`, this action is also performed on those sublayers.
    internal func perform(recursively: Bool = true, _ handler: (Layer) -> ()) {
        handler(self)
        guard recursively else { return }
        self.sublayers.forEach {
            $0.perform(recursively: recursively, handler)
        }
        self.mask?.perform(recursively: recursively, handler)
    }
    
    /// Find the first ancestor layer matching `criteria`, if any.
    /// If `strictly` is `false`, and the receiver matches `criteria`, it will
    /// be returned.
    internal func ancestor(strictly: Bool = false, with criteria: (Layer) -> (Bool)) -> Layer? {
        var child: Layer? = self
        while let parent = child?.superlayer {
            child = parent
            if criteria(parent) {
                return child
            }
        }
        return !strictly && criteria(self) ? self : nil
    }
    
    //
    // MARK: - Layer Actions
    //
    
    /// Specifies the default value associated with the specified key. Returns
    /// nil if no default value has been set.
    ///
    /// If you define custom properties for a layer but do not set a value, this
    /// method returns a suitable "zero" default value based on the expected
    /// value of the key. For example, if the value for key is a `CGSize` struct,
    /// the method returns (0.0, 0.0). For a `CGRect` an empty rectangle is returned.
    /// For `CGAffineTransform` and `Transform3D`, the appropriate identity matrix
    /// is returned.
    public class func defaultValue(forKey event: String) -> Any? {
        switch event {
        case "isDoubleSided": return true
        case "isOpaque": return true
        case "isHidden": return true
        case "opacity": return 1.0
        case "contentsCenter": return CGRect(x: 0, y: 0, width: 1, height: 1)
        case "contentsRect": return CGRect(x: 0, y: 0, width: 1, height: 1)
        case "contentsGravity": return ContentsGravity.resize
        case "anchorPoint": return CGPoint(x: 0.5, y: 0.5)
        default: return nil
        }
    }
    
    /// Returns a suitable action object for the given key or nil of no action
    /// object was associated with that key. Classes that want to provide default
    /// actions can override this method and use it to return those actions.
    public class func defaultAction(forKey event: String) -> Action? {
        return nil
    }
    
    /// Returns the object that provides the action for key. This method searches
    /// for the given action object of the layer. Actions define dynamic behaviors
    /// for a layer. For example, the animatable properties of a layer typically
    /// have corresponding action objects to initiate the actual animations. When
    /// that property changes, the layer looks for the action object associated
    /// with the property name and executes it. You can also associate custom
    /// action objects with your layer to implement app-specific actions.
    public func action(forKey event: String) -> Action? {
        Transaction.ensure()
        let x: Action? = Transaction.whileLocked {
            
            // 1. Check delegate for action:
            // 2. Check `actions` dictionary:
            // 3. Check `style` dictionary's `actions` dictionary:
            // 4. Check class default action:
            if let a = self.delegate?.action(for: self, forKey: event) {
                return a is NSNull ? nil : a
            } else if let a = self.actions?[event] {
                return a is NSNull ? nil : a
            } else if let s = self.style?["actions"] as? [String: Action], let a = s[event] {
                return a is NSNull ? nil : a
            } else if let a = type(of: self).defaultAction(forKey: event) {
                return a is NSNull ? nil : a
            }
            return nil
        }
        
        // If no defined action, and the `keyPath` is implicitly animated:
        // TODO: this actually doesn't happen here! only at layer caller site
        return x// ?? self.implicitAnimation(forKeyPath: event)
    }
    
    /// Creates an implicit animation suitable for the given `keyPath`, if possible.
    private func implicitAnimation(forKeyPath event: String) -> Animation? {
        let event = event.components(separatedBy: ".").first!
        
        let animation = BasicAnimation(keyPath: event)
        animation.fromValue = self.presentation()?.values[event]
        // TODO: use valueForUndefinedKey, etc. if needed
        
        return animation
    }
    
    //
    // MARK: - Layer Animations
    //
    
    ///
    public func addAnimation(_ anim: Animation, forKey key: String? = nil) {
        Transaction.ensure()
        Transaction.whileLocked {
            
            // if anim is a Transition, change key = "transition"
            //animation.timingFunction = Transaction.timingFunction
            //animation.duration = Transaction.duration
            // etc, fill in the blank values
            
            // TODO: At commit time:
            anim.beginTime = CurrentMediaTime()
            anim.duration = Transaction.animationDuration
            anim.timingFunction = Transaction.animationTimingFunction ?? .default
            
            self.animations[key ?? anim.fallbackIdentifier] = anim
            
            // mark self?
        }
    }
    
    ///
    public func removeAnimationForKey(_ key: String) {
        Transaction.ensure()
        Transaction.whileLocked {
            self.animations[key] = nil
        }
    }
    
    ///
    public func removeAllAnimations() {
        Transaction.ensure()
        Transaction.whileLocked {
            self.animations.removeAll()
        }
    }
    
    ///
    public var animationKeys: [String] {
        return self.animations.compactMap { $0.0 }
    }
    
    ///
    public func animationForKey(_ key: String) -> Animation? {
        Transaction.ensure()
        return Transaction.whileLocked {
            self.animations.filter { $0.0 == key }.first?.1
        }
    }
    
    /// Maps the receiver's animations onto the receiver at a provided reference time.
    internal func layer(at time: TimeInterval) -> Self {
        let clone = type(of: self).init(layer: self)
        self.animations.map { $0.1 }.forEach {
            $0.apply(to: clone, at: time)
        }
        return clone
    }
    
    ///
    internal func layerBeingDrawn() -> Self {
        guard self.animations.count > 0 else { return self }
        Transaction.ensure()
        
        // TODO: This is bad! Get a copy!
        return Transaction.whileLocked {
            self.layer(at: CurrentMediaTime())
        }
    }

    //
    // MARK: - Layer Display
    //
    
    ///
    public var needsDisplayOnBoundsChange: Bool = false
    
    
    ///
    public class func needsDisplay(forKey key: String) -> Bool {
        return false
    }
    
    ///
    private var _needsDisplay: Bool = true
    
    ///
    public func needsDisplay() -> Bool {
        return self._needsDisplay
    }
    
    ///
    public func setNeedsDisplay(_ rect: CGRect = .infinite) {
        self._needsDisplay = true
        Transaction.ensure()
        // ensure layer transaction
        Transaction.whileLocked {
            if let store = self.contents as? BackingStore {
                // TODO: flip the rectangle if self.contentsAreFlipped!
                store.invalidate(rect != .infinite ?
                    rect.constrain(self.bounds.size) :
                    rect)
            }
        }
    }
    
    ///
    public func displayIfNeeded() {
        if self._needsDisplay {
            self.display()
        }
    }
    
    /// Reloads the content of this layer.
    ///
    /// Do not call this method directly. The layer calls this method at
    /// appropriate times to update the layer’s content. If the layer has a
    /// delegate object, this method attempts to call the delegate’s `display(_:)`
    /// method, which the delegate can use to update the layer’s contents. If
    /// the delegate does not implement the `display(_:)` method, this method
    /// creates a backing store and calls the layer’s `draw(in:)` method to
    /// fill that backing store with content. The new backing store replaces the
    /// previous contents of the layer.
    ///
    /// Subclasses can override this method and use it to set the layer’s
    /// contents property directly. You might do this if your custom layer
    /// subclass handles layer updates differently.
    public func display() {
        if let d = self.delegate as? LayerDisplayDelegate {
            d.display(self)
        } else if (self.contents == nil || self.contents is BackingStore) &&
            (self.bounds.size.width > 0 && self.bounds.size.height > 0)
        {
            self.delegate?.layerWillDraw(self)
            self.contents = self.prepareContents()
        }
        
        // TODO: maybe not do this here??
        self._needsDisplay = false
    }
    
    /// To be implemented by subclasses whose contents are internally managed.
    internal func prepareContents() -> Drawable {
        Transaction.ensure()
        let store = Transaction.whileLocked {
            return self.contents as? BackingStore ?? BackingStore()
        }
        var opts: BackingStore.Flags = []
        opts.formIntersection(self.isOpaque ? .opaque : [])
        opts.formIntersection(self.minificationFilter == .trilinear ? .mipmap : [])
        store.update(size: self.bounds.size, opts) { ctx in
            self.prepare(context: ctx)
            self.layerBeingDrawn().draw(in: ctx)
        }
        return store
    }
    
    /// Applies the transformation matrix on the context for drawing the receiver.
    internal func prepare(context ctx: CGContext) {
        if self.contentsAreFlipped {
            ctx.translateBy(x: 0, y: CGFloat(self.bounds.height))
            ctx.scaleBy(x: 1, y: -1)
        }
        ctx.translateBy(x: self.bounds.minX, y: self.bounds.minY)
    }
    
    /// Draws the layer’s content using the specified graphics context.
    ///
    /// `context` is the graphics context in which to draw the content. The
    /// context may be clipped to protect valid layer content. Subclasses that
    /// wish to find the actual region to draw can call its `clipBoundingBox`.
    ///
    /// The default implementation of this method does not do any drawing itself.
    /// If the layer’s delegate implements the `draw(_:in:)` method, that method
    /// is called to do the actual drawing.
    ///
    /// Subclasses can override this method and use it to draw the layer’s
    /// content. When drawing, all coordinates should be specified in points in
    /// the logical coordinate space.
    public func draw(in context: CGContext) {
        // ensure a transaction?
        self.delegate?.draw(self, in: context)
        
        // Run the `onDraw` action:
        if !Transaction.disableActions {
            self.action(forKey: Layer.onDrawKey)?.run(forKey: Layer.onDrawKey,
                                                      on: self,
                                                      with: ["context": context])
        }
    }
    
    /// Invalidates the `contents` of the receiver.
    internal func invalidateContents() {
        Transaction.ensure()
        // ensure layer transaction
        Transaction.whileLocked {
            if let store = self.contents as? BackingStore {
                store.purge()
            } else {
                self.contents = nil
            }
        }
        // mark self
    }
    
    ///
    public var contentsAreFlipped: Bool {
        return self.isGeometryFlipped
    }
    
    ///
    public var isGeometryFlipped: Bool = false {
        didSet {
            self.perform { l in
                l.values.trigger("contentsAreFlipped", self.contentsAreFlipped,
                                 [.willSet])
                if /*self.layoutIsActive &&*/ self.needsLayoutOnGeometryChange { // TODO
                    self.setNeedsLayout()
                }
                l.values.trigger("contentsAreFlipped", self.contentsAreFlipped,
                                 [.didSet])
            }
        }
    }
    
    ///
    internal func colorSpaceDidChange(_ space: CGColorSpace) {
        if let store = self.contents as? BackingStore {
            store.colorSpace = space
            self.setNeedsDisplay()
        } /*else if let store = self.contents as? CGImage { // TODO
            // set contents changed here to redraw Render.Image
        }*/
    }

    //
    // MARK: - Layer Layout
    //
    
    ///
    public var needsLayoutOnGeometryChange: Bool = true
    
    ///
    internal var layoutIsActive: Bool = true
    
    ///
    internal var _needsLayout: Bool = true
    
    /// Recalculate the receiver’s layout, if required.
    ///
    /// When this message is received, the layer’s super layers are traversed
    /// until a ancestor layer is found that does not require layout. Then layout
    /// is performed on the entire layer-tree beneath that ancestor.
    public func layoutIfNeeded() {
        Transaction.ensure()
        Transaction.whileLocked {
            self.ancestor(strictly: false) { $0._needsLayout }?.perform {
                $0.layoutSublayers()
                $0._needsLayout = false
            }
        }
    }
    
    ///
    public func setNeedsLayout() {
        Transaction.ensure()
        // ensure layer transaction
        guard !self._needsLayout else { return }
        Transaction.whileLocked {
            self._needsLayout = true
        }
    }
    
    ///
    public func needsLayout() -> Bool {
        Transaction.ensure()
        return self._needsLayout
    }
    
    ///
    public func layoutSublayers() {
        self.delegate?.layoutSublayers(of: self)
        
        // Run the `onLayout` action:
        if !Transaction.disableActions {
            let action = self.action(forKey: Layer.onLayoutKey)
            action?.run(forKey: Layer.onLayoutKey, on: self, with: nil)
        }
    }
    
    //
    // MARK: - Layer Commit
    //
    
    // TODO: CALayer function variants of: layoutIfNeeded, displayIfNeeded
    
    ///
    internal func prepareCommit() {
        Transaction.ensure()
        Transaction.whileLocked {
            self.perform { _ in
                // if self.contents is CGImage or BackingStore:
                // - set the current colorspace from the context
                // - prepare mipmap if needed
            }
        }
    }
    
    ///
    private var _needsCommit: Bool = false
    
    ///
    internal func needsCommit() -> Bool {
        return self._needsCommit
    }
    
    ///
    internal func setNeedsCommit() {
        self._needsCommit = true
    }
    
    ///
    internal func commitIfNeeded() {
        
    }
    
    ///
    internal func commitAnimations() {
        
    }
    
    ///
    internal func collectAnimations() {
        
    }
    
    ///
    internal var nextAnimationTime: TimeInterval = .infinity
    
    //
    // MARK: - Layer KVO Changes
    //
    
    // todo: for all prop changes, ensure transaction, perform while locked:
    
    ///
    public func willSet(_ attributeSet: AttributeList, forKey keyPath: String, willChange: Bool) {
        Transaction.ensure()
        Transaction.lock()
        if willChange {
            let action = self.beginChange(keyPath)
            Transaction.values.currentAction = action
        }
    }
    
    ///
    public func didSet(_ attributeSet: AttributeList, forKey keyPath: String, didChange: Bool) {
        if didChange {
            let action = Transaction.values.currentAction as Action?
            self.endChange(keyPath, action)
            Transaction.values.currentAction = nil as Action?
        }
        Transaction.unlock()
    }
    
    ///
    internal func beginChange(_ keyPath: String) -> Action? {
        assert(!self.isReadOnly, "Attempting to modify read-only layer!")
        
        // Locate a possible action for the `keyPath`:
        var action: Action? = nil
        if !Transaction.disableActions {
            action = self.action(forKey: keyPath)
        }
        return action
    }
    
    ///
    internal func endChange(_ keyPath: String, _ action: Action?) {
        assert(!self.isReadOnly, "Attempting to modify read-only layer!")
        Transaction.ensure()
        self.mark() // TODO: only if layer prop!
        
        // check if transform only layer or not
        // update cached props
        // maybe invalidate media timing cache
        
        action?.run(forKey: keyPath, on: self, with: nil)
        
        // Mark needing display if this `keyPath` requires it:
        if type(of: self).needsDisplay(forKey: keyPath) {
            self.setNeedsDisplay()
        }
        
        //
        if keyPath == "bounds" && self.needsDisplayOnBoundsChange {
            self.setNeedsDisplay()
        }
        
        /* // TODO: needsLayoutForKey?
        if self.layoutIsActive {
            self.setNeedsLayout()
        }*/
    }

    //
    // MARK: - Layer Presentation vs Model
    //
    
    internal func ensureModel() {
        assert(!self.isReadOnly, "Expected model layer, not presentation layer!")
    }
    
    public func model() -> Self {
        return self
    }
    
    public func presentation() -> Self? {
        return nil
    }
    
    //
    // MARK: - Hashable & Equatable
    //
    
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
    
    public static func ==(_ lhs: Layer, _ rhs: Layer) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
}
