import Foundation

extension Render {
    
    /// Composes a render tree that mirrors the client-side layer-tree.
    internal final class Layer: RenderValue {
        
        /// The parent context reference.
        internal var context: Reference<Context>?
        
        /// The layer object reference.
        internal var layer: Reference<Layer>?
        
        ///
        internal var name: String?
        
        ///
        internal var timing: Timing?
        
        ///
        internal var animations: [Animation]?
        
        ///
        internal var sublayers: [Layer]?
        
        ///
        internal var mask: Layer?
        
        ///
        internal var position: SIMD3<Float>?
        
        ///
        internal var anchorPoint: SIMD3<Float>?
        
        ///
        internal var bounds: SIMD4<Float>?
        
        ///
        internal var cornerRadius: Float?
        
        ///
        internal var backgroundColor: SIMD4<Float>?
        
        ///
        //internal var backgroundPattern: CGPattern?
        
        ///
        internal var borderWidth: Float?
        
        ///
        internal var borderColor: SIMD4<Float>?
        
        ///
        //internal var borderPattern: CGPattern?
        
        ///
        internal var frameTransform: float4x4?
        
        ///
        internal var transform: float4x4?
        
        ///
        internal var contentsTransform: float4x4?
        
        ///
        internal var shadowOpacity: Float?
        
        ///
        internal var shadowRadius: SIMD2<Float>?
        
        ///
        internal var shadowOffset: SIMD2<Float>?
        
        ///
        internal var shadowColor: SIMD4<Float>?
        
        ///
        internal var mipBias: Float?
        
        
        //
        
        // copy()
        
        //
        
        // FUNC: ??? is_animating(double, float, double, float, double&)
        // FUNC: ??? append_contents_transform(transform&, bool, size, size&)
        // FUNC: ??? compute_contents_transform(gravity, rect, size, affineT)
        // FUNC: ??? layer_contents_transform(size&, affineT&)
        // FUNC: ??? compute_frame_transform(layer, transform&, float*, transform*)
        // FUNC: ??? compute_reflection_plane(float, float*)
        //
        // FUNC: ??? composite(layer *, ulong, bool) -> used for cube/page/etc transition, clones layer
        
    }
    
        
    
/*
backgroundColor:
        didSet {
            guard self.backgroundColor.pattern == nil else {
                fatalError("Layer does not support CGPattern-backed backgroundColor!")
            }
        }

borderColor:
        didSet {
            guard self.borderColor.pattern == nil else {
                fatalError("Layer does not support CGPattern-backed borderColor!")
            }
        }


contentsCenter:
        didSet {
            assert(self.contentsCenter.origin.x >= 0.0 &&
                   self.contentsCenter.origin.y >= 0.0 &&
                   self.contentsCenter.size.width <= 1.0 &&
                   self.contentsCenter.size.width <= 1.0,
                   "The contentsCenter must be normalized to a unit rectangle!")
        }

contentsRect:
        didSet {
            assert(self.contentsRect.origin.x >= 0.0 &&
                   self.contentsRect.origin.y >= 0.0 &&
                   self.contentsRect.size.width <= 1.0 &&
                   self.contentsRect.size.width <= 1.0,
                   "The contentsRect must be normalized to a unit rectangle!")
        }
*/
    
}

///
extension LayerNode {
    
    ///
    internal init(from layer2: Layer, at time: TimeInterval) {
        self.init()
        let layer = layer2.layer(at: time)
        
        /*var benchmark = CurrentMediaTime() * 1000 {
            didSet {
                print(benchmark - oldValue)
            }
        }*/
        
        self.position = SIMD2<Float>(layer.position)
        self.anchorPoint = SIMD2<Float>(layer.anchorPoint)
        self.bounds = SIMD4<Float>(layer.bounds)
        self.cornerRadius = Float(layer.cornerRadius)
        self.borderWidth = Float(layer.borderWidth)
        self.borderColor = SIMD4<Float>(layer.borderColor)
        self.backgroundColor = SIMD4<Float>(layer.backgroundColor)
        self.mipBias = Float(layer.minificationFilterBias)
        
        self.shadowOpacity = Float(layer.shadowOpacity)
        self.shadowRadius = Float(layer.shadowRadius)
        self.shadowOffset = SIMD2<Float>(layer.shadowOffset)
        self.shadowColor = SIMD4<Float>(layer.shadowColor)
        
        //print("convert: ", terminator: "")
        //benchmark = CurrentMediaTime() * 1000
        
        // transform:
        /*
        let value = Double((0.1 * time).truncatingRemainder(dividingBy: 1.0))
        let r1 = Transform3D.scale(x: sin(Float.pi * Float(value)),
                                   y: sin(Float.pi * Float(value))).m
        let r2 = Transform3D.rotation(angle: 2 * Float.pi * Float(value), z: 1).m
        let r3 = Transform3D.translation(x: Float(value) * 100,
                                         y: Float(value) * 100).m
        let transform = r3 * r2 * r1
        */
        let transform = (layer.transform ?? .identity).m
        
        //print("get_t: ", terminator: "")
        //benchmark = CurrentMediaTime() * 1000
        
        // fix transform!
        let pivot = self.position - SIMD2<Float>(self.bounds.z * 2.0 * (0.5 - self.anchorPoint.x),
												 self.bounds.w * 2.0 * (0.5 - self.anchorPoint.y))
        let forward = Transform3D.translation(x: pivot.x, y: pivot.y).m
        let backward = Transform3D.translation(x: -pivot.x, y: -pivot.y).m
        let bounds = Transform3D.scale(x: self.bounds.z, y: self.bounds.w).m
        
        //print("calc_t: ", terminator: "")
        //benchmark = CurrentMediaTime() * 1000
        
        // set transforms:
        self.transform = (forward * transform * backward) * (forward * bounds)
        self.contentsTransform = (forward * transform * backward) * (forward * bounds)
        
        //print("apply_t: ", terminator: "")
        //benchmark = CurrentMediaTime() * 1000
    }
}
