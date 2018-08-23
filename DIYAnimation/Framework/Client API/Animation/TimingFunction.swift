
///
public struct TimingFunction {
    
    // TODO: built-in types may need separate encoding/decoding for CAML/etc
    
    /// The default `TimingFunction` if none is provided.
    public static let `default` = TimingFunction.linear
    
    ///
    public static let linear = TimingFunction(c1x: 0.25, c1y: 0.25, c2x: 0.75, c2y: 0.75)
    
    ///
    public static let easeIn = TimingFunction(c1x: 0.42, c1y: 0.0, c2x: 1.00, c2y: 1.0)
    
    ///
    public static let easeOut = TimingFunction(c1x: 0.00, c1y: 0.0, c2x: 0.58, c2y: 1.0)
    
    ///
    public static let easeInOut = TimingFunction(c1x: 0.42, c1y: 0.0, c2x: 0.58, c2y: 1.0)
    
    ///
    public let c1x: Double
    
    ///
    public let c1y: Double
    
    ///
    public let c2x: Double
    
    ///
    public let c2y: Double
    
    /// Polynomial coefficients.
    private let a: (x: Double, y: Double)
    private let b: (x: Double, y: Double)
    private let c: (x: Double, y: Double)
    
    ///
    ///
    /// **Note:** All points are clamped to the unit coordinate space (that is,
    /// `(0.0, 0.0)` to `(1.0, 1.0)`).
    public init(c1x: Double = 0, c1y: Double = 0, c2x: Double = 0, c2y: Double = 0) {
        self.c1x = c1x.clamped(to: 0.0...1.0)
        self.c1y = c1y.clamped(to: 0.0...1.0)
        self.c2x = c2x.clamped(to: 0.0...1.0)
        self.c2y = c2y.clamped(to: 0.0...1.0)
        
        // Calculate the polynomial coefficients:
        // Implicit first and last control points are (0,0) and (1,1).
        self.c.x = 3.0 * self.c1x;
        self.c.y = 3.0 * self.c1y;
        self.b.x = 3.0 * (self.c2x - self.c1x) - self.c.x;
        self.b.y = 3.0 * (self.c2y - self.c1y) - self.c.y;
        self.a.x = 1.0 - self.c.x - self.b.x;
        self.a.y = 1.0 - self.c.y - self.b.y;
    }
    
    ///
    internal subscript(_ x: Double) -> Double {
        // TODO: provide a duration for correct subsampling.
        return self.sampleCurve(y: self.solve(for: x))
    }
}

extension TimingFunction {
    
    /// Samples the parametric curve of the unit bezier on the X axis.
    fileprivate func sampleCurve(x t: Double) -> Double {
        return ((self.a.x * t + self.b.x) * t + self.c.x) * t;
    }
    
    /// Samples the parametric curve of the unit bezier on the Y axis.
    fileprivate func sampleCurve(y t: Double) -> Double {
        return ((self.a.y * t + self.b.y) * t + self.c.y) * t;
    }
    
    /// Samples the derivative of the parametric curve of the unit bezier on
    /// the X axis.
    fileprivate func sampleCurve(derivativeX t: Double) -> Double {
        return (3.0 * self.a.x * t + 2.0 * self.b.x) * t + self.c.x;
    }
    
    /// Samples the derivative of the parametric curve of the unit bezier on
    /// the Y axis.
    fileprivate func sampleCurve(derivativeY t: Double) -> Double {
        return (3.0 * self.a.y * t + 2.0 * self.b.y) * t + self.c.y;
    }
    
    /// Solve the unit bezier backing the receiver for a provided `duration`.
    /// If the provided `duration <= 0.0`, the subsampling is predefined to an
    /// infinitesimal (`1e-6`); this computed value defines precision.
    ///
    /// **Note:** The implementation of this function may take a "short path"
    /// via Newton's method, or fall back to the bisection method.
    fileprivate func solve(for x: Double, duration: Double = 0.0) -> Double {
        let epsilon = duration > 0.0 ? 1.0 / (200.0 * duration) : 1e-6
        
        var t0 = 0.0
        var t1 = 0.0
        var t2 = 0.0
        var x2 = 0.0
        var d2 = 0.0
        
        // Newton method:
        t2 = x
        for _ in 0..<8 {
            x2 = self.sampleCurve(x: t2) - x
            if (fabs(x2) < epsilon) {
                return t2;
            }
            d2 = self.sampleCurve(derivativeX: t2)
            if (fabs(d2) < 1e-6) {
                break;
            }
            t2 = t2 - x2 / d2
        }
        // Cleanup:
        t0 = 0.0
        t1 = 1.0
        t2 = x
        // Bisection method:
        if (t2 < t0) {
            return t0
        }
        if (t2 > t1) {
            return t1
        }
        while (t0 < t1) {
            x2 = sampleCurve(x: t2)
            if (fabs(x2 - x) < epsilon) {
                return t2
            }
            if (x > x2) {
                t0 = t2
            } else {
                t1 = t2
            }
            t2 = (t1 - t0) * 0.5 + t0
        }
        // Failure:
        return t2
    }
    
    // TODO: may need -invert func
}
