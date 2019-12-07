
// TODO: Append, Prepend, Concat w/ Point/Size, etc
// inverse, determinant

// TODO: Compose/Decompose don't correctly work as translated from WebCore!

internal enum AspectRatioType {
    case none
    case fitWidth
    case fitHeight
    case auto
}

internal extension CGAffineTransform {
    
    /// Create the transformation that pins a layer's image with its
    /// `contentsGravity`, `contentsCenter`, and `contentsRect`.
    ///
    /// Note: returns the `.identity` matrix if the `gravity` is `.resize`.
	static func apply(gravity: Layer.ContentsGravity, _ center: CGRect,
                               _ contentsRect: CGRect, _ layerBounds: CGRect,
                               _ imageSize: CGSize) -> CGAffineTransform
    {
        
        // Compute the adjusted image rect first:
        var imageRect = CGRect(origin: layerBounds.origin, size: imageSize)
        imageRect.size.width *= contentsRect.size.width
        imageRect.size.height *= contentsRect.size.height
        var aspect = AspectRatioType.none
        
        // Compute the gravity effect's rectangle, except for aspect ratio types:
        switch gravity {
        case .resize: return .identity
        case .resizeAspect: aspect = .fitWidth
        case .resizeAspectFill: aspect = .fitHeight
            
        case .bottomLeft: // (0.0, 0.0)
            break
        case .bottom: // (0.5, 0.0)
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width) / 2
        case .bottomRight: // (1.0, 0.0)
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width)
        case .left: // (0.0, 0.5)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height) / 2
            break
        case .center: // (0.5, 0.5)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height) / 2
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width) / 2
        case .right: // (1.0, 0.5)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height) / 2
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width)
        case .topLeft: // (0.0, 1.0)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height)
            break
        case .top: // (0.5, 1.0)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height)
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width) / 2
        case .topRight: // (1.0, 1.0)
            imageRect.origin.y -= (imageRect.size.height - layerBounds.size.height)
            imageRect.origin.x -= (imageRect.size.width - layerBounds.size.width)
        }
        
        // Return the snap transform:
        return CGAffineTransform.snap(from: layerBounds, to: imageRect,
                                      aspectRatio: aspect)
    }
    
    /// Create the transformation that converts `source` to `dest`, optionally
    /// keeping the aspect ratio.
	static func snap(from source: CGRect, to dest: CGRect,
                              aspectRatio: AspectRatioType = .none) -> CGAffineTransform
    {
        let axis = (source.width / source.height) > (dest.width / dest.height)
        
        let x = CGAffineTransform(translationX: -(source.midX - dest.midX),
                                  y: -(source.midY-dest.midY))
        switch aspectRatio {
        case .none:
            x.scaledBy(x: dest.width / source.width,
                       y: dest.height / source.height)
        case .fitHeight,
             .auto where axis:
            x.scaledBy(x: dest.height / source.height,
                       y: dest.height / source.height)
        case .fitWidth,
             .auto where !axis:
            x.scaledBy(x: dest.width / source.width,
                       y: dest.width / source.width)
        default: fatalError()
        }
        return x
    }
}

internal extension CGAffineTransform {
    
    ///
	struct Components: Equatable {
        var scaleX: CGFloat
        var scaleY: CGFloat
        var angle: CGFloat
        var translateX: CGFloat
        var translateY: CGFloat
        var remainderA: CGFloat
        var remainderB: CGFloat
        var remainderC: CGFloat
        var remainderD: CGFloat
    }
    
    ///
	func decompose() -> Components {
        var m = self
        
        // Compute scaling factors
        var xScale = sqrt(pow(m.a, 2) + pow(m.b, 2))
        var yScale = sqrt(pow(m.c, 2) + pow(m.d, 2))
        // Compute cross product of transformed unit vectors. If negative,
        // one axis was flipped.
        if m.a * m.d - m.c * m.b < 0 {
            // Flip axis with minimum unit vector dot product
            if m.a < m.d {
                xScale = -xScale
            } else {
                yScale = -yScale
            }
        }
        // Remove scale from matrix
        m = m.scaledBy(x: 1 / xScale, y: 1 / yScale)
        
        // Compute rotation, remove rotation from matrix
        let angle = atan2(m.b, m.a)
        m.rotated(by: -angle * 180.0 / CGFloat.pi);
        
        // Return:
        return Components(scaleX: xScale,
                          scaleY: yScale,
                          angle: angle,
                          translateX: m.tx,
                          translateY: m.ty,
                          remainderA: m.a,
                          remainderB: m.b,
                          remainderC: m.c,
                          remainderD: m.d)
    }
    
    ///
	static func compose(_ components: Components) -> CGAffineTransform {
        var t = CGAffineTransform()
        t.a = components.remainderA
        t.b = components.remainderB
        t.c = components.remainderC
        t.d = components.remainderD
        t.tx = components.translateX
        t.ty = components.translateY
        t = t.rotated(by: components.angle)
        t = t.scaledBy(x: components.scaleX,
                       y: components.scaleY)
        return t
    }
    
    ///
	static func interpolate(from: CGAffineTransform, to: CGAffineTransform, _ fraction: CGFloat) -> CGAffineTransform
    {
        // Decompose source transforms:
        var from = from.decompose()
        var to = to.decompose()
        
        // If x-axis of one is flipped, and y-axis of the other, convert to an unflipped rotation.
        if (from.scaleX < 0 && to.scaleY < 0) || (from.scaleY < 0 && to.scaleX < 0) {
            from.scaleX *= -1
            from.scaleY *= -1
            from.angle += CGFloat.pi * (from.angle < 0 ? 1 : -1)
        }
        
        // Don't rotate the long way around.
        from.angle = fmod(from.angle, 2 * CGFloat.pi)
        to.angle = fmod(to.angle, 2 * CGFloat.pi)
        if abs(from.angle - to.angle) > CGFloat.pi {
            if from.angle > to.angle {
                from.angle -= 2 * CGFloat.pi
            } else {
                to.angle -= 2 * CGFloat.pi
            }
        }
        
        // Apply interpolation to each component:
        from.scaleX += fraction * (to.scaleX - from.scaleX)
        from.scaleY += fraction * (to.scaleY - from.scaleY)
        from.angle += fraction * (to.angle - from.angle)
        from.translateX += fraction * (to.translateX - from.translateX)
        from.translateY += fraction * (to.translateY - from.translateY)
        from.remainderA += fraction * (to.remainderA - from.remainderA)
        from.remainderB += fraction * (to.remainderB - from.remainderB)
        from.remainderC += fraction * (to.remainderC - from.remainderC)
        from.remainderD += fraction * (to.remainderD - from.remainderD)
        
        // Recompose to destination transform:
        return CGAffineTransform.compose(from)
    }
}

extension CGAffineTransform: Hashable {
    public func hash(into hasher: inout Hasher) {
        hasher.combine(a, b, c, d, tx, ty)
    }
}
