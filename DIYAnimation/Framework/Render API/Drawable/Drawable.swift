import Foundation
import MetalKit
import Accelerate

/// Anything that supports being drawn on a `Layer`. Note that the client of the
/// framework may not conform new types to this protocol; there are a few objects
/// "blessed" by the framework to support these features, like `CGImage` or
/// `IOSurface`. Use those instead of conforming new types to this protocol.
public protocol Drawable {}

//
// Builtins:
//

extension IOSurface: Drawable, RenderConvertible {
    var renderValue: Any {
        return Render.Surface(self)
    }
}
extension CGImage: Drawable, RenderConvertible {
    var renderValue: Any {
        return Render.Image.cached(for: self)
    }
}
#if canImport(AppKit)
import AppKit
extension NSImage: Drawable, RenderConvertible {
    var renderValue: Any {
        let img = self.cgImage(forProposedRect: nil, context: nil, hints: nil)!
        return Render.Image.cached(for: img)
    }
}
#endif

extension MTLTexture {
    
    /// Return a representation of the receiver as a `CGImage`, if possible.
    /// The receiver's pixel format must be `bgra8Unorm`.
    var cgImage: CGImage? {
        guard self.pixelFormat == .bgra8Unorm else { return nil }
        
        // read texture as byte array
        let rowBytes = self.width * 4
        let length = rowBytes * self.height
        let bgraBytes = [UInt8](repeating: 0, count: length)
        let region = MTLRegionMake2D(0, 0, self.width, self.height)
        self.getBytes(UnsafeMutableRawPointer(mutating: bgraBytes),
                      bytesPerRow: rowBytes, from: region, mipmapLevel: 0)
        
        // convert from BGRA to RGBA
        var bgraBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: bgraBytes),
                                       height: vImagePixelCount(self.height),
                                       width: vImagePixelCount(self.width), rowBytes: rowBytes)
        let rgbaBytes = [UInt8](repeating: 0, count: length)
        var rgbaBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: rgbaBytes),
                                       height: vImagePixelCount(self.height),
                                       width: vImagePixelCount(self.width), rowBytes: rowBytes)
        let map: [UInt8] = [2, 1, 0, 3]
        vImagePermuteChannels_ARGB8888(&bgraBuffer, &rgbaBuffer, map, 0)
        
        // flipping image vertically
        let flippedBytes = bgraBytes
        var flippedBuffer = vImage_Buffer(data: UnsafeMutableRawPointer(mutating: flippedBytes),
                                          height: vImagePixelCount(self.height),
                                          width: vImagePixelCount(self.width), rowBytes: rowBytes)
        vImageVerticalReflect_ARGB8888(&rgbaBuffer, &flippedBuffer, 0)
        
        // create CGImage with RGBA
        let space = CGColorSpaceCreateDeviceRGB()
        let bitmapInfo = CGBitmapInfo(rawValue: CGImageAlphaInfo.premultipliedLast.rawValue)
        guard let data = CFDataCreate(nil, flippedBytes, length) else { return nil }
        guard let provider = CGDataProvider(data: data) else { return nil }
        return CGImage(width: self.width,
                       height: self.height,
                       bitsPerComponent: 8,
                       bitsPerPixel: 32,
                       bytesPerRow: rowBytes,
                       space: space,
                       bitmapInfo: bitmapInfo,
                       provider: provider,
                       decode: nil,
                       shouldInterpolate: true,
                       intent: .defaultIntent)
    }
}
