import CoreVideo.CVHostTime
#if canImport(AppKit)
import AppKit.NSOpenGL
#else
import OpenGL.CGLTypes
import OpenGL.CGLRenderers
#endif

/// A layer that provides a layer suitable for rendering OpenGL content.
/// To provide OpenGL content you must subclass and override the provided draw functions.
/// You can specify that the OpenGL content is static by setting the `isAsynchronous` property to `false`.
public class OpenGLLayer: Layer {
    
    /// Use the NSOpenGL variants instead of CGL variants if possible.
    /*#if canImport(AppKit)
    public typealias GLContext = NSOpenGLContext
    public typealias GLPixelFormat = NSOpenGLPixelFormat
    #else*/
    public typealias GLContext = CGLContextObj
    public typealias GLPixelFormat = CGLPixelFormatObj
    /*#endif*/
	
	///
	public static var shouldRenderOnBackgroundThread: Bool = true
    
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
    
    ///
	public var maximumFrameRate: Float = 60.0
    
    /// Provides access to the layer's associated `GLPixelFormat`. Subclasses
    /// should override `glPixelFormat.didSet` to ensure it is released
    /// appropriately when no longer needed.
    public private(set) var glPixelFormat: GLPixelFormat? = nil
    
    /// Provides access to the layer's associated `GLContext`. Subclasses
    /// should override `glContext.didSet` to ensure it is released
    /// appropriately when no longer needed.
    public private(set) var glContext: GLContext? = nil
	
	deinit {
		// TODO: OpenGLLayerDestroy
	}
    
    /// This method will be called by `OpenGLLayer` when a pixel format object
    /// is needed for the layer. Return an OpenGL pixel format suitable for
    /// rendering to the set of displays defined by the display `mask`. The
    /// default implementation returns a 32bpp fixed point pixel format, with
    /// `.noRecovery` and `.accelerated` flags set.
    public func glPixelFormat(for displayMask: UInt32) -> GLPixelFormat {
		var pix: CGLPixelFormatObj? = nil
		var num: GLint = 0
		let err = CGLChoosePixelFormat([
			kCGLPFANoRecovery,
			kCGLPFAAccelerated,
			CGLPixelFormatAttribute(0) /* TODO: 32bpp fixed point */
		], &pix, &num)
		assert(err.rawValue == 0)
		return pix!
    }
    
    /// Called by `OpenGLLayer` when a rendering context is needed by the layer.
    /// Return an OpenGL context with renderers from pixel format 'pf'. The
    /// default implementation allocates a new context with a null share context.
    public func glContext(for pixelFormat: GLPixelFormat) -> GLContext {
		var ctx: CGLContextObj? = nil
		let err = CGLCreateContext(pixelFormat, nil, &ctx)
		assert(err.rawValue == 0)
		return ctx!
    }

    /// Called when the OpenGL pixel format that was previously
	/// returned from `glPixelFormat(for:)` is no longer needed.
	public func destroy(_ pixelFormat: GLPixelFormat) {
		let err = CGLDestroyPixelFormat(pixelFormat)
		assert(err.rawValue == 0)
	}
    
    /// Called when the OpenGL context 'ctx' that was previously returned
	/// from `glContext(for:)` is no longer needed.
	public func destroy(_ context: GLContext) {
		let err = CGLDestroyContext(context)
		assert(err.rawValue == 0)
	}
    
    /// Called before attempting to render the frame for layer time `t`.
    /// When non-`nil`, `ts` describes the display timestamp associated with layer
    /// time 't'. If the method returns `false`, the frame is skipped. The default
    /// implementation always returns `true`.
    public func canDraw(in context: GLContext, pixelFormat: GLPixelFormat,
						forLayerTime t: CFTimeInterval,
						displayTime ts: UnsafePointer<CVTimeStamp>) -> Bool
	{
        return true
    }
    
    /// Called when a new frame needs to be generated for layer time `t`. `ctx`
    /// is attached to the rendering destination. Its state is otherwise undefined.
    /// When non-`nil`, `ts` describes the display timestamp associated with
    /// layer time 't'. Subclasses should call the superclass implementation of
    /// the method to flush the context after rendering.
    public func draw(in context: GLContext, pixelFormat: GLPixelFormat,
					 forLayerTime t: CFTimeInterval,
					 displayTime ts: UnsafePointer<CVTimeStamp>)
	{
        // stub
    }
	
	internal override func prepareContents() {
		let queue: ImageQueue
		if let _queue = self.contents as? ImageQueue {
			queue = _queue
		} else {
			queue = ImageQueue(ImageQueue.Size(width: UInt(self.bounds.size.width),
											   height: UInt(self.bounds.size.height)), 30)
		}
		
		//
		Transaction.whileLocked {
			if	queue.size.width != UInt(self.bounds.size.width) ||
				queue.size.height != UInt(self.bounds.size.height) {
				queue.size = ImageQueue.Size(width: UInt(self.bounds.size.width),
											 height: UInt(self.bounds.size.height))
			}
		}
		let isAsynchronous = self.isAsynchronous
		let renderTime = self.convert(CurrentMediaTime(), from: nil)
		if CurrentMediaTime() >= renderTime {
			let queueCount = Transaction.whileLocked { queue.collect() }
			if queueCount > 0 {
				
				//
				//self.destroy(self.glPixelFormat!)
				//self.destroy(self.glContext!)
				let pix = self.glPixelFormat(for: 0) // TODO: only if needed, recreate
				let ctx = self.glContext(for: pix) // TODO: only if needed, recreate
				
				//
				var screen: GLint = 0
				CGLGetVirtualScreen(ctx, &screen)
				var pixValue: GLint = 0
				CGLDescribePixelFormat(pix, screen, kCGLPFADisplayMask, &pixValue)
				// TODO: loop until found suitable screen?
				
				//
				CGLLockContext(ctx)
				let oldCtx = CGLGetCurrentContext()
				CGLSetCurrentContext(ctx)
				//self.setTimeBeingDrawnFor(renderTime)
				let layer = self.layerBeingDrawn()
				
				//
				var fake = CVTimeStamp()
				if layer.canDraw(in: ctx, pixelFormat: pix, forLayerTime: renderTime, displayTime: &fake) {
					CGLSetVirtualScreen(ctx, screen)
					CGLUpdateContext(ctx)
					
					//
					let surface = IOSurface(properties: [
						.width: queue.size.width,
						.height: queue.size.height,
						.bytesPerElement: 4,
						.bytesPerRow: queue.size.width * 16, /* TODO: why 16??? */
						//.allocSize: queue.size.width * queue.size.height * 4,
						.pixelFormat: 0x47524142 /* RGBA */
					])!
					let image = Transaction.whileLocked {
						return queue.register(ioSurface: surface)
						
						// TODO: unsure when to do the below instead
						//let id = IOSurfaceGetID(unsafeBitCast(surface, to: IOSurfaceRef.self))
						// alternatively call CGLCreatePBuffer()
					}
					
					//
					var tex: GLuint = 0
					glGenTextures(1, &tex)
					glBindTexture(GLenum(GL_TEXTURE_RECTANGLE_ARB), tex)
					let err = CGLTexImageIOSurface2D(ctx, GLenum(GL_TEXTURE_RECTANGLE_ARB), GLenum(GL_RGBA),
													 GLsizei(queue.size.width), GLsizei(queue.size.height),
													 GLenum(GL_BGRA), GLenum(GL_UNSIGNED_INT_8_8_8_8_REV),
													 unsafeBitCast(surface, to: IOSurfaceRef.self), 0)
					assert(err.rawValue == 0)
					glBindTexture(GLenum(GL_TEXTURE_RECTANGLE_ARB), 0)

					//
					var fbo: GLuint = 0
					glGenFramebuffers(1, &fbo)
					glBindFramebuffer(GLenum(GL_FRAMEBUFFER), fbo)
					glFramebufferTexture2D(GLenum(GL_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0),
										   GLenum(GL_TEXTURE_RECTANGLE_ARB), tex, 0)
					//glBindFramebuffer(GLenum(GL_FRAMEBUFFER), 0)
					
					// TODO: depth buffers not accounted for!
					
					//
					glViewport(0, 0, GLsizei(queue.size.width), GLsizei(queue.size.height))
					layer.draw(in: ctx, pixelFormat: pix, forLayerTime: renderTime, displayTime: &fake)
					glFlushRenderAPPLE()
					
					//
					Transaction.whileLocked {
						queue.insert(at: renderTime, image: image, flags: self.isOpaque ? .opaque : [])
						// set 0x20 flag
					}
				}
				
				//
				//self.setTimeBeingDrawnFor(renderTime)
				CGLSetCurrentContext(oldCtx)
				CGLUnlockContext(ctx)
			}
		}
		Transaction.whileLocked {
			// flags do not contain 0x20 + unconsumed image count > 1? -> add flags |= 0x20
			self.contents = queue
			if isAsynchronous {
				self.setNeedsCommit()
			}
			// flags |= 0x80
		}
		//self.updateTimer()
	}
	
	public override func invalidateContents() {
		super.invalidateContents()
		// TODO: OpenGLLayerDestroy
	}
	
	func layerDidChangeDisplay(_ display: CGDirectDisplayID) {
		Transaction.whileLocked {
			// let x = CGDisplayIDToOpenGLDisplayMask(display)
			// if x != saved_x:
			//     if asynchronous == false -> setNeedsDisplay
		}
	}
	
	// OpenGLLayerDestroy -> CGLDestroyPixelFormat(), CGLDestroyContext()
	// didChangeValueForKey -> "asynchronous" -> setNeedsDisplay ELSE ?
	// shouldArchiveValueForKey = false for ?
	// TODO: scheduleAnimationTimer -> ensure_queue() + update_timer()
	// TODO: cancelAnimationTimer
}
