import Foundation
import Metal
import CoreImage
import MetalPerformanceShaders

// TODO ImagingNodes: Filter, Composite, Shadow, Mesh, Blend, MotionBlur, Quad,
//                    Backdrop, Mask, Layer, Cache, Transition
//
// TODO: depth buffer!
//
// TODO: instead of recursion, dispatch parallel or GPU the tree visits

/// Describes, encodes, and emits to a texture a single render operation.
internal class RenderOp {
    
    /// Describes the render state used by any `RenderOp`.
    internal final class State {
        
        /// Container struct to hold all the various pipeline and sampler states used.
        internal struct Pipeline {
            fileprivate var composite: MTLRenderPipelineState!
            fileprivate var background: MTLRenderPipelineState!
            fileprivate var contents: MTLRenderPipelineState!
            fileprivate var border: MTLRenderPipelineState!
            fileprivate var shadow: MTLRenderPipelineState!
            fileprivate var mask: MTLComputePipelineState!
            
            fileprivate var linear_linearSampler: MTLSamplerState!
            fileprivate var linear_nearestSampler: MTLSamplerState!
            fileprivate var nearest_linearSampler: MTLSamplerState!
            fileprivate var nearest_nearestSampler: MTLSamplerState!
            fileprivate var trilinear_linearSampler: MTLSamplerState!
            fileprivate var trilinear_nearestSampler: MTLSamplerState!
            
            fileprivate var depthState: MTLDepthStencilState!
        }
        
        /// The stack of textures currently used.
        fileprivate var textureStack: [MTLTexture] = []
        
        /// The last texture popped off of the `textureStack`.
        fileprivate var lastTexture: MTLTexture? = nil
        
        /// The stack of mask boundaries corresponding to `textureStack`.
        /// Mask boundaries indicate start-points for flatten operations.
        fileprivate var boundaries: [Int] = []
        
        /// The current encoder that corresponds to the topmost texture, if any.
        fileprivate weak var encoder: MTLRenderCommandEncoder? = nil
        
        /// The command buffer to encode all operations into.
        fileprivate weak var command: MTLCommandBuffer? = nil
        
        /// Contains the pipeline used by the `RenderOp` subclasses.
        /// Create and cache this object until the `MTLDevice` changes.
        fileprivate var pipeline: Pipeline? = nil
        
        /// The Core Image context used by `FilterOp` et al.
        fileprivate var ciContext: CIContext? = nil
        
        /// The global scene viewport matrix (in MVP terms).
        fileprivate var viewport: MTLBuffer? = nil
        
        /// Creates a new `RenderOp.State`.
        /// Create and cache the `Pipeline` until the `MTLDevice` changes.
        internal init(_ command: MTLCommandBuffer,
                      _ ciContext: CIContext,
                      _ pipeline: Pipeline,
                      _ viewport: float4x4)
        {
            self.command = command
            self.ciContext = ciContext
            self.pipeline = pipeline
            
            // Create the global node's buffer ahead-of-time:
            let buffer = command.device.makeBuffer(length: MemoryLayout<GlobalNode>.size,
                                                   options: .storageModeManaged)!
            let ptr = buffer.contents().bindMemory(to: GlobalNode.self, capacity: 1)
            defer { buffer.didModifyRange(0..<buffer.length) }
            var g = GlobalNode()
            g.transform = viewport
            ptr.pointee = g
            self.viewport = buffer
        }
    }
    
    /// The sequence of operations to be executed by the receiver.
    private var ops: [RenderOp] = []
    
    /// The resultant texture from the operations executed by the receiver.
    internal var result: MTLTexture? = nil
    
    /// This method may be overridden by subclasses or ignored.
    fileprivate init() {
        // no-op
    }
    
    /// Create a new `RenderOp` executing a sequence of operations that correspond
    /// to rendering `layer` into a texture of size `size`.
    internal convenience init(for layer: Layer, with device: MTLDevice, size: MTLSize,
                  _ handler: (Layer) -> (LayerNode))
    {
        // Perform an action before and after visiting the layer's sublayers.
        // State from the pre-visit is transferred to the post-visit handler.
        func visit<T>(_ root: Layer, preVisit: (Layer) -> (T), postVisit: (Layer, T) -> ()) {
            let t = preVisit(root)
            for x in root.orderedSublayers() /* reverse z-order */ {
                visit(x, preVisit: preVisit, postVisit: postVisit)
            }
            if let r = root.mask, !root._isMask {
                visit(r, preVisit: preVisit, postVisit: postVisit)
            }
            postVisit(root, t)
        }
        
        // TODO: only apply layer transforms after composite if offscreen
        
        // Begin tracking all nodes in a pass-global buffer:
        var vendor = (0..<Int.max).makeIterator()
        let count = layer.sublayerCount() + 1
        let buffer = device.makeBuffer(length: count * MemoryLayout<LayerNode>.size,
                                       options: .storageModeManaged)!
        let ptr = buffer.contents().bindMemory(to: LayerNode.self, capacity: count)
        defer { buffer.didModifyRange(0..<buffer.length) }
        
        // Visit all layers in this tree and transform them into render ops:
        var ops = [RenderOp]()
        ops.append(PushTextureOp(size))
        ops.append(AttachBufferOp(buffer))
        visit(layer, preVisit: { l -> (Int, Bool) in
            
            // Bind the buffer memory to the layer node:
            let id = vendor.next()!
            ptr.advanced(by: id).pointee = handler(l)
            let offscreen = l.needsOffscreenRendering
            
            // Queue all the pre-sublayer-visit operations:
            let bf = l.backgroundFilters?.compactMap { $0 as? CIFilter } ?? []
            if bf.count > 0 {
                ops.append(FlattenOp())
                ops.append(FilterOp(bf))
                //
                // TODO: bg_filter is also affected by mask!
                //
                ops.append(AttachBufferOp(buffer))
            }
            if offscreen {
                ops.append(PushTextureOp(size))
                ops.append(AttachBufferOp(buffer))
            }
            ops.append(AttachLayerOp(id))
            if l.backgroundColor.alpha > 0.0 {
                ops.append(BackgroundOp())
            }
            if let c = l.contents?.texture(device) {
                ops.append(ContentsOp(c, (l.minificationFilter,
                                          l.magnificationFilter)))
            }
            
            return (id, offscreen)
        }, postVisit: { l, _x in let (id, offscreen) = _x
            
            // Queue all the post-sublayer-visit operations:
            ops.append(AttachLayerOp(id))
            if l.borderWidth > 0.0 && l.borderColor.alpha > 0.0 {
                ops.append(BorderOp())
            }
            if offscreen {
                let lf = l.filters?.compactMap { $0 as? CIFilter } ?? []
                if lf.count > 0 {
                    ops.append(FilterOp(lf, reattach: false))
                }
                ops.append(PopTextureOp())
                if let cf = l.compositingFilter as? CIFilter {
                    ops.append(FlattenOp())
                    ops.append(CompositeFilterOp(cf))
                } else if l.shadowOpacity > 0.0 {
                    //
                    // TODO: shadow must match layer transform!
                    //
                    ops.append(ShadowOp(sigma: Float(l.shadowRadius)))
                    ops.append(AttachBufferOp(buffer))
                    ops.append(AttachLayerOp(id))
                    ops.append(CompositeShadowOp())
                } else {
                    ops.append(CompositeOp())
                }
                if l.masksToBounds || l.mask != nil {
                    // TODO: compositeop should support mask (multiple!) inputs
                    //
                    // TODO: if masking needed + c_filter, filter in-place
                    // without composite, run separate compositeop
                    //
                    // order: draw mask layer -> tex, then draw bounds -> tex
                    // NOTE: mask cannot have another mask on it
                    //
                    
                    //ops.append(MaskOp())
                }
                ops.append(AttachBufferOp(buffer))
            }
        })
        ops.append(PopTextureOp(attach: false))
        
        self.init()
        self.ops = ops
    }
    
    /// The implementation for `RenderOp` executes its sequence of operations
    /// and retrieves the resultant texture. Must be overridden by subclasses.
    internal func perform(_ state: RenderOp.State) {
        self.ops.forEach { $0.perform(state) }
        
        // Ensure all stack operations are balanced before finishing:
        assert(state.textureStack.count == 0 &&
            state.lastTexture != nil &&
            state.boundaries.count == 0,
               "The texture stack was not balanced!")
        
        self.result = state.lastTexture!
        state.lastTexture = nil
    }
}

/// Attaches the shader buffer to the pipeline. Must be performed after any
/// texture stack modification, if further rendering is required.
///
/// - **state modified:** `encoder.buffer`
fileprivate class AttachBufferOp: RenderOp {
    fileprivate let buffer: MTLBuffer
    fileprivate init(_ buffer: MTLBuffer) {
        self.buffer = buffer
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        state.encoder?.setVertexBuffer(state.viewport!, offset: 0, at: .globalNode)
        state.encoder?.setVertexBuffer(self.buffer, offset: 0, at: .layerNode)
        state.encoder?.setFragmentBuffer(self.buffer, offset: 0, at: .layerNode)
    }
}

/// Sets the layer node to be rendered in the pipeline. Must be performed after
/// any sublayer traversal.
///
/// - **state modified:** `encoder.bufferOffset`
fileprivate class AttachLayerOp: RenderOp {
    fileprivate let node: Int
    fileprivate init(_ node: Int) {
        self.node = node
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        let _len = MemoryLayout<LayerNode>.size
        state.encoder!.setVertexBufferOffset(self.node * _len, at: .layerNode)
        state.encoder!.setFragmentBufferOffset(self.node * _len, at: .layerNode)
    }
}

/// Draws the layer background.
///
/// - **state modified:** `encoder`
fileprivate class BackgroundOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        state.encoder!.setRenderPipelineState(state.pipeline!.background)
        state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws the layer border.
///
/// - **state modified:** `encoder`
fileprivate class BorderOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        state.encoder!.setRenderPipelineState(state.pipeline!.border)
        state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws the layer contents.
///
/// - **state modified:** `encoder`
fileprivate class ContentsOp: RenderOp {
    fileprivate typealias SamplerType = (Layer.ContentsFilter, Layer.ContentsFilter)
    fileprivate let texture: () -> MTLTexture?
    fileprivate let type: SamplerType
    fileprivate init(_ texture: @autoclosure @escaping () -> MTLTexture?,
                     _ type: SamplerType)
    {
        self.texture = texture
        self.type = type
    }
    
    fileprivate override func perform(_ state: RenderOp.State) {
        state.encoder!.setRenderPipelineState(state.pipeline!.contents)
        state.encoder!.setFragmentTexture(self.texture(), at: .contents)
        state.encoder!.setFragmentSamplerState(state.sampler(self.type),
                                               at: .contents)
        state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Draws the layer shadow, using the last popped texture from the stack.
/// This operation **MUST** be followed by buffer and layer attachment, and then
/// a `CompositeShadowOp`, or the results of this operation are voided.
///
/// - **state modified:** `encoder`, `textureStack`, `lastTexture`
fileprivate class ShadowOp: RenderOp {
    fileprivate let sigma: Float
    fileprivate init(sigma: Float) {
        self.sigma = sigma
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        let source = state.lastTexture!
        let destination = state.textureStack.last!
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        
        // High performance gaussian blurs for shadows:
        //   1. Determine sigma = shadowRadius / 2.0
        //   2. Determine alpha = shadowColor.a * shadowOpacity
        //   3. If sigma == 0, discard operation
        //   4. Build piece-wise quadratic convolution
        //        1. let d = floor(s * 3*sqrt(2*pi)/4 + 0.5)
        //        2. if d is odd:
        //             a. 3 box-blurs of size 'd', centered on p.
        //        3. if d is even, 2 box-blurs of size 'd'
        //             a. first: centered on avg(p, p.x -= 1)
        //             b. second: centered on avg(p, p.x += 1)
        //             c. third: size 'd+1', centered on p.
        //   5. Use half-precision float16, applying only to A channel
        //   6. After convolve, set RGB channels = shadowColor.rgb
        //   7. Composite pixel at p.xy += shadowOffset.xy
        //
        // TODO: need convolution matrix compute kernel!
        
        // Encode a high performance gaussian blur:
        let shadow = state.newTexture(destination.width, destination.height)
        state.textureStack.append(shadow)
        MPSImageGaussianBlur(device: state.command!.device, sigma: 10.0)
            .encode(commandBuffer: state.command!,
                    sourceTexture: source,
                    destinationTexture: shadow)
        
        // Restore the encoder state to the destination:
        state.newRenderPass(for: destination)
    }
}

/// Composite the source texture atop the blur shadow texture atop the destination.
///
/// - **state modified:** `textureStack`, `lastTexture`
fileprivate class CompositeShadowOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        let source = state.lastTexture!
        state.lastTexture = nil
        let shadow = state.textureStack.popLast()!
        
        state.encoder!.setRenderPipelineState(state.pipeline!.shadow)
        state.encoder!.setFragmentTexture(source, at: .composite)
        state.encoder!.setFragmentTexture(shadow, at: .shadow)
        state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
    }
}

/// Masks the current texture with the last popped texture's alpha channel, while
/// drawing into the texture directly below. If `targetSelf` is `true`, the last
/// popped texture is masked using the selected layer's shape.
///
/// - **state modified:**
fileprivate class MaskOp: RenderOp {
    fileprivate let targetSelf: Bool
    fileprivate init(self targetSelf: Bool = true) {
        self.targetSelf = targetSelf
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        
    }
}

/// Applies a filter "in-place" to the topmost texture on the stack.
///
/// - **state modified:** `encoder`, `textureStack`
fileprivate class FilterOp: RenderOp {
    fileprivate let filters: [CIFilter]
    fileprivate let attach: Bool
    fileprivate init(_ filters: [CIFilter], reattach: Bool = true) {
        self.filters = filters
        self.attach = reattach
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        let tex = state.textureStack.last!
        
        // Chain the input image -> filter[n]... -> output image:
        let input = CIImage(mtlTexture: tex, options: [
            kCIImageColorSpace: CGColorSpaceCreateDeviceRGB()
        ])!
        if self.filters[0].inputKeys.contains(kCIInputImageKey) {
            self.filters[0].setValue(input, forKey: kCIInputImageKey)
        }
        for i in 0..<self.filters.count - 1 /*all but the last element!*/ {
            let out = self.filters[i].value(forKey: kCIOutputImageKey)
            if self.filters[i + 1].inputKeys.contains(kCIInputImageKey) {
                self.filters[i + 1].setValue(out, forKey: kCIInputImageKey)
            }
        }
        let output = self.filters.last!.value(forKey: kCIOutputImageKey)! as! CIImage
        
        // Create the backing texture and swap the topmost one out:
        let texture = state.newTexture(tex.width, tex.height)
        state.textureStack[state.textureStack.count - 1] = texture
        
        // Render to the texture:
        let sz = CGRect(x: 0, y: 0, width: tex.width, height: tex.height)
        state.ciContext!.render(output, to: texture, commandBuffer: state.command!,
                                bounds: sz, colorSpace: CGColorSpaceCreateDeviceRGB())
        
        // Reset the filter objects when rendering is done:
        for f in self.filters {
            if f.inputKeys.contains(kCIInputImageKey) {
                f.setValue(nil, forKey: kCIInputImageKey)
            }
        }
        
        // Begin the new encoder session:
        if self.attach {
            state.newRenderPass(for: texture)
        }
    }
}

/// Applies a filter between the topmost texture on the stack and the last-popped
/// texture. If `replace` is true, the resultant texture will replace the topmost
/// texture on the stack; otherwise, it will replace the last-popped texture.
///
/// - **state modified:** `encoder`, `textureStack`, `lastTexture`
fileprivate class CompositeFilterOp: RenderOp {
    fileprivate let filter: CIFilter
    fileprivate let attach: Bool
    fileprivate let replace: Bool
    fileprivate init(_ filter: CIFilter, attach: Bool = true, replace: Bool = true) {
        self.filter = filter
        self.attach = attach
        self.replace = replace
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        assert(state.textureStack.count >= 1 && state.lastTexture != nil,
               "`CompositeFilterOp` requires AT LEAST two textures to operate on!")
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        
        // Apply the two input images and retrieve the output image.
        let tex1 = state.textureStack.last!
        let tex2 = state.lastTexture!
        let input = CIImage(mtlTexture: tex2, options: [
            kCIImageColorSpace: CGColorSpaceCreateDeviceRGB()
        ])!
        let background = CIImage(mtlTexture: tex1, options: [
            kCIImageColorSpace: CGColorSpaceCreateDeviceRGB()
        ])!
        
        // Set the filter values and get the output image:
        if self.filter.inputKeys.contains(kCIInputImageKey) {
            self.filter.setValue(input, forKey: kCIInputImageKey)
        }
        if self.filter.inputKeys.contains(kCIInputBackgroundImageKey) {
            self.filter.setValue(background, forKey: kCIInputBackgroundImageKey)
        }
        let output = self.filter.value(forKey: kCIOutputImageKey)! as! CIImage
        
        // Render to a new texture and swap it out:
        let texture = state.newTexture(tex2.width, tex2.height)
        let sz = CGRect(x: 0, y: 0, width: tex2.width, height: tex2.height)
        state.ciContext!.render(output, to: texture, commandBuffer: state.command!,
                                bounds: sz, colorSpace: CGColorSpaceCreateDeviceRGB())
        if self.replace {
            state.textureStack[state.textureStack.count - 1] = texture
        } else {
            state.lastTexture = texture
        }
        
        // Reset the filter objects when rendering is done:
        if self.filter.inputKeys.contains(kCIInputImageKey) {
            self.filter.setValue(nil, forKey: kCIInputImageKey)
        }
        if self.filter.inputKeys.contains(kCIInputBackgroundImageKey) {
            self.filter.setValue(nil, forKey: kCIInputBackgroundImageKey)
        }
        
        if self.attach {
            state.newRenderPass(for: state.textureStack.last!)
        }
    }
}

/// This texture is then composited onto the current texture.
///
/// - **state modified:** `encoder`, `textureStack`
fileprivate class PushTextureOp: RenderOp {
    fileprivate let size: MTLSize
    fileprivate init(_ size: MTLSize) {
        self.size = size
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        
        // Create the new texture and render pass:
        let texture = state.newTexture(self.size.width, self.size.height)
        state.textureStack.append(texture)
        state.newRenderPass(for: texture, clear: true)
    }
}

/// Pops a texture from the stack.
///
/// - **state modified:** `encoder`, `textureStack`
fileprivate class PopTextureOp: RenderOp {
    fileprivate let attach: Bool
    fileprivate init(attach: Bool = true) {
        self.attach = attach
    }
    fileprivate override func perform(_ state: RenderOp.State) {
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        
        // Grab the source and destination:
        state.lastTexture = state.textureStack.popLast()!
        if let destination = state.textureStack.last, self.attach {
            state.newRenderPass(for: destination)
        }
    }
}

/// Inserts a texture boundary that limits texture flattening operations to the
/// currently topmost texture on the stack.
///
/// - **state modified:** `boundaries`
fileprivate class PushBoundaryOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        state.boundaries.append(state.textureStack.count - 1)
    }
}

/// Removes a texture boundary; texture flattening operations are either limited
/// to the most recent boundary or to the bottom-most texture on the stack.
///
/// - **state modified:** `boundaries`
fileprivate class PopBoundaryOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        state.boundaries.removeLast()
    }
}

/// Composites the topmost texture on the stack to the one directly below it.
///
/// - **state modified:** `lastTexture`
fileprivate class CompositeOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        state.encoder!.setRenderPipelineState(state.pipeline!.composite)
        state.encoder!.setFragmentTexture(state.lastTexture!, at: .composite)
        state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        state.lastTexture = nil
    }
}

/// Flattens all textures currently on the stack into one, in reverse order.
///
/// - **state modified:** `encoder`, `textureStack`
fileprivate class FlattenOp: RenderOp {
    fileprivate override func perform(_ state: RenderOp.State) {
        
        // End any existing encoder session:
        state.encoder?.endEncoding()
        state.encoder = nil
        //state.lastTexture = nil // FIXME: maybe not?
        
        // Begin the new encoder session:
        let idx = state.boundaries.last ?? 0
        state.newRenderPass(for: state.textureStack[idx])
        state.encoder!.setRenderPipelineState(state.pipeline!.composite)
        
        // Run the composite shader for each texture going up the stack:
        for x in state.textureStack.dropFirst(idx + 1) {
            state.encoder!.setFragmentTexture(x, at: .composite)
            state.encoder!.drawPrimitives(type: .triangle, vertexStart: 0, vertexCount: 6)
        }
        state.textureStack.removeSubrange((idx + 1)...)
    }
}

//
//
//

extension Layer {
    
    /// Return whether the receiver requires offscreen rendering for complex effects.
    fileprivate var needsOffscreenRendering: Bool {
        return (self.filters?.count ?? 0 > 0) ||
            self.compositingFilter != nil ||
            self.masksToBounds ||
            self.mask != nil ||
            self.shadowOpacity > 0.0
    }
}

extension Drawable {
    
    ///
    func texture(_ device: MTLDevice) -> MTLTexture? {
        var tex: MTLTexture? = nil
        if let x = (self as? RenderConvertible)?.renderValue as? RenderDrawable {
            tex = x.texture(device)
        } else if let x = self as? RenderDrawable {
            tex = x.texture(device)
        }
        return tex
    }
}

fileprivate extension RenderOp.State {
    
    /// Convenience function to create a new unmanaged texture.
    fileprivate func newTexture(_ width: Int, _ height: Int) -> MTLTexture {
        let desc = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .bgra8Unorm,
                                                            width: width, height: height,
                                                            mipmapped: false)
        desc.usage = [.renderTarget, .shaderRead, .shaderWrite]
        return self.command!.device.makeTexture(descriptor: desc)!
    }
    
    /// Convenience function to create a new depth store.
    fileprivate func newDepth(_ width: Int, _ height: Int) -> MTLRenderPassDepthAttachmentDescriptor {
        let t = MTLTextureDescriptor.texture2DDescriptor(pixelFormat: .depth16Unorm,
                                                         width: width, height: height,
                                                         mipmapped: false)
        t.storageMode = .private
        t.usage = [.renderTarget, .shaderRead]
        let x = MTLRenderPassDepthAttachmentDescriptor()
        x.texture = self.command!.device.makeTexture(descriptor: t)!
        x.loadAction = .clear
        x.storeAction = .dontCare
        x.clearDepth = 0.0
        return x
    }
    
    /// Convenience function to create a new render pass encoder in the state.
    fileprivate func newRenderPass(for texture: MTLTexture, clear: Bool = false) {
        let pass = MTLRenderPassDescriptor()
        pass.colorAttachments[0].loadAction = clear ? .clear : .dontCare
        pass.colorAttachments[0].storeAction = .store
        pass.colorAttachments[0].clearColor = MTLClearColorMake(0, 0, 0, 0)
        pass.colorAttachments[0].texture = texture
        //pass.depthAttachment = self.newDepth(texture.width, texture.height)
        self.encoder = self.command!.makeRenderCommandEncoder(descriptor: pass)!
        //self.encoder?.setDepthStencilState(self.pipeline!.depthState)
    }
    
    /// Convenience function to create the corresponding sampler state for a layer.
    fileprivate func sampler(_ params: ContentsOp.SamplerType) -> MTLSamplerState {
        switch params {
        case (.linear, .linear): return self.pipeline!.linear_linearSampler
        case (.linear, .nearest): return self.pipeline!.linear_nearestSampler
        case (.nearest, .linear): return self.pipeline!.nearest_linearSampler
        case (.nearest, .nearest): return self.pipeline!.nearest_nearestSampler
        case (.trilinear, .linear): return self.pipeline!.trilinear_linearSampler
        case (.trilinear, .nearest): return self.pipeline!.trilinear_nearestSampler
            
        // The following cases acknowledge that `trilinear` `magFilter` is not supported:
        case (.linear, .trilinear): return self.pipeline!.linear_linearSampler
        case (.nearest, .trilinear): return self.pipeline!.nearest_linearSampler
        case (.trilinear, .trilinear): return self.pipeline!.trilinear_linearSampler
        }
    }
}

internal extension RenderOp.State.Pipeline {
    
    /// Creates all the pipeline states used in rendering the scene.
    internal static func create(_ device: MTLDevice) -> RenderOp.State.Pipeline {
        var pipeline = RenderOp.State.Pipeline()
        let pipeDesc = MTLRenderPipelineDescriptor()
        //pipeDesc.depthAttachmentPixelFormat = .depth16Unorm
        pipeDesc.colorAttachments[0].pixelFormat = .bgra8Unorm
        pipeDesc.colorAttachments[0].isBlendingEnabled = true
        pipeDesc.colorAttachments[0].rgbBlendOperation = .add
        pipeDesc.colorAttachments[0].alphaBlendOperation = .add
        pipeDesc.colorAttachments[0].sourceRGBBlendFactor = .one
        pipeDesc.colorAttachments[0].sourceAlphaBlendFactor = .one
        pipeDesc.colorAttachments[0].destinationRGBBlendFactor = .oneMinusSourceAlpha
        pipeDesc.colorAttachments[0].destinationAlphaBlendFactor = .oneMinusSourceAlpha
        let lib = device.makeDefaultLibrary()!
        
        // Create the layer render pipelines:
        do {
            pipeDesc.vertexFunction = lib.makeFunction(name: "scene_emit_quad")
            pipeDesc.fragmentFunction = lib.makeFunction(name: "scene_composite")
            pipeline.composite = try device.makeRenderPipelineState(descriptor: pipeDesc)
            pipeDesc.fragmentFunction = lib.makeFunction(name: "scene_shadow")
            pipeline.shadow = try device.makeRenderPipelineState(descriptor: pipeDesc)
            pipeDesc.vertexFunction = lib.makeFunction(name: "layer_emit_quad")
            pipeDesc.fragmentFunction = lib.makeFunction(name: "layer_background")
            pipeline.background = try device.makeRenderPipelineState(descriptor: pipeDesc)
            pipeDesc.fragmentFunction = lib.makeFunction(name: "layer_contents")
            pipeline.contents = try device.makeRenderPipelineState(descriptor: pipeDesc)
            pipeDesc.fragmentFunction = lib.makeFunction(name: "layer_border")
            pipeline.border = try device.makeRenderPipelineState(descriptor: pipeDesc)
        } catch {
            fatalError("Could not create layer rendering pipelines: \(error)")
        }
        
        // Create sampler states:
        do { // linear, linear
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .linear
            sdesc.magFilter = .linear
            sdesc.mipFilter = .notMipmapped
            pipeline.linear_linearSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        do { // linear, nearest
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .linear
            sdesc.magFilter = .nearest
            sdesc.mipFilter = .notMipmapped
            pipeline.linear_nearestSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        do { // nearest, linear
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .nearest
            sdesc.magFilter = .linear
            sdesc.mipFilter = .notMipmapped
            pipeline.nearest_linearSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        do { // nearest, nearest
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .nearest
            sdesc.magFilter = .nearest
            sdesc.mipFilter = .notMipmapped
            pipeline.nearest_nearestSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        do { // trilinear, linear
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .linear
            sdesc.magFilter = .linear
            sdesc.mipFilter = .linear
            pipeline.trilinear_linearSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        do { // trilinear, nearest
            let sdesc = MTLSamplerDescriptor()
            sdesc.minFilter = .linear
            sdesc.magFilter = .nearest
            sdesc.mipFilter = .linear
            pipeline.trilinear_nearestSampler = device.makeSamplerState(descriptor: sdesc)!
        }
        
        // Create depth buffer state:
        do {
            let desc = MTLDepthStencilDescriptor()
            desc.isDepthWriteEnabled = true
            desc.depthCompareFunction = .always
            pipeline.depthState = device.makeDepthStencilState(descriptor: desc)!
        }
        return pipeline
    }
}

/// Utilities to deal with `BufferIndex`, `TextureIndex`, and `SamplerIndex`.
extension MTLRenderCommandEncoder {
    @inline(__always)
    internal func setVertexBytes(_ bytes: UnsafeRawPointer, length: Int, at index: BufferIndex) {
        self.setVertexBytes(bytes, length: length, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setVertexBuffer(_ buffer: MTLBuffer?, offset: Int, at index: BufferIndex) {
        self.setVertexBuffer(buffer, offset: offset, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setVertexBufferOffset(_ offset: Int, at index: BufferIndex) {
        self.setVertexBufferOffset(offset, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setFragmentBuffer(_ buffer: MTLBuffer?, offset: Int, at index: BufferIndex) {
        self.setFragmentBuffer(buffer, offset: offset, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setFragmentBufferOffset(_ offset: Int, at index: BufferIndex) {
        self.setFragmentBufferOffset(offset, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setFragmentTexture(_ texture: MTLTexture?, at index: TextureIndex) {
        self.setFragmentTexture(texture, index: Int(index.rawValue))
    }
    @inline(__always)
    internal func setFragmentSamplerState(_ sampler: MTLSamplerState?, at index: SamplerIndex) {
        self.setFragmentSamplerState(sampler, index: Int(index.rawValue))
    }
}
