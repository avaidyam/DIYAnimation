import IOSurface
import Metal.MTLTexture
import CoreImage.CIContext
import CoreImage.CIImage

extension Render {
    
    ///
    internal final class Surface: RenderValue, RenderDrawable {
        
        ///
        private enum CodingKeys: CodingKey {
            case surfaceID
        }
        
        ///
        internal enum SurfaceError: Error {
            case invalidID
        }
        
        ///
        internal let surface: IOSurface
        
        ///
        internal var image: CGImage {
            let b = CGRect(x: 0, y: 0,
                           width: self.surface.width,
                           height: self.surface.height)
            let ctx = CIContext(options: nil)
            let img = CIImage(ioSurface: __ioNS2CF(self.surface)!)
            return ctx.createCGImage(img, from: b)!
        }
        
        ///
        internal init(_ surface: IOSurface) {
            self.surface = surface
            self.surface.incrementUseCount()
        }
        
        deinit {
            self.surface.decrementUseCount()
        }
        
        ///
        internal init(from decoder: Decoder) throws {
            let container = try decoder.container(keyedBy: CodingKeys.self)
            let id = try container.decode(IOSurfaceID.self, forKey: .surfaceID)
            
            // Ensure the lookup returned a valid `IOSurface`!
            guard let surface = IOSurfaceLookup(id) else {
                throw SurfaceError.invalidID
            }
            self.surface = __ioCF2NS(surface)!
        }
        
        ///
        internal func encode(to encoder: Encoder) throws {
            var container = encoder.container(keyedBy: CodingKeys.self)
			try container.encode(IOSurfaceGetID(__ioNS2CF(self.surface)!), forKey: .surfaceID)
        }
        
        ///
        internal func texture(_ device: MTLDevice) -> MTLTexture {
            let desc = MTLTextureDescriptor()
            desc.width = self.surface.width
            desc.height = self.surface.height
            desc.textureType = .type2D
            desc.usage = .shaderRead
            desc.storageMode = .managed
            //desc.pixelFormat = .bgra8Unorm
            return device.makeTexture(descriptor: desc,
									  iosurface: __ioNS2CF(self.surface)!,
                                      plane: 0)!
        }
        
    }
    
    ///
    internal final class PixelBuffer: RenderValue {
        // TODO
    }
}
