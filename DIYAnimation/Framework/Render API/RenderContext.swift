import Foundation

extension Render {
    
    ///
    internal final class Context: RenderValue {
        
        /// The context reference.
        internal var context: Reference<Context>
        
        ///
        internal var layers: [Reference<Layer>: Layer] = [:]
        
        ///
        internal var animations: [Reference<Animation>: Animation] = [:]
        
        ///
        internal static var allContexts = [Int: Weak<Context>]()
        
        ///
        internal static var contextLock = Lock() // TODO: lookup should lock allContexts against this!
        
        ///
        
    }
}
