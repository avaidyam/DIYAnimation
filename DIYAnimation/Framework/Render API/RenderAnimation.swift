import Foundation

extension Render {
    
    ///
    internal class Animation: RenderValue {
        
        /// The parent context reference.
        internal var context: Reference<Context>
        
        /// The animation object reference.
        internal var animation: Reference<Animation>
        
        ///
        internal final class Property: Animation {
            
        }
        
        ///
        internal final class Basic: Animation {
            
        }
        
        ///
        internal final class Keyframe: Animation {
            
        }
        
        ///
        internal final class Group: Animation {
            
        }
        
        ///
        internal final class Transition: Animation {
            
        }
    }
}
