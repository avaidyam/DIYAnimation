import Foundation

extension Render {
	    
	///
    internal final class ImageQueue: RenderValue {
        
        //
		private var flags: Int {
			return 0 // get from shmem -> flags
		}
		
		internal init(_ shmem: SharedMemory) {
			// retain shmem
		}
		
		deinit {
			// global list being foreach released?
			// texture release?
			// release all registered buffers?
		}
        
		///
		func flush() {
			
		}
		
		///
		func flushCache() {
			
		}
		
		///
		func update(_ a: Render.Context, _ b: Render.Context, _ c: Double, _ d: Float, _ e: [Render.Timing], _ f: Render.Update) {
			//
		}
    }
}
