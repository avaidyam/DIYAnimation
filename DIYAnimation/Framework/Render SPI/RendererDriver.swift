
extension Renderer {
    
    /// A `Driver` translates render commands distilled from layer operations to
    /// the GPU or CPU as required to the selected render target.
    public /*abstract*/ class Driver {
        
        ///
        internal init() {
            // no-op: swallows all draw commands.
        }
        
        
        ///
        /// MARK: - Metal Driver
        ///
        
        
        ///
        public final class Metal: Driver {
            
            /// The device being used to render the layer scene.
            private let device: MTLDevice
            
            /// The command queue to encode all render pass infomation to.
            private let queue: MTLCommandQueue
            
            /// The context shared with CoreImage for applying layer filters.
            private let ciContext: CIContext
            
            ///
            internal convenience override init() {
                self.init(MTLCreateSystemDefaultDevice()!)
            }
            
            /// Create a new `Driver.Metal`.
            internal init(_ device: MTLDevice) {
                self.device = device
                self.queue = self.device.makeCommandQueue()!
                self.ciContext = CIContext(mtlDevice: self.device)
                
                // OGL render pass:
                // 1. begin
                //   2. prepare layers
                //   3. render layers
                // 4. end
            }
        }
        
        
        ///
        /// MARK: - Quartz Driver
        ///
        
        
        ///
        public final class Quartz: Driver {
            
            /// The default context.
            private static let defaultContext = CGContext(data: nil, width: 1,
                                                          height: 1, bitsPerComponent: 8,
                                                          bytesPerRow: 0,
                                                          space: CGColorSpaceCreateDeviceRGB(),
                                                          bitmapInfo: 0x2)!
            
            /// The context being used to render the layer scene.
            private let context: CGContext
            
            /// The context shared with CoreImage for applying layer filters.
            private let ciContext: CIContext
            
            ///
            internal convenience override init() {
                self.init(Quartz.defaultContext)
            }
            
            /// Create a new `Driver.Quartz`.
            internal init(_ context: CGContext) {
                self.context = context
                self.ciContext = CIContext(cgContext: self.context, options: nil)
                
                // TODO: draw stuff to new CGLayer, then draw layer to a diff context!
                //
                // let layer = CGLayer(context, size: size, auxiliaryInfo: nil)!
            }
        }
        
        
        ///
        /// MARK: - Unsupported Drivers
        ///
        
        
        ///
        public final class Vulkan: Driver {
            internal init(_ device: Any) {
                fatalError("DIYAnimation: Vulkan is not a supported render driver.")
            }
        }
        
        ///
        public final class CGL: Driver {
            internal init(_ device: Any) {
                fatalError("DIYAnimation: CoreGL (OpenGL-macOS) is not a supported render driver.")
            }
        }
        
        ///
        public final class GLES: Driver {
            internal init(_ device: Any) {
                fatalError("DIYAnimation: OpenGL ES (OpenGL-iOS) is not a supported render driver.")
            }
        }
    }
}
