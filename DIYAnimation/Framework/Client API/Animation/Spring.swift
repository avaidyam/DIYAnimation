
///
internal struct Spring {
    
    ///
    internal let mass: Double
    
    ///
    internal let stiffness: Double
    
    ///
    internal let damping: Double
    
    ///
    internal let initialVelocity: Double
    
    ///
    internal init(mass: Double, stiffness: Double, damping: Double,
                  initialVelocity: Double)
    {
        self.mass = mass
        self.stiffness = stiffness
        self.damping = damping
        self.initialVelocity = initialVelocity
    }
    
    ///
    internal func solve(_ t: Double) -> Double {
        assert(self.damping > 0.0 && self.stiffness > 0.0 && self.mass > 0.0)
        
        let x0 = -1.0
        let iv = self.initialVelocity
        let beta = self.damping / (2 * mass)
        let w0 = sqrt(self.stiffness / self.mass)
        let w1 = sqrt((w0 * w0) - (beta * beta))
        let w2 = sqrt((beta * beta) - (w0 * w0))
        
        if beta < w0 { // under damped
            return -x0 + exp(-beta * t) * ((x0 * cos(w1 * t)) + (((beta * x0 + iv) / w1) * sin(w1 * t)))
        } else if beta == w0 { // critically damped
            return -x0 + exp(-beta * t) * (x0 + (beta * x0 + iv) * t)
        } else if beta > w0 { // over damped
            return -x0 + exp(-beta * t) * ((x0 * cosh(w2 * t)) + (((beta * x0 + iv) / w2) * sinh(w2 * t)))
        } else {
            fatalError("This should never occur!")
        }
    }
}
