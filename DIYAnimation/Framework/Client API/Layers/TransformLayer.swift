
/// Objects used to create true 3D layer hierarchies, rather than the flattened
/// hierarchy rendering model used by other `Layer` classes.
///
/// Unlike normal layers, transform layers do not flatten their sublayers into
/// the plane at `Z=0`. Due to this, they do not support many of the features of
/// the `Layer` class compositing model:
///
/// Only the sublayers of a transform layer are rendered. The `Layer` properties
/// that are rendered by a layer are ignored, including: `backgroundColor`,
/// `contents`, border style properties, stroke style properties, etc.
///
/// The properties that assume 2D image processing are also ignored, including:
/// `filters`, `backgroundFilters`, `compositingFilter`, `mask`, `masksToBounds`,
/// and shadow style properties.
///
/// The `opacity` property is applied to each sublayer individually, the
/// transform layer does not form a compositing group.
///
/// The `hitTest(_:)` method should never be called on a transform layer as they
/// do not have a 2D coordinate space into which the point can be mapped.
public class TransformLayer: Layer {
	
	// TODO: by default: _layer.setFlags(0x2000 /* do not flatten compositing group? */)
    // TODO: CAReplicatorLayer.preservesDepth also causes same flags to be set
}
