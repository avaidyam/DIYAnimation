import CoreVideo.CVBase
import CoreVideo.CVBuffer
import CoreVideo.CVImageBuffer
import CoreVideo.CVPixelBuffer
import CoreVideo.CVPixelBufferIOSurface

///
internal final class PixelBuffer: CustomStringConvertible, Hashable {
    
    ///
    internal typealias ReleaseHandler = @convention(block) () -> ()
    
    ///
    internal static func colorSpace(from attachments: [String: Any]) -> CGColorSpace? {
        return CVImageBufferCreateColorSpaceFromAttachments(attachments as CFDictionary)?.takeUnretainedValue()
    }
    
    ///
    internal static func resolve(_ attributes: [[String: Any]]) -> [String: Any]? {
        var out: CFDictionary? = nil
        CVPixelBufferCreateResolvedAttributesDictionary(nil, attributes as CFArray, &out)
        return out as? [String: Any]
    }
    
    ///
    private let buffer: CVPixelBuffer
    
    ///
    internal var width: Int {
        return CVPixelBufferGetWidth(self.buffer)
    }
    
    ///
    internal var height: Int {
        return CVPixelBufferGetHeight(self.buffer)
    }
    
    ///
    internal var pixelFormat: OSType {
        return CVPixelBufferGetPixelFormatType(self.buffer)
    }
    
    ///
    internal var baseAddress: UnsafeMutableRawPointer? {
        return CVPixelBufferGetBaseAddress(self.buffer)
    }
    
    ///
    internal var bytesPerRow: Int {
        return CVPixelBufferGetBytesPerRow(self.buffer)
    }
    
    ///
    internal var dataSize: Int {
        return CVPixelBufferGetDataSize(self.buffer)
    }
    
    ///
    internal var isPlanar: Bool {
        return CVPixelBufferIsPlanar(self.buffer)
    }
    
    ///
    internal var planeCount: Int {
        return CVPixelBufferGetPlaneCount(self.buffer)
    }
    
    ///
    public var encodedSize: CGSize {
        return CVImageBufferGetEncodedSize(self.buffer)
    }
    
    ///
    public var displaySize: CGSize {
        return CVImageBufferGetDisplaySize(self.buffer)
    }
    
    ///
    public var cleanRect: CGRect {
        return CVImageBufferGetCleanRect(self.buffer)
    }
    
    ///
    public var isFlipped: Bool {
        return CVImageBufferIsFlipped(self.buffer)
    }
    
    ///
    public var colorSpace: CGColorSpace? {
        return CVImageBufferGetColorSpace(self.buffer)?.takeUnretainedValue()
    }
    
    ///
    internal var ioSurface: IOSurface? {
		return unsafeBitCast(CVPixelBufferGetIOSurface(self.buffer)?.takeUnretainedValue(), to: IOSurface?.self)
    }

    ///
    internal init?(_ width: Int, _ height: Int, _ pixelFormat: OSType,
                   _ attributes: [String: Any]? = nil)
    {
        var b: CVPixelBuffer? = nil
        CVPixelBufferCreate(nil, width, height, pixelFormat, attributes as CFDictionary?, &b)
        guard let c = b else { return nil }
        self.buffer = c
    }
    
    ///
    internal init?(_ width: Int, _ height: Int, _ pixelFormat: OSType,
                   _ baseAddress: UnsafeMutableRawPointer, _ bytesPerRow: Int,
                   _ attributes: [String: Any]? = nil, _ releaseBytes: @escaping ReleaseHandler)
    {
        let q: CVPixelBufferReleaseBytesCallback = { o, _ in
            let qq = Unmanaged<AnyObject>.fromOpaque(o!).takeUnretainedValue() as! ReleaseHandler
            qq()
        }
        
        var b: CVPixelBuffer? = nil
        let qq = Unmanaged.passRetained(releaseBytes as AnyObject).toOpaque()
        CVPixelBufferCreateWithBytes(nil, width, height, pixelFormat, baseAddress, bytesPerRow, q, qq, attributes as CFDictionary?, &b)
        guard let c = b else { return nil }
        self.buffer = c
    }
    
    ///
    internal init?(_ width: Int, _ height: Int, _ pixelFormat: OSType,
                   _ dataAddress: UnsafeMutableRawPointer?, _ dataSize: Int,
                   _ numberOfPlanes: Int, _ planeBaseAddress: [UnsafeMutableRawPointer?],
                   _ planeWidth: [Int], _ planeHeight: [Int], _ planeBytesPerRow: [Int],
                   _ attributes: [String: Any]? = nil, _ releaseBytes: @escaping ReleaseHandler)
    {
        let q: CVPixelBufferReleasePlanarBytesCallback = { o, _, _, _, _ in
            let qq = Unmanaged<AnyObject>.fromOpaque(o!).takeUnretainedValue() as! ReleaseHandler
            qq()
        }
        
        var b: CVPixelBuffer? = nil
        let qq = Unmanaged.passRetained(releaseBytes as AnyObject).toOpaque()
        var planeBaseAddress = planeBaseAddress, planeWidth = planeWidth,
            planeHeight = planeHeight, planeBytesPerRow = planeBytesPerRow
        CVPixelBufferCreateWithPlanarBytes(nil, width, height, pixelFormat, dataAddress, dataSize, numberOfPlanes, &planeBaseAddress, &planeWidth, &planeHeight, &planeBytesPerRow, q, qq, attributes as CFDictionary?, &b)
        guard let c = b else { return nil }
        self.buffer = c
    }
    
    ///
    internal init?(surface: IOSurface, attributes: [String: Any]? = nil) {
        var x: Unmanaged<CVPixelBuffer>? = nil
		CVPixelBufferCreateWithIOSurface(nil, unsafeBitCast(surface, to: IOSurfaceRef.self), attributes as CFDictionary?, &x)
        guard let y = x?.takeRetainedValue() else { return nil }
        self.buffer = y
    }
    
    ///
    internal func set(attachment: Any, forKey key: String, mode: CVAttachmentMode) {
        CVBufferSetAttachment(self.buffer, key as CFString, attachment as CFTypeRef, mode)
    }
    
    ///
    internal func attachment(forKey key: String) -> (Any?, CVAttachmentMode) {
        var mode = CVAttachmentMode(rawValue: 0)!
        let out = CVBufferGetAttachment(self.buffer, key as CFString, &mode)
        return (out, mode)
    }
    
    ///
    internal func removeAttachment(forKey key: String) {
        CVBufferRemoveAttachment(self.buffer, key as CFString)
    }
    
    ///
    internal func set(attachments a: [String: Any], mode: CVAttachmentMode) {
        CVBufferSetAttachments(self.buffer, a as CFDictionary, mode)
    }
    
    ///
    internal func attachments(_ mode: CVAttachmentMode) -> [String: Any]? {
        return CVBufferGetAttachments(self.buffer, mode) as? [String: Any]
    }
    
    ///
    internal func removeAllAttachments() {
        CVBufferRemoveAllAttachments(self.buffer)
    }
    
    ///
    internal func propogateAttachments(to destination: PixelBuffer) {
        CVBufferPropagateAttachments(self.buffer, destination.buffer)
    }
    
    internal func lock(_ flags: CVPixelBufferLockFlags = []) {
        CVPixelBufferLockBaseAddress(self.buffer, flags)
    }
    
    internal func unlock(_ flags: CVPixelBufferLockFlags = []) {
        CVPixelBufferUnlockBaseAddress(self.buffer, flags)
    }
    
    ///
    internal func widthOfPlane(at planeIndex: Int) -> Int {
        return CVPixelBufferGetWidthOfPlane(self.buffer, planeIndex)
    }
    
    ///
    internal func heightOfPlane(at planeIndex: Int) -> Int {
        return CVPixelBufferGetHeightOfPlane(self.buffer, planeIndex)
    }
    
    ///
    internal func baseAddressOfPlane(at planeIndex: Int) -> UnsafeMutableRawPointer? {
        return CVPixelBufferGetBaseAddressOfPlane(self.buffer, planeIndex)
    }
    
    ///
    internal func bytesPerRowOfPlane(at planeIndex: Int) -> Int {
        return CVPixelBufferGetBytesPerRowOfPlane(self.buffer, planeIndex)
    }

    ///
    internal var extendedPixels: (left: Int, right: Int, top: Int, bottom: Int) {
        var left = 0, right = 0, top = 0, bottom = 0
        CVPixelBufferGetExtendedPixels(self.buffer, &left, &right, &top, &bottom)
        return (left: left, right: right, top: top, bottom: bottom)
    }
    
    ///
    internal func fillExtendedPixels() {
        CVPixelBufferFillExtendedPixels(self.buffer)
    }
    
    //
    //
    //
    
    internal var description: String {
        return CFCopyDescription(self.buffer) as String
    }
    
    internal static func ==(lhs: PixelBuffer, rhs: PixelBuffer) -> Bool {
        return lhs.buffer == rhs.buffer
    }
    
	internal func hash(into hasher: inout Hasher) {
		hasher.combine(self.buffer)
	}
}
