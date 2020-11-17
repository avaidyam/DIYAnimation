
///
public class View {
	
	// 1. real displays = [WS] one overlay CGSWindow per CGDisplay
	// 2. virtual displays = [WS] REQUEST one overlay CGSSpace per CGSWindow
	// 3. CA-bridged = [NO] CALayer subclass + renderer
	
}

/*
#if canImport(MetalKit)
import MetalKit
extension Renderer: MTKViewDelegate {
    
    /// Convenience to bind a `Renderer` to an `MTKView`.
    public func configure(for view: MTKView) {
        view.device = self.device
        view.delegate = self
        view.colorPixelFormat = .bgra8Unorm
        view.depthStencilPixelFormat = .depth16Unorm
        view.colorspace = CGColorSpaceCreateDeviceRGB()
        view.layer?.isOpaque = false
        view.isPaused = false
        view.framebufferOnly = false
        self.mtkView(view, drawableSizeWillChange: view.drawableSize)
    }
    
    /// Adjusts the `bounds` of the receiver.
    public func mtkView(_ view: MTKView, drawableSizeWillChange size: CGSize) {
        self.bounds = CGRect(origin: .zero, size: size)
    }
    
    /// Renders a frame into the `currentDrawable` at the current media time.
    public func draw(in view: MTKView) {
        let drawable = view.currentDrawable!
        
        self.renderTarget = drawable.texture
        self.beginFrame(atTime: CurrentMediaTime())
        self.render { drawable.present() }
        self.endFrame()
    }
}
#endif
*/
