import CoreVideo.CVHostTime
#if canImport(AppKit)
import AppKit.NSOpenGL
#else
import OpenGL.CGLTypes
import OpenGL.CGLRenderers
#endif

///
public class OpenGLLayer: Layer {
    
    /// Use the NSOpenGL variants instead of CGL variants if possible.
    #if canImport(AppKit)
    public typealias GLContext = NSOpenGLContext
    public typealias GLPixelFormat = NSOpenGLPixelFormat
    #else
    public typealias GLContext = CGLContextObj
    public typealias GLPixelFormat = CGLPixelFormatObj
    #endif
    
    /// When false the contents of the layer is only updated in response to
    /// `setNeedsDisplay()` messages. When true the layer is asked to redraw
    /// periodically with timestamps matching the display update frequency.
    public var isAsynchronous: Bool = false
    
    /// The colorspace of the rendered frames. If `nil`, no colormatching occurs.
    /// If non-`nil`, the rendered content will be colormatched to the colorspace
    /// of the context containing this layer (typically the display's colorspace).
    public var colorspace: CGColorSpace? = nil
    
    /// If any rendering context on the screen has this enabled, all content will
    /// be clamped to its `NSScreen.maximumExtendedDynamicRangeColorComponentValue`
    /// rather than 1.0.
    public var wantsExtendedDynamicRangeContent: Bool = false
    
    /// Provides access to the layer's associated `GLPixelFormat`. Subclasses
    /// should override `glPixelFormat.didSet` to ensure it is released
    /// appropriately when no longer needed.
    public private(set) var glPixelFormat: GLPixelFormat? = nil
    
    /// Provides access to the layer's associated `GLContext`. Subclasses
    /// should override `glContext.didSet` to ensure it is released
    /// appropriately when no longer needed.
    public private(set) var glContext: GLContext? = nil
    
    /// This method will be called by `OpenGLLayer` when a pixel format object
    /// is needed for the layer. Return an OpenGL pixel format suitable for
    /// rendering to the set of displays defined by the display `mask`. The
    /// default implementation returns a 32bpp fixed point pixel format, with
    /// `.noRecovery` and `.accelerated` flags set.
    public func glPixelFormat(forDisplayMask mask: UInt32) -> GLPixelFormat! {
        return nil // should not!
    }
    
    /// Called by `OpenGLLayer` when a rendering context is needed by the layer.
    /// Return an OpenGL context with renderers from pixel format 'pf'. The
    /// default implementation allocates a new context with a null share context.
    public func glContext(for pixelFormat: GLPixelFormat) -> GLContext! {
        return nil // should not!
    }
    
    /// Called before attempting to render the frame for layer time `t`.
    /// When non-`nil`, `ts` describes the display timestamp associated with layer
    /// time 't'. If the method returns `false`, the frame is skipped. The default
    /// implementation always returns `true`.
    public func canDraw(in context: GLContext, pixelFormat: GLPixelFormat, forLayerTime t: CFTimeInterval, displayTime ts: UnsafePointer<CVTimeStamp>) -> Bool {
        return true
    }
    
    /// Called when a new frame needs to be generated for layer time `t`. `ctx`
    /// is attached to the rendering destination. Its state is otherwise undefined.
    /// When non-`nil`, `ts` describes the display timestamp associated with
    /// layer time 't'. Subclasses should call the superclass implementation of
    /// the method to flush the context after rendering.
    public func draw(in context: GLContext, pixelFormat: GLPixelFormat, forLayerTime t: CFTimeInterval, displayTime ts: UnsafePointer<CVTimeStamp>) {
        
    }
}
