import Metal.MTLDevice

///
internal protocol RenderDrawable {
    
    ///
    func texture(_ device: MTLDevice) -> MTLTexture
}

extension Render {
    
    ///
    internal final class Image: RenderValue, RenderDrawable {
        
        ///
        internal struct Options: OptionSet, Codable {
            internal var rawValue: Int
            internal init(rawValue: Int) {
                self.rawValue = rawValue
            }
            
            ///
            internal static let flipped = Options(rawValue: 1 << 0)
            
            ///
            internal static let mipmap = Options(rawValue: 1 << 1)
        }
        
        ///
        private static var commandQueue: MTLCommandQueue?
        
        ///
        private static var imageCache: [Weak<CGImage>: Image] = [:]
        
        ///
        private static var textureCache: [Weak<Image>: MTLTexture] = [:]
        
        ///
        private static var cacheLock = Lock()
        
        ///
        internal var width: Int
        
        ///
        internal var height: Int
        
        ///
        internal var bytesPerPixel: Int
        
        ///
        internal var bitsPerComponent: Int
        
        ///
        internal var data: Data
        
        ///
        internal var options: Options = []
        
        ///
        internal var bytesPerRow: Int {
            return self.width * self.bytesPerPixel
        }
        
        ///
        internal var dataSize: Int {
            return self.width * self.height * self.bytesPerPixel
        }
        
        ///
        internal var memory: SharedMemory? = nil
        
        ///
        internal var isVolatile: Bool = false {
            didSet {
                self.memory?.isVolatile = self.isVolatile
            }
        }
        
        ///
        internal var image: CGImage {
            return CGImage(width: self.width,
                           height: self.height,
                           bitsPerComponent: self.bitsPerComponent,
                           bitsPerPixel: self.bytesPerPixel * 8,
                           bytesPerRow: self.bytesPerRow,
                           space: CGColorSpaceCreateDeviceRGB(),
                           bitmapInfo: [],
                           provider: CGDataProvider(data: self.data as CFData)!,
                           decode: nil,
                           shouldInterpolate: true,
                           intent: .defaultIntent)!
        }
        
        ///
        internal init(_ width: Int, _ height: Int, _ bytesPerPixel: Int,
                      _ bitsPerComponent: Int, _ data: Data, _ options: Options = [])
        {
            // also has unsigned long* for levels
            // also has optional releaseHandler + releaseInfo passed into handler
            
            self.width = width
            self.height = height
            self.bytesPerPixel = bytesPerPixel
            self.bitsPerComponent = bitsPerComponent
            self.data = data
            self.options = options
        }
        
        ///
        internal convenience init(_ image: CGImage, _ options: Options = []) {
            
            // Configure a new bitmap context:
            let width = image.width
            let height = image.height
            let bytesPerPixel = image.bytesPerRow / image.width
            let bitsPerComponent = image.bitsPerComponent
            let bytesPerRow = image.bytesPerRow
            let colorSpace = image.colorSpace ?? CGColorSpaceCreateDeviceRGB()
            let opt = image.bitmapInfo.rawValue
            
            // Draw the image into the new context (decoding it):
            var data = Data(count: height * width * bytesPerPixel)
            data.withUnsafeMutableBytes { (x: UnsafeMutablePointer<UInt8>) -> Void in
                let ptr = UnsafeMutableRawPointer(x)
                let ctx = CGContext(data: ptr, width: width, height: height, bitsPerComponent: bitsPerComponent, bytesPerRow: bytesPerRow, space: colorSpace, bitmapInfo: opt)!
                
                // Flip the image if needed, then draw into the bounding rect:
                if options.contains(.flipped) {
                    ctx.translateBy(x: 0, y: CGFloat(height))
                    ctx.scaleBy(x: 1, y: -1)
                }
                let rect = CGRect(x: 0, y: 0, width: width, height: height)
                ctx.draw(image, in: rect)
                ctx.flush()
            }
            
            // Initialize with the raw decoded image data:
            self.init(width, height, bytesPerPixel, bitsPerComponent, data, options)
        }
        
        deinit {
            Image.cacheLock.whileLocked {
                Image.textureCache[Weak(self)] = nil
            }
            // finalize... then, release data... call handlers?
        }
        
        ///
        internal static func cached(for image: CGImage) -> Image {
            return Image.cacheLock.whileLocked {
                if let img = Image.imageCache[Weak(image)] {
                    return img
                } else {
                    let img = Image(image)
                    Image.imageCache[Weak(image)] = img
                    return img
                }
            }
        }
        
        ///
        internal func texture(_ device: MTLDevice) -> MTLTexture {
            return Image.cacheLock.whileLocked {
                
                // Return the previously cached texture if still valid:
                if let tex = Image.textureCache[Weak(self)],
                    tex.device.registryID == device.registryID {
                    return tex
                }
                
                // Transfer that bitmap data into a new `MTLTexture`:
                let m = MTLTextureDescriptor.texture2DDescriptor(pixelFormat:width:
                    height:mipmapped:)
                let tex = device.makeTexture(descriptor: m(.rgba8Unorm, width, height,
                                                           self.options.contains(.mipmap)))!
                let r = MTLRegionMake2D(0, 0, width, height)
                self.data.withUnsafeMutableBytes { (x: UnsafeMutablePointer<UInt8>) -> Void in
                    tex.replace(region: r, mipmapLevel: 0, withBytes: x,
                                bytesPerRow: self.width * self.bytesPerPixel)
                }
                
                // If we require mipmaps, generate them:
                if self.options.contains(.mipmap) && tex.mipmapLevelCount > 1 {
                    if Image.commandQueue == nil {
                        Image.commandQueue = device.makeCommandQueue()!
                    }
                    let b = Image.commandQueue!.makeCommandBuffer()!
                    let c = b.makeBlitCommandEncoder()!
                    c.generateMipmaps(for: tex)
                    c.endEncoding()
                    b.commit()
                    b.waitUntilCompleted()
                }
                
                // Cache and return the texture:
                Image.textureCache[Weak(self)] = tex
                return tex
            }
        }
        
        /// TODO: Copy sub-image range...
        internal func copy(subrange: (width: Int, height: Int)) -> Image? {
            return nil
        }
    }
}
