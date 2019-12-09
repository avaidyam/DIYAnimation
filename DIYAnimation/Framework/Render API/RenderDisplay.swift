
extension Render {
	public final class Display {
		public private(set) var bounds: CGRect
		public private(set) var windowID: CGSWindowID
		public private(set) var surfaceID: CGSSurfaceID
		public private(set) var spaceID: CGSSpaceID
		public private(set) var context: CGLContextObj
		public private(set) var device: MTLDevice
		
		public var currentDrawable: MTLTexture?
		
		public init() {
			
			// Create appropriate window/surface regions for later.
			var rect = CGDisplayBounds(CGMainDisplayID())
			var region: CGSRegionRef? = nil
			var err = CGSNewRegionWithRect(&rect, &region)
			assert(err.rawValue == 0)
			var clean: CGSRegionRef? = nil
			err = CGSNewEmptyRegion(&clean)
			assert(err.rawValue == 0)
			
			// Create a non-opaque non-shadowed CGS window on-screen.
			var windowID: CGSWindowID = 0
			err = CGSNewWindow(CGSMainConnectionID(), 0x3, 0, 0, region, &windowID)
			assert(err.rawValue == 0)
			err = CGSSetWindowTags(CGSMainConnectionID(), windowID, [1 << 3 /* disable shadows */ | 1 << 9 /* disable all events */, 0], 0x8 * 0x8 /* 64-bit tag size */)
			assert(err.rawValue == 0)
			err = CGSSetWindowOpacity(CGSMainConnectionID(), windowID, false)
			assert(err.rawValue == 0)
			err = CGSOrderWindow(CGSMainConnectionID(), windowID, kCGSOrderAbove, 0)
			assert(err.rawValue == 0)
			
			// Create a non-opaque CGS window surface to bind a GL context to.
			var surfaceID: CGSSurfaceID = 0
			err = CGSAddSurface(CGSMainConnectionID(), windowID, &surfaceID)
			assert(err.rawValue == 0)
			err = CGSSetSurfaceBounds(CGSMainConnectionID(), windowID, surfaceID, rect)
			assert(err.rawValue == 0)
			err = CGSSetSurfaceOpacity(CGSMainConnectionID(), windowID, surfaceID, false)
			assert(err.rawValue == 0)
			err = CGSSetSurfaceResolution(CGSMainConnectionID(), windowID, surfaceID, 1.0) /* FIXME */
			assert(err.rawValue == 0)
			err = CGSOrderSurface(CGSMainConnectionID(), windowID, surfaceID, 1, 0)
			assert(err.rawValue == 0)
			
			// Create a shielding (above all others) CGS space to host the window.
			let spaceID = CGSSpaceCreate(CGSMainConnectionID(), 0x1 /* do not draw desktop icons */, nil)
			assert(spaceID > 0)
			CGSSpaceSetAbsoluteLevel(CGSMainConnectionID(), spaceID, 400 /* 400=facetime? */)
			CGSShowSpaces(CGSMainConnectionID(), [Int32(spaceID)] as CFArray)
			CGSAddWindowsToSpaces(CGSMainConnectionID(), [windowID] as CFArray, [spaceID] as CFArray)
			
			// Choose a default suitable pixel format for GL rendering.
			let attribs = [kCGLPFADoubleBuffer, kCGLPFAAccelerated, CGLPixelFormatAttribute(0)]
			var pix: CGLPixelFormatObj? = nil
			var num: GLint = 0
			var err2 = CGLChoosePixelFormat(attribs, &pix, &num)
			assert(err2.rawValue == 0)
			assert(pix != nil)
			
			// Create a new GL context with VSync enabled.
			var ctx: CGLContextObj? = nil
			err2 = CGLCreateContext(pix!, nil, &ctx)
			assert(err2.rawValue == 0)
			CGLDestroyPixelFormat(pix!)
			var vSync: GLint = 1
			err2 = CGLSetParameter(ctx!, kCGLCPSwapInterval, &vSync)
			assert(err2.rawValue == 0)
			
			// Bind the context's rendering surface and confirm it has a drawable.
			err2 = CGLSetSurface(ctx!, CGSMainConnectionID(), windowID, surfaceID)
			assert(err2.rawValue == 0)
			var drawable: GLint = 0
			err2 = CGLGetParameter(ctx!, kCGLCPHasDrawable, &drawable)
			assert(drawable == 1)
			
			self.bounds = rect
			self.windowID = windowID
			self.surfaceID = surfaceID
			self.spaceID = spaceID
			self.context = ctx!
			self.device = CGDirectDisplayCopyCurrentMetalDevice(CGMainDisplayID())!
		}

		// Clean up the GL context, CGS surface, CGS window, and CGS space.
		deinit {
			CGLDestroyContext(self.context)
			// TODO: SURFACE
			// TODO: WINDOW
			CGSHideSpaces(CGSMainConnectionID(), [self.spaceID] as CFArray)
			CGSSpaceDestroy(CGSMainConnectionID(), self.spaceID)
		}

		func render(_ texture: MTLTexture) {
			
			// Prepare the surface by clearing it with alpha=0.0 (non-opaque).
			CGLSetCurrentContext(self.context)
			glClearColor(0.0, 0.0, 0.0, 0.0)
			glClear(GLenum(GL_COLOR_BUFFER_BIT))
			
			// Convert the MTLTexture's backing IOSurface into an OpenGL Texture.
			var tex: GLuint = 0
			glGenTextures(1, &tex)
			glBindTexture(GLenum(GL_TEXTURE_RECTANGLE_ARB), tex)
			var err2 = CGLTexImageIOSurface2D(self.context, GLenum(GL_TEXTURE_RECTANGLE_ARB), GLenum(GL_RGBA), GLsizei(texture.width), GLsizei(texture.height), GLenum(GL_BGRA), GLenum(GL_UNSIGNED_INT_8_8_8_8_REV), unsafeBitCast(texture.iosurface, to: IOSurfaceRef.self), 0)
			assert(err2.rawValue == 0)
			
			// Bind the source and destination framebuffers to convert texture classes.
			var fbo: GLuint = 0
			glGenFramebuffers(1, &fbo)
			glBindFramebuffer(GLenum(GL_READ_FRAMEBUFFER), fbo)
			glBindFramebuffer(GLenum(GL_DRAW_FRAMEBUFFER), 0)
			glFramebufferTexture2D(GLenum(GL_READ_FRAMEBUFFER), GLenum(GL_COLOR_ATTACHMENT0), GLenum(GL_TEXTURE_RECTANGLE_ARB), tex, 0)
			
			// Flush the framebuffer to the screen/current drawable.
			// This blit call is the single largest drawback vs. SkyLight's rendering method.
			glBlitFramebuffer(0, 0, GLint(texture.width), GLint(texture.height), 0, 0, GLint(self.bounds.width), GLint(self.bounds.height), GLenum(GL_COLOR_BUFFER_BIT), GLenum(GL_LINEAR))
			err2 = CGLFlushDrawable(self.context)
			assert(err2.rawValue == 0)
			CGLSetCurrentContext(nil)
		}
		
		//
		func drawable(_ size: CGSize) -> MTLTexture {
			let m = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:width:height:mipmapped:)
			
			// Create the backing IOSurface that was requested.
			let surface = IOSurfaceCreate([
				kIOSurfaceWidth: size.width,
				kIOSurfaceHeight: size.height,
				kIOSurfaceBytesPerElement: 4,
				kIOSurfaceBytesPerRow: size.width * 4,
				kIOSurfaceAllocSize: size.width * size.height * 4,
				kIOSurfacePixelFormat: 0x47524142 /* RGBA */
			] as CFDictionary)!
			
			// Transfer that bitmap data into a new `MTLTexture`:
			let tex = self.device.makeTexture(descriptor: m(.bgra8Unorm, Int(size.width), Int(size.height), false), iosurface: surface, plane: 0)!
			return tex
		}

		// Load and convert an NSImage -> CGImage -> MTLTexture.
		// Be sure to swap byte order (RGBA8 -> BGRA8) as renderer uses BGRA.
		func render(_ cgImage: CGImage) {
			let texture = self.drawable(CGSize(width: cgImage.width, height: cgImage.height))
			Render.Image(cgImage, [.swapOrder]).draw(to: texture)
			self.render(texture)
		}
	}
}
