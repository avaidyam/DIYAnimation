import Foundation

/// A layer that displays scrollable content larger than its own bounds.
///
/// The `ScrollLayer` class is a subclass of `Layer` that simplifies displaying
/// a portion of a layer. The extent of the scrollable area of the `ScrollLayer`
/// is defined by the layout of its sublayers. The visible portion of the layer
/// content is set by specifying the origin as a point or a rectangular area of
/// the contents to be displayed. `ScrollLayer` does not provide keyboard or
/// mouse event-handling, nor does it provide visible scrollers.
public class ScrollLayer: Layer {
    
    ///
    public enum ScrollMode {
        
        /// The receiver is unable to scroll.
        case none
        
        /// The receiver is able to scroll horizontally.
        case horizontally
        
        /// The receiver is able to scroll vertically.
        case vertically
        
        /// The receiver is able to scroll both horizontally and vertically.
        case both
    }
    
    /// Defines the axes in which the layer may be scrolled.
    public var scrollMode: ScrollMode = .both
	
	// TODO: masksToBounds = true by default
    
    /// Changes the origin of the receiver to the specified point.
    public func scroll(to point: CGPoint) {
		var value = self.bounds
		if self.scrollMode == .horizontally || self.scrollMode == .both {
			value.origin.x = point.x
		}
		if self.scrollMode == .vertically || self.scrollMode == .both {
			value.origin.y = point.y
		}
		self.bounds = value
    }
    
    /// Scroll the contents of the receiver to ensure that the rectangle is visible.
    public func scroll(to rect: CGRect) {
		guard !rect.contains(self.bounds) else { return }
		
		var value = self.bounds
		if self.scrollMode == .horizontally || self.scrollMode == .both {
			value.origin.x = rect.origin.x // TODO
		}
		if self.scrollMode == .vertically || self.scrollMode == .both {
			value.origin.y = rect.origin.y // TODO
		}
		self.bounds = value
    }
	
	internal func visibleRect(of layer: Layer) -> CGRect {
		return layer.convert(layer.bounds, to: self).intersection(self.bounds)
	}
}
