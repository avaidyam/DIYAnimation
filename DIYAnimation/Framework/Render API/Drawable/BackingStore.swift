import Foundation
import Metal

// create BackingStore (IFF < 1024bytes!)
// share BackingStore vm page with renderer

///
internal final class BackingStore: Drawable, RenderConvertible, Hashable {
    
    ///
    typealias RenderType = Render.Surface
    
    ///
    internal struct Flags: OptionSet {
        typealias RawValue = Int
        internal let rawValue: Int
        internal init(rawValue: Int) {
            self.rawValue = rawValue
        }
        internal init(_ rawValue: Int) {
            self.rawValue = rawValue
        }
        
        ///
        internal static let opaque = Flags(0)
        
        ///
        internal static let cleared = Flags(1)
        
        ///
        internal static let mipmap = Flags(2)
        
        ///
        internal static let autoMipmap = Flags(3)
    }
    
    //
    //
    //
    
    /// Maintains a list of all `BackingStore`s allocated by the client process.
    internal static var allStores: [Weak<BackingStore>] = []
    
    /// All `BackingStore` operations are globally lock-acquired.
    private static var lock = Lock()
    
    ///
    private static var pendingCollect: Bool = false
    
    /// Marks the front buffer of the receiver as `volatile`, and the system is
    /// able to reclaim the memory used by only this buffer.
    internal var isVolatile: Bool = false {
        didSet {
            self.mark(volatile: self.isVolatile)
        }
    }
    
    /// The `CGColorSpace` used in displaying the contents of the receiver.
    internal var colorSpace = CGColorSpace(name: CGColorSpace.sRGB)!
    
    /// The region to be updated by the receiver during an `update(...)`.
    internal private(set) var updateShape: Shape = .empty
    
    ///
    private var frontBuffer: IOSurface? = nil
    
    ///
    private var backBuffer: IOSurface? = nil
    
    /// Create a new `BackingStore`.
    internal init() {
        BackingStore.allStores.append(Weak(self))
        self.invalidate()
    }
    
    deinit {
        BackingStore.allStores.removeAll { $0.value == self }
    }
    
    /// Begins collection of the receiver at the given `time`. See `collectBlocking()`.
    internal static func collect(_ time: TimeInterval) {
        BackingStore.lock.whileLocked {
            for x in BackingStore.allStores {
                x.value?.mark(volatile: true)
            }
            if !BackingStore.pendingCollect {
                Callback(at: time) {
                    BackingStore.pendingCollect = false
                    
                    // wait until all resources are collected...
                }
                BackingStore.pendingCollect = true
            }
        }
    }
    
    /// Begins collection of the receiver immediately.
    internal static func collectBlocking() {
        // TODO: ... ehh....
        BackingStore.lock.whileLocked {
            for x in BackingStore.allStores {
                x.value?.mark(volatile: true)
            }
        }
    }
    
    /// Updates the currently selected buffer of the reciever, invoking `handler`.
    internal func update(size: CGSize, _ flags: Flags, _ handler: (CGContext) -> ()) {
        assert(size.width > 0 && size.height > 0, "BackingStore size must be non-zero!")
        
        // TODO: Use layer's contentsFormat and Flags!!
        if self.frontBuffer == nil ||
            (self.frontBuffer!.width != Int(size.width) ||
                self.frontBuffer!.height != Int(size.height)) {
            
            self.frontBuffer = IOSurface(properties: [
                .width: Int(size.width),
                .height: Int(size.height),
                .pixelFormat: 0x42475241,//"ARGB",
                .bytesPerElement: 4,
            ])!
        }
        
        //var pixels = [UInt8](repeating: 0, count: Int(height * width * 4))
        //let crtx = CGContext(data: &pixels, width: Int(size.width), height: Int(size.height), bitsPerComponent: 8, bytesPerRow: Int(size.width) * 4, space: self.colorSpace, bitmapInfo: bmp, releaseCallback: nil, releaseInfo: nil)
        
        //self.surface.lock(options: [], seed: nil)
        let bmp = CGImageAlphaInfo.premultipliedFirst.rawValue |
                  CGBitmapInfo.byteOrder32Little.rawValue
		let ctx = CGIOSurfaceContextCreate(unsafeBitCast(self.frontBuffer!, to: IOSurfaceRef.self),
										   Int(size.width), Int(size.height), 8, 32,
                                           self.colorSpace, bmp)!
        handler(ctx)
        //ctx.flush() // might defeat purpose of CGIOSurfaceContext...
        //self.surface.unlock(options: [], seed: nil)
        
        // TODO: manage the back buffer!
        self.swap()
    }
    
    /// Swaps the front and back buffers of the receiver.
    internal func swap() {
        BackingStore.lock.whileLocked {
            let x = self.frontBuffer
            self.frontBuffer = self.backBuffer
            self.backBuffer = x
        }
    }
    
    /// Invalidates a region of the receiver; if none provided, an infinite rect
    /// indicates the whole contents of the receiver must be redrawn.
    internal func invalidate(_ rect: CGRect = .infinite) {
        self.updateShape.components.append(rect)
    }
    
    /// Purges both buffers used by the receiver. The contents will be completely
    /// redrawn upon reuse.
    internal func purge() {
        self.frontBuffer = nil
        self.swap()
    }
    
    internal func mark(volatile: Bool) {
        // TODO: mark both front + back buffers as volatile
    }
}

internal extension BackingStore {
    var renderValue: Any {
        return (self.frontBuffer ?? self.backBuffer)!.renderValue
    }
    /*
    func texture(_ device: MTLDevice) -> MTLTexture {
        return (self.frontBuffer ?? self.backBuffer)!.texture(device)
    }
    func image() -> CGImage {
        return (self.frontBuffer ?? self.backBuffer)!.image()
    }*/
}

internal extension BackingStore {
	static func ==(lhs: BackingStore, rhs: BackingStore) -> Bool {
        return ObjectIdentifier(lhs) == ObjectIdentifier(rhs)
    }
	func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}

// void UIGraphicsBeginImageContextWithOptions(CGSize size, BOOL opaque = NO, CGFloat scale = 1.0);
// UIImage *UIGraphicsGetImageFromCurrentImageContext();
// void UIGraphicsEndImageContext();
//
//
//
// If the opaque parameter is YES, the alpha channel is ignored and the bitmap is treated as fully opaque (kCGImageAlphaNoneSkipFirst | kCGBitmapByteOrder32Host). Otherwise, each pixel uses a premultipled ARGB format (kCGImageAlphaPremultipliedFirst | kCGBitmapByteOrder32Host).

#if canImport(AppKit)
import AppKit
internal extension NSGraphicsContext {
    
    ///
	static func using(_ ctx: CGContext, _ flipped: Bool = false,
                               _ handler: () -> ())
    {
        NSGraphicsContext.saveGraphicsState()
        NSGraphicsContext.current = NSGraphicsContext(cgContext: ctx, flipped: false)
        handler()
        NSGraphicsContext.restoreGraphicsState()
    }
}
#endif
