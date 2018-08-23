import Metal.MTLDrawable

/// **Note:** The default value of the `opaque' property for `MetalLayer`
/// instances is `true`.
public class MetalLayer: Layer {
    
    /// This property determines which `MTLDevice` the `MTLTexture` objects for
    /// the drawables will be created from. It must be set explicitly before
    /// asking for the first drawable.
    public var device: MTLDevice? = nil
    
    /// This property controls the pixel format of the `MTLTexture` objects.
    /// The two supported values are `.brga8Unorm` and `.brga8Unorm_sRGB`.
    public var pixelFormat: MTLPixelFormat = .bgra8Unorm
    
    /// This property controls whether or not the returned drawables' `MTLTexture`s
    /// may only be used for framebuffer attachments (`true`) or  whether they
    /// may also be used for texture sampling and pixel read/write operations
    /// (`false`). A value of `true` allows `MetalLayer` to allocate the
    /// `MTLTexture` objects in ways that are optimized for display purposes that
    /// makes them unsuitable for sampling.
    public var framebufferOnly: Bool = true
    
    /// This property controls the pixel dimensions of the returned drawables.
    /// The most typical value will be the layer size multiplied by the layer
    /// `contentsScale` property.
    public var drawableSize: CGSize = .zero
    
    /// Get the swap queue's next available drawable. Always blocks until a
    /// drawable is available.
    ///
    /// Can return `nil` under the following conditions:
    ///     1) The layer has an invalid combination of drawable properties.
    ///     2) All drawables in the swap queue are in-use and the 1s timeout has elapsed.
    ///        (except when `allowsNextDrawableTimeout' is set to `false`)
    ///     3) Process is out of memory.
    public func nextDrawable() -> MetalDrawable? {
        return nil
    }
    
    /// Controls the number maximum number of drawables in the swap queue.
    /// Values set outside of range [2, 3] are ignored and an exception will be
    /// thrown.
    public var maximumDrawableCount: Int = 3 {
        didSet {
            assert(self.maximumDrawableCount < 2 || self.maximumDrawableCount > 3,
                   "Cannot set the maximum drawable count outside of range [2, 3]!")
        }
    }
    
    /// When false (the default value) changes to the layer's render buffer appear
    /// on-screen asynchronously to normal layer updates. When `true`, changes
    /// to the MTL content are sent to the screen via the standard `Transaction`
    /// mechanisms.
    public var presentsWithTransaction: Bool = false
    
    /// The colorspace of the rendered frames. If `nil`, no colormatching occurs.
    /// If non-`nil`, the rendered content will be colormatched to the colorspace
    /// of the context containing this layer (typically the display's colorspace).
    public var colorspace: CGColorSpace? = nil
    
    /// If any rendering context on the screen has this enabled, all content will
    /// be clamped to its `NSScreen.maximumExtendedDynamicRangeColorComponentValue`
    /// rather than `1.0`.
    public var wantsExtendedDynamicRangeContent: Bool = false
    
    /// This property controls if this layer and its drawables will be synchronized
    /// to the display's Vsync.
    public var displaySyncEnabled: Bool = true
    
    /// Controls if `nextDrawable()' is allowed to timeout after 1 second and
    /// return `nil` if the system does not have a free drawable available.
    ///
    /// If set to `false`, then `nextDrawable()' will block forever until a free
    /// drawable is available.
    public var allowsNextDrawableTimeout: Bool = true
    
    ///
    public var isServerSyncEnabled: Bool = true
    
    ///
    public var isFenceEnabled: Bool = true
    
    ///
    internal var isDrawableAvailable: Bool {
        return false //
    }
    
    ///
    internal func discardContents() {
        //
    }
}

/// `MetalDrawable` represents a displayable buffer that vends an object
/// that conforms to the `MTLTexture` protocol that may be used to create
/// a render target for Metal.
///
/// Note: `MetalLayer` maintains an internal pool of textures used for
/// display. In order for a texture to be re-used for a new `MetalDrawable`,
/// any prior `MetalDrawable` must have been deallocated and another
/// `MetalDrawable` presented.
public final class MetalDrawable: NSObject, MTLDrawable {
    
    /// This is an object that conforms to the `MTLTexture` protocol and will
    /// typically be used to create an `MTLRenderTargetDescriptor`.
    public fileprivate(set) var texture: MTLTexture
    
    /// This is the `MetalLayer` responsible for displaying the drawable.
    public fileprivate(set) weak var layer: MetalLayer? = nil
    
    ///
    fileprivate init(texture: MTLTexture, layer: MetalLayer) {
        self.texture = texture
        self.layer = layer
    }
    
    ///
    public func present() {
        
    }
    
    ///
    public func present(at presentationTime: CFTimeInterval) {
        
    }
}
