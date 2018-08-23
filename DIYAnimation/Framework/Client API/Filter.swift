import Foundation
import CoreImage.CIFilter

///
public protocol FilterType: class {}
extension CIFilter: FilterType {}

///
public final class Filter: FilterType {
    
    ///
    public enum Name {
        
        
        //
        // MARK: - Blend Modes
        //
        
        
        ///
        case normal
        
        ///
        case multiply
        
        ///
        case screen
        
        ///
        case overlay
        
        ///
        case darken
        
        ///
        case lighten
        
        ///
        case colorDodge
        
        ///
        case colorBurn
        
        ///
        case softLight
        
        ///
        case hardLight
        
        ///
        case hardMix
        
        ///
        case difference
        
        ///
        case exclusion
        
        ///
        case subtract
        
        ///
        case negation
        
        ///
        case divide
        
        ///
        case linearBurn
        
        ///
        case linearDodge
        
        ///
        case linearLight
        
        ///
        case pinLight
        
        ///
        case vividLight
        
        
        //
        // MARK: - Composite Modes
        //
        
        
        ///
        case clear
        
        ///
        case sourceCopy
        
        ///
        case sourceOver
        
        ///
        case sourceIn
        
        ///
        case sourceOut
        
        ///
        case sourceAtop
        
        ///
        case destinationCopy
        
        ///
        case destinationOver
        
        ///
        case destinationIn
        
        ///
        case destinationOut
        
        ///
        case destinationAtop
        
        ///
        case xor
        
        ///
        case plusDarker
        
        ///
        case plusLighter
        
        
        //
        // MARK: - Color Matrix
        //
        
        
        ///
        case colorMatrix
        
        ///
        case colorAdd
        
        ///
        case colorSubtract
        
        ///
        case colorMultiply
        
        ///
        case colorMonochrome
        
        ///
        case colorHueRotate
        
        ///
        case colorSaturate
        
        ///
        case colorBrightness
        
        ///
        case colorContrast
        
        ///
        case colorInvert
        
        
        //
        // MARK: - Effects
        //
        
        
        ///
        case convolve
        
        ///
        case diffuseLighting
        
        ///
        case specularLighting
        
        ///
        case distanceField
        
        ///
        case luminanceToAlpha
        
        ///
        case gaussianBlur
        
        ///
        case lanczosResize
    }
    
    // TODO
    
}
