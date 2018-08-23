import Foundation.NSUUID

extension Render {
    
    private static var vendor = (100...Int.max).makeIterator()
    
    ///
    internal struct Reference<Type: RenderValue>: RenderValue {
        
        //
        private let value: Int
        
        ///
        internal init<T: RenderValue>(to parent: T) {
            // some kind of reparenting?
            
            self.value = Render.vendor.next()!
        }
    }
}
