import Dispatch
import Metal

/// A class that allows an application to render a layer tree into a Metal
/// rendering context.
public final class Renderer {
    
    /// The possible phases a `Renderer` can be in.
    private enum Phase {
        
        /// The current frame to render has begun.
        case begin
        
        /// The current frame is being rendered.
        case render
        
        /// There is no current frame to render.
        case ended
    }
    
    ///
    public private(set) var driver: Renderer.Driver = .Metal()
    
    /// The device being used to render the layer scene.
    public private(set) var device: MTLDevice
    
    /// The rendering surface that the `Renderer` will output to.
    /// Note: if the render target was made on a different `MTLDevice`, that
    /// device will be used to render.
    public weak var renderTarget: MTLTexture? = nil {
        didSet {
            guard let t = self.renderTarget else { return }
            if self.device.registryID != t.device.registryID {
                self.device = t.device
                self.queue = self.device.makeCommandQueue()!
                self.ciContext = CIContext(mtlDevice: self.device)
            }
        }
    }
    
    ///
    public var context: Context? = nil {
        didSet {
            
        }
    }
    
    /// The root layer of the layer-tree the receiver should render.
    public var layer: Layer? {
        get { return self.context?.layer }
        set {
            if self.context == nil {
                self.context = Context.local()
            }
            self.context?.layer = newValue
        }
    }
    
    /// The size of the rendered surface. Must match the `renderTarget` size.
    public var bounds: CGRect = .zero {
        didSet {
            self.viewport.0 = MTLViewport(originX: 0, originY: 0,
                                          width: Double(self.bounds.width),
                                          height: Double(self.bounds.height),
                                          znear: -1.0, zfar: 1.0)
            self.viewport.1 = .orthographic(left: 0, right: Float(self.bounds.width),
                                            bottom: 0, top: Float(self.bounds.height),
                                            zNear: -1.0, zFar: 1.0)
        }
    }
    
    /// The current render phase of the receiver.
    private var phase: Phase = .ended
    
    /// The origin frame time for the current frame pass.
    private var frameTime: TimeInterval = 0.0
    
    /// The region to update in the next frame pass.
    private var updateShape: Shape = .empty
    
    /// The viewport and projection matrix (MVP) for rendering; dependent on `bounds`.
    private var viewport = (MTLViewport(), Transform3D.identity)
    
    /// The per-frame render semaphore that synchronizes each frame render.
    private var semaphore: DispatchSemaphore
    
    /// The dispatch queue that offloads all rendering activity.
    private var dispatch: DispatchQueue
    
    /// The command queue to encode all render pass infomation to.
    private var queue: MTLCommandQueue
    
    /// The context shared with CoreImage for applying layer filters.
    private var ciContext: CIContext
    
    /// The pipeline used by rendering operations.
    private var pipeline: RenderOp.State.Pipeline
    
    /// Create a new `Renderer` with the given `device`.
    public required init(_ device: MTLDevice = MTLCreateSystemDefaultDevice()!) {
        self.semaphore = DispatchSemaphore(value: 1)
        self.dispatch = DispatchQueue(label: "Renderer", attributes: [.concurrent])
        
        // Create device-specific resources:
        self.device = device
        self.queue = device.makeCommandQueue()!
        self.ciContext = CIContext(mtlDevice: self.device)
        self.pipeline = RenderOp.State.Pipeline.create(self.device)
    }
    
    /// Begin rendering a frame at the specified time.
    public func beginFrame(atTime t: TimeInterval, timeStamp: CVTimeStamp? = nil) {
        guard self.layer != nil else { return }
        guard self.renderTarget != nil else { return }
        assert(self.phase == .ended, "Cannot begin a new frame with phase \(self.phase)!")
        
        // Perform actions:
        self.frameTime = t
        // add self.layer.context to update list
        
        // Set new phase:
        self.phase = .begin
    }
    
    /// Render the update region of the current frame to the target context.
    public func render(_ scheduledHandler: @escaping () -> () = {}) {
        guard self.layer != nil else { return }
        guard self.renderTarget != nil else { return }
        assert(self.phase == .begin, "Cannot render a frame with phase \(self.phase)!")
        
        let frameTime = self.frameTime // local shadow
        let output = self.renderTarget! // local shadow
        
        // Wait for prior render pass first, then queue the current one:
        _ = self.semaphore.wait(timeout: .now() + .milliseconds(16))
        self.dispatch.async {
            
            // Create a command buffer and begin asynchronous encoding:
            let commandBuffer = self.queue.makeCommandBuffer()!
            commandBuffer.enqueue()
            let texSize = MTLSize(width: output.width,
                                  height: output.height,
                                  depth: output.depth)
            
            // Encodes the drawing commands for the `layer` and its sublayers, returning
            // an `MTLTexture` containing the rendered output.
            //
            // Perform the render operation chain and extract the resultant texture:
            //
            // TODO: Creating the RenderOp takes ~6x more time (10ms vs 1.7ms)! Offload it to pre-render phase.
            // TODO: `LayerNode(from:at:)` is absurdly slow! About ~0.5ms per conversion!
            // TODO: Don't recreate the buffer each time in RenderOp!
			// TODO: You MUST turn off "GPU Frame Capture" in Xcode or things go bad! Real bad!
            //
            let op = RenderOp(for: self.layer!, with: self.device, size: texSize) {
                $0.displayIfNeeded() // TODO!
                return LayerNode(from: $0, at: frameTime)
            }
            op.perform(RenderOp.State(commandBuffer, self.ciContext, self.pipeline, self.viewport.1.m))
            
            // Blit from the current texture into the render target:
            let blit = commandBuffer.makeBlitCommandEncoder()!
            blit.copy(from: op.result!,
                      sourceSlice: 0, sourceLevel: 0,
                      sourceOrigin: MTLOrigin(x: 0, y: 0, z: 0),
                      sourceSize: texSize,
                      to: output,
                      destinationSlice: 0, destinationLevel: 0,
                      destinationOrigin: MTLOrigin(x: 0, y: 0, z: 0))
            blit.endEncoding()
            
            // Schedule presentation and completion of the command buffer:
            commandBuffer.addScheduledHandler { _ in
                scheduledHandler()
            }
            commandBuffer.addCompletedHandler { _ in
                self.semaphore.signal()
            }
            commandBuffer.commit()
        }
        
        // Set new phase:
        self.phase = .render
    }
    
    /// Release any data associated with the current frame.
    public func endFrame() {
        guard self.layer != nil else { return }
        guard self.renderTarget != nil else { return }
        assert(self.phase == .render, "Cannot end a frame with phase \(self.phase)!")
        
        // Perform actions:
        self.updateShape.components = [] // clear
        self.frameTime = 0.0
        
        // Set new phase:
        self.phase = .ended
    }
    
    /// Returns the bounds of the update region that contains all pixels that
    /// will be rendered by the current frame.
    public var updateBounds: CGRect {
        return self.updateShape.boundingBox
    }
    
    /// Adds the rectangle to the update region of the current frame.
    public func addUpdate(_ rect: CGRect) {
        self.updateShape.components.append(rect)
    }
    
    /// The time at which the next update should happen. If infinite, no update
    /// needs to be scheduled yet. If nextFrameTime is the current frame time,
    /// a continuous animation is running and an update should be scheduled after
    /// an appropriate delay.
    public func nextFrameTime() -> TimeInterval {
        return .infinity
    }
}
