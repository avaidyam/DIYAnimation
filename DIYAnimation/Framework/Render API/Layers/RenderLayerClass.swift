import Foundation

extension Render {
    
    /// Switch inheritance into composition for internally well-known layer types.
    internal class LayerClass: RenderValue {
        
        ///
        func commit(layer: Layer, context: Context, handle: Handle) {
            fatalError("LayerSubclass is an abstract class!")
        }
        
        ///
        func update(layer: Layer, at time: TimeInterval) {
            fatalError("LayerSubclass is an abstract class!")
        }
        
        ///
        func hitTest(layer: Layer, at point: CGPoint) -> Bool {
            fatalError("LayerSubclass is an abstract class!")
        }
        
        // TODO: why?
        //
        // func hasDepth() -> Bool {}
        // func getBounds() -> Bounds {}
        // func getVolume() -> Volume {}
    }
    
    ///
    internal final class ShapeLayer: LayerClass {
        // fill/stroke/dash/path stuff
    }
    
    ///
    internal final class GradientLayer: LayerClass {
        //image()
    }
    
    ///
    internal final class LayerHost: LayerClass {
        
        ///
        func willCommit(context: Context) {
            //
        }
        
        ///
        func didCommit(context: Context, for: Context, _ value: Bool) {
            //
        }
        
        ///
        override func commit(layer: Layer, context: Context, handle: Handle) {
            // custom!
        }
    }
    
    ///
    internal final class ReplicatorLayer: LayerClass {
        //instance transform stuff
        //global func prepare_replicator(globalstate, localstate, replicatorlayer)
    }
}
