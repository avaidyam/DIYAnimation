import Foundation.NSDate
import CoreVideo.CVBase

///
internal final class ImageQueue {
    
    ///
    public typealias Size = (width: UInt, height: UInt)
    
    ///
    public typealias ImageID = UInt64
    
    ///
    public typealias ImageRemoveHandler = (ImageType, ImageID, ImageInfo?) -> ()
    
    /// Image types for `insert(_:)`.
    public enum ImageType {
        
        /// CGSSurfaceID
        case surface
        
        /// Result of `register(*:)`
        case buffer
        
        /// IOSurfaceID
        case ioSurface
    }
    
    ///
    public struct Flags: OptionSet {
        public typealias RawValue = Int
        public var rawValue: Int
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        public init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        /// Asynchronous queues will be continuously polled by the renderer
        /// for new frames. Synchronous queues will only be polled when the
        /// layers that reference them are marked dirty (i.e. committed into
        /// the render tree.) Asynchronous queues may be marked synchronous at
        /// any point, and vice versa.
        public static let async = Flags(1 << 0)
        
        /// When set, we ignore the rule that displayed images must be after
        /// the current layer time. This means that the latest image before the
        /// sample time will be displayed.
        public static let fill = Flags(1 << 1)
        
        /// Image queue content is "protected".
        public static let protected = Flags(1 << 2)
        
        /// Display the clean aperture of the pixel buffer, not the entire
        /// encoded contents.
        public static let cleanAperture = Flags(1 << 3)
        
        /// Include the effect of the pixel aspect ratio when applying the
        /// contents gravity of the layer.
        public static let useAspectRatio = Flags(1 << 4)
        
        /// Use the fastest color matching method. May clip components and/or
        /// introduce posterization.
        public static let lowQualityColor = Flags(1 << 5)
    }
    
    ///
    public struct ImageFlags: OptionSet {
        public typealias RawValue = Int
        public var rawValue: Int
        public init(rawValue: RawValue) {
            self.rawValue = rawValue
        }
        public init(_ rawValue: RawValue) {
            self.rawValue = rawValue
        }
        
        /// Marks an inserted image wholly opaque.
        public static let opaque = ImageFlags(1 << 0)
        
        /// Atomically flushes the queue before inserting the new image.
        public static let flush = ImageFlags(1 << 1)
        
        /// Insert the image such that it won't be used or deleted until the
        /// queue has next been flushed.
        public static let willFlush = ImageFlags(1 << 2)
        
        /// Marks that the inserted image is flipped vertically.
        public static let flipped = ImageFlags(1 << 3)
        
        /// Marks that the attached image has outstanding GPU rendering
        /// commands targeting it. The consumer of the image sample needs to
        /// somehow synchronize with the GPU before displaying the image.
        public static let waitGPU = ImageFlags(1 << 4)
    }
    
    ///
    public struct VBLInfo {
        
        ///
        public let hostTime: UInt64
        
        ///
        public let localTime: TimeInterval
        
        ///
        public let hostRate: Float
    }
    
    /// When called from the 'release' callback of an image entered into
    /// the queue, returns the address of a structure describing when the
    /// image was first displayed (in layer time), and how many times it
    /// was displayed. May return a null pointer.
    public struct ImageInfo {
        
        /// The number of times this image was displayed.
        public let displayCount: UInt32
        
        /// The layer time at which this image was first displayed.
        public let localTime: TimeInterval
        
        /// Whether this image was flushed or not.
        public let wasFlushed: Bool
        
        /// The host time at which this image was first displayed.
        public let hostTime: UInt64
    }
    
    /// Change the size of images added to the queue.
    public var size: Size = (width: 0, height: 0)
    
    ///
    public var capacity: UInt = 0
    
    /// Set or get the flags associated with the receiver.
    public var flags: Flags = Flags(0) {
        didSet {
            // if different, call ping()!
        }
    }
    
    /// Defines the latest time that the image queue has the canonical image
    /// for. If an image is required after this time and none is available,
    /// offline renderers may decide to wait for new images to be inserted
    /// into the queue. (Real-time renderers will always use the latest
    /// image at or before the current sample time.) The default value of
    /// this property is Infinity. Flushing the queue resets it to the
    /// default value. (Note that if layer time is currently playing backwards
    /// the meaning of any comparisons against this value are inverted.)
    public var latestCanonicalTime: TimeInterval = 0
    
    ///
    private var buffers: [ImageID: Any] = [:] {
        didSet {
            // retain contexts
            // encode update message:
            //      - buffer deletions
            //      - buffer additions
            //          - shmem additions
            // send message
            // CASPing
        }
    }
    
    /// Create a new image queue. All images in the queue will have the specified
    /// `width` and `height`. The queue will be able to hold `capacity` images
    /// at once.
    public init(_ size: Size, _ capacity: UInt) {
        self.size = size
        self.capacity = capacity
        
        // create metadata Shmem
    }
    
    deinit {
        self.invalidate()
    }
    
    /// Free all images in the queue. Any subsequent image queue operation
    /// will have undefined results.
    public func invalidate() {
        
        // TODO: maybe don't do this??
        self.flush()
    }
    
    /// Invalidate all images in the queue.
    public func flush() {
        _ = self.collect() // do this for all things in the queue
    }
    
    /// Removes all consumed images except the latest from the queue. Returns
    /// the number of free slots.
    public func collect() -> Int {
        return 0
    }
    
    /// Push one image into the queue for time `time`. The image is of kind
    /// `type` and has identifier `id` (meaning defined by `type`). This
    /// function returns true if successful, or false if the queue was
    /// already full. If non-`nil`, `removeHandler` defines a function to be called
    /// when the image is removed from the queue.
    public func insert(at time: TimeInterval, type: ImageType, id: ImageID, flags: ImageFlags, _ removeHandler: ImageRemoveHandler)
    {
        
    }
    
    /// Register an image buffer with the queue. Returns the id to be used
    /// to insert the buffer into the queue (with type `.buffer`).
    /// `format` is one of the members of the `Layer.ImageFormat` enum.
    public func register(buffer: UnsafeRawPointer, _ rowbytes: Int, _ width: Int,
                         _ height: Int, _ format: Layer.ContentsFormat) -> ImageID
    {
        return self.register(pixelBuffer: buffer,
                             0, /* TODO: calculate this! */
                             rowbytes, width, height,
                             OSType() /* TODO: convert this! */
        )
    }
    
    /// Register a CoreVideo style pixel buffer with the image queue.
    /// Returns the id to be used to insert the buffer into the queue (with
    /// type `.buffer`). `pixelFormat` is the CoreVideo style
    /// pixel format type.
    public func register(pixelBuffer: UnsafeRawPointer, _ size: Int,
                         _ rowbytes: Int, _ width: Int, _ height: Int,
                         _ format: OSType, _ attachments: [String: Any]? = nil,
                         _ flags: ImageFlags = ImageFlags(0)) -> ImageID
    {
        // create PixelBuffer with new Shmem and call register with it
        return 0
    }
    
    /// Register an `IOSurface` buffer with the receiver.
    public func register(ioSurfaceBuffer: IOSurface) -> ImageID {
        // create Surface and call register with it
        // remember to inc/dec surface use count!
        return 0
    }
    
    /// Register a `CVImageBuffer` with the receiver.
    public func register(imageBuffer: CVImageBuffer) -> ImageID {
        // can be IOSurface-backed or Pixel backed!
        return 0
    }
    
    /// Remove a previously registered image buffer.
    public func delete(buffer: ImageID) {
        
        // remember to inc/dec surface use count!
    }
    
    /// Query the next times at which the queue will be sampled. Up to
    /// 'count' times will be placed in 'buffer'. The actual number of time
    /// values stored in the buffer will be returned.
    public func samplingTimes() -> [TimeInterval] {
        return []
    }
    
    ///
    public func vblInfo() -> [VBLInfo] {
        return []
    }
    
    ///
    public func timestamp(for vbl: VBLInfo) -> CVTimeStamp {
        return CVTimeStamp()
    }
    
    /// Returns the sample time of the latest image in the queue.
    public var latestTime: TimeInterval {
        return 0
    }
    
    ///
    public var lastUpdateHostTime: TimeInterval {
        return 0
    }
    
    /// Returns the sample time of the latest displayed image in the queue.
    public var displayTime: TimeInterval {
        return 0
    }
    
    /// Returns the display mask associated with the receiver.
    public var displayMask: CGOpenGLDisplayMask = 0
    
    /// Returns the GPU registry ID associated with the receiver.
    public var gpuRegistryID: UInt64 = 0
    
    /// Returns the number of unconsumed images in the queue. If that is
    /// nonzero, the minimum and maximum time of those images is placed in
    /// 'minTime' and 'maxTime' respectively.
    public var unconsumedImageCount: (count: Int, min: TimeInterval?, max: TimeInterval?) {
        return (count: 0, min: nil, max: nil)
    }
    
    ///
    private func ping() {
        // retain context
        // will commit
        // did commit
        // CASUpdateClient
    }
    
    ///
    private func collectable() {
        
    }
    
    ///
    private func didComposite() {
        
    }
}
