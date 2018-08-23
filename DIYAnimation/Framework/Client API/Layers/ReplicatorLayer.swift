import Foundation

/// A layer that creates a specified number of sublayer copies with varying
/// geometric, temporal, and color transformations.
///
/// You can use a `ReplicatorLayer` object to build complex layouts based on a
/// single source layer that is replicated with transformation rules that can
/// affect the position, rotation color, and time.
///
/// **Note:** The `ReplicatorLayer` implementation of `hitTest(_:)` currently
/// tests only the first instance of z replicator layer's sublayers. This may
/// change in the future.
public class ReplicatorLayer: Layer {
    
    //
    
}
