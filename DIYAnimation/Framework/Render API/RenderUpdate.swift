import Foundation

extension Render {
    
    /// Update!
    ///
    /// 1. add contexts
    /// 2. prepare layers
    /// 3. convert to layer nodes
    internal final class Update: RenderValue {
        
        /// The context reference.
        internal var contexts: [Weak<Context>] = []
        
        ///
        internal var shape: Shape = Shape()
        
        //
        
    }
}
