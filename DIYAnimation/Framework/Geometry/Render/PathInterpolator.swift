import CoreGraphics.CGPath

/// The Kochanek-Bartels `Spline` is a cubic Hermite `Spline` with the addition
/// of the `tension`, `bias`,  and `continuity` properties, modifying the tangents
/// of the interpolating points. Setting these values to zero results in the
/// Catmull-Rom `Spline`.
internal struct Spline {
    
    ///
    internal struct Knot {
        
        /// The control point.
        fileprivate var point: CGPoint
        
        /// T = (−1→Round, +1→Tight)
        fileprivate var tension: CGFloat
        
        /// B = (−1→Pre-shoot, +1→Post-shoot)
        fileprivate var bias: CGFloat
        
        /// C = (−1→Box-corners, +1→Inverted-corners)
        fileprivate var continuity: CGFloat
        
        internal init(point: CGPoint = .zero, tension: CGFloat = 0,
                      bias: CGFloat = 0, continuity: CGFloat = 0)
        {
            self.point = point
            self.tension = tension
            self.bias = bias
            self.continuity = continuity
        }
    }
    
    /// The knots in the receiver.
    private var knots: [Knot]
    
    /// The number of subdivisions used in interpolating between points.
    private var subdivisions: UInt
    
    /// Create a new Kochanek-Bartels `Spline` for interpolation.
    internal init(knots: [Knot], subdivisions: UInt = 10) {
        self.knots = knots
        self.subdivisions = subdivisions
    }
    
    /// Iterate over the interpolated points of the receiver.
    fileprivate func forEach(_ handler: (CGPoint) -> ()) {
        guard self.knots.count >= 2 else { return }
        var incoming = [CGPoint](), outgoing = [CGPoint]()
        
        // Kochanek-Bartels Equations 8 & 9.
        // Calculate incoming & outgoing tangent vectors for each point:
        for i in 0..<self.knots.count {
            var next = CGPoint.zero, prev = CGPoint.zero
            let curr = self.knots[i].point
            
            // Select suitable start + end points (imaginary, if needed):
            if i == 0 {
                next = self.knots[i + 1].point
                prev = self.knots[i].point
            } else if i == self.knots.count - 1 {
                next = self.knots[i].point
                prev = self.knots[i - 1].point
            } else {
                next = self.knots[i + 1].point
                prev = self.knots[i - 1].point
            }
            
            // Calculate T, B, C variance:
            let T = self.knots[i].tension
            let B = self.knots[i].bias
            let C = self.knots[i].continuity
            let d0 = CGPoint(x: ((1 - T) * (1 - C) * (1 + B)) / 2,
                             y: ((1 - T) * (1 + C) * (1 - B)) / 2)
            let d1 = CGPoint(x: ((1 - T) * (1 + C) * (1 + B)) / 2,
                             y: ((1 - T) * (1 - C) * (1 - B)) / 2)
            
            // Insert the new calculated tangents:
            let ivec = CGPoint(x: d0.x * (curr.x - prev.x) + d0.y * (next.x - curr.x),
                               y: d0.x * (curr.y - prev.y) + d0.y * (next.y - curr.y))
            let dvec = CGPoint(x: d1.x * (curr.x - prev.x) + d1.y * (next.x - curr.x),
                               y: d1.x * (curr.y - prev.y) + d1.y * (next.y - curr.y))
            incoming.append(ivec)
            outgoing.append(dvec)
        }
        
        // Kochanek-Bartels Equation 2.
        // Apply an interpolation matrix to each point using its tangent point:
        for i in 0..<self.knots.count - 1 {
            let curr = self.knots[i].point
            let next = self.knots[i + 1].point
            let d0 = outgoing[i]
            let d1 = incoming[i + 1]
            
            // Calculate the intermediate point using tangents:
            let a = CGPoint(x: 2.0 * curr.x - 2.0 * next.x + d0.x + d1.x,
                            y: 2.0 * curr.y - 2.0 * next.y + d0.y + d1.y)
            let b = CGPoint(x: -3.0 * curr.x + 3.0 * next.x - 2.0 * d0.x - d1.x,
                            y: -3.0 * curr.y + 3.0 * next.y - 2.0 * d0.y - d1.y)
            let c = d0
            let d = curr
            
            // Interpolate each new point from the spline:
            var s1: CGFloat = 0.0, s2: CGFloat = 0.0, s3: CGFloat = 0.0
            let step = 1.0 / (CGFloat(max(1, self.subdivisions)) - 1)
            for _ in 0..<max(1, self.subdivisions) {
                if s1 != 0 {
                    s2 = s1 * s1
                    s3 = s2 * s1
                }
                
                // Calculate and invoke with the parametric vertex:
                let vertex = CGPoint(x: (a.x * s3 + b.x * s2 + c.x * s1 + d.x),
                                     y: (a.y * s3 + b.y * s2 + c.y * s1 + d.y))
                handler(vertex)
                s1 += step
            }
        }
        
        // We didn't consider the last point yet:
        handler(self.knots.last!.point)
    }
}

internal extension CGPoint {
    
    /// A much faster approximation to the true `distance`.
    /// If `to` is `.zero`, the value represents the `length` of the receiver.
    @inline(__always)
    func manhattanDistance(to: CGPoint = .zero) -> CGFloat {
        return abs(self.x - to.x) + abs(self.y - to.y)
    }
    
    /// The distance from the receiver to a new point.
    /// If `to` is `.zero`, the value represents the `length` of the receiver.
    @inline(__always)
    func distance(to: CGPoint = .zero) -> CGFloat {
        return sqrt(pow((self.x - to.x), 2) + pow((self.y - to.y), 2))
    }
}

//
// MARK: - NSBezierPath <-> CGPath
//

#if canImport(AppKit)
import AppKit
extension NSBezierPath {
    
    /// Convert a bezier path to a `CGPath`.
    public var cgPath: CGPath {
        let path = CGMutablePath()
        var points = [CGPoint](repeating: .zero, count: 3)
        for i in 0 ..< self.elementCount {
            let type = self.element(at: i, associatedPoints: &points)
            switch type {
			case .moveTo: path.move(to: points[0])
			case .lineTo: path.addLine(to: points[0])
			case .curveTo: path.addCurve(to: points[2], control1: points[0], control2: points[1])
			case .closePath: path.closeSubpath()
			@unknown default: fatalError()
			}
        }
        return path
    }
}
#endif

//
// MARK: - Color Utilities
//

internal extension CGColor {
    @usableFromInline
	static var _space = CGColorSpaceCreateDeviceRGB()
    @usableFromInline
	var rgba: [CGFloat] {
        let x = self.converted(to: CGColor._space,
                               intent: .defaultIntent, options: nil)
        return x?.components ?? [CGFloat](repeating: 0.0,
                                          count: CGColor._space.numberOfComponents)
    }
}
