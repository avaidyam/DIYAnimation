import Foundation

// TODO: Not sure how to emit keypath action for "transform.rotate.z" if a func is applied?

///
public struct ValueFunction {
    
    ///
    public enum Name {
        
        /// The `rotate' function takes three input values and constructs a
        /// 4x4 matrix representing the corresponding rotation matrix.
        case rotate
        
        /// The `rotateX', `rotateY', `rotateZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding rotation
        /// matrix.
        case rotateX
        
        /// The `rotateX', `rotateY', `rotateZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding rotation
        /// matrix.
        case rotateY
        
        /// The `rotateX', `rotateY', `rotateZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding rotation
        /// matrix.
        case rotateZ
        
        /// The `scale' function takes three input values and constructs a
        /// 4x4 matrix representing the corresponding scale matrix.
        case scale
        
        /// The `scaleX', `scaleY', `scaleZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding scaling
        /// matrix.
        case scaleX
        
        /// The `scaleX', `scaleY', `scaleZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding scaling
        /// matrix.
        case scaleY
        
        /// The `scaleX', `scaleY', `scaleZ' functions take a single input value
        /// and construct a 4x4 matrix representing the corresponding scaling
        /// matrix.
        case scaleZ
        
        /// The `translate' function takes three input values and constructs a
        /// 4x4 matrix representing the corresponding scale matrix.
        case translate
        
        /// The `translateX', `translateY', `translateZ' functions take a single
        /// input value and construct a 4x4 matrix representing the corresponding
        /// translation matrix.
        case translateX
        
        /// The `translateX', `translateY', `translateZ' functions take a single
        /// input value and construct a 4x4 matrix representing the corresponding
        /// translation matrix.
        case translateY
        
        /// The `translateX', `translateY', `translateZ' functions take a single
        /// input value and construct a 4x4 matrix representing the corresponding
        /// translation matrix.
        case translateZ
    }
    
    ///
    public let name: Name
    
    ///
    public init(name: Name) {
        self.name = name
    }
}

internal extension ValueFunction {
    
    // props: inputCount, outputCount
    
    ///
	func apply(_ value: Animatable) -> Animatable {
        /*
        switch self.name {
        case .rotate:
            guard let value = value as? [CGFloat],
                value.count == 3 else { break }
            break // todo
        case .rotateX:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .rotateY:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .rotateZ:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .scale:
            guard let value = value as? [CGFloat],
                value.count == 3 else { break }
            break // todo
        case .scaleX:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .scaleY:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .scaleZ:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .translate:
            guard let value = value as? [CGFloat],
                value.count == 3 else { break }
            break // todo
        case .translateX:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .translateY:
            guard let value = value as? CGFloat else { break }
            break // todo
        case .translateZ:
            guard let value = value as? CGFloat else { break }
            break // todo
        }
        */
        return value
    }
}
