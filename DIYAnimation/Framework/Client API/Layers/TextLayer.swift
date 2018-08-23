import Foundation

///
public class TextLayer: Layer {
    
    ///
    public enum TruncationMode: Int, Codable {
        
        ///
        case none
        
        ///
        case start
        
        ///
        case middle
        
        ///
        case end
    }
    
    ///
    public enum AlignmentMode: Int, Codable {
        
        ///
        case natural
        
        ///
        case left
        
        ///
        case center
        
        ///
        case right
        
        ///
        case justified
    }
    
    public override class func defaultValue(forKey keyPath: String) -> Any? {
        switch keyPath {
        case "fontSize": return 36.0 as CGFloat
        case "foregroundColor": return CGColor.white
        case "truncationMode": return TruncationMode.none
        case "alignmentMode": return AlignmentMode.natural
        default: return super.defaultValue(forKey: keyPath)
        }
    }
    
    /// The text to be rendered, should be either a `String` or an `NSAttributedString`.
    public var string: String? { //DrawableString? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// The font to use, currently may be either a `CTFont`, `NSFont`, `CGFont`,
    /// or a string naming the font. Defaults to the "Helvetica" font. Only
    /// used when the `string' property is not an `NSAttributedString`.
    public var font: NSFont? { //DrawableFont?  {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// The font size. Defaults to 36. Only used when the `string' property is
    /// not an `NSAttributedString`. Animatable.
    public var fontSize: CGFloat {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// The color object used to draw the text. Defaults to opaque white.
    /// Only used when the `string' property is not an `NSAttributedString`.
    /// Animatable.
    public var foregroundColor: CGColor? {
        get { return self.values[#function] }
        set { self.values[#function] = newValue }
    }
    
    /// When true the string is wrapped to fit within the layer bounds.
    public var isWrapped: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Describes how the string is truncated to fit within the layer bounds.
    public var truncationMode: TruncationMode {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Describes how individual lines of text are aligned within the layer bounds.
    public var alignmentMode: AlignmentMode {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    /// Sets the `allowsFontSubpixelQuantization` parameter of the `CGContext`
    /// passed to the `Layer.draw(in:)` method.
    public var allowsFontSubpixelQuantization: Bool {
        get { return self.values[#function]! }
        set { self.values[#function] = newValue }
    }
    
    public required init() {
        super.init()
    }
    
    public required init(layer: Layer) {
        super.init(layer: layer)
    }
    
    /// Ensure we disable font smoothing for our text rendering.
    internal override func prepare(context ctx: CGContext) {
        super.prepare(context: ctx)
        ctx.setShouldSmoothFonts(false)
        ctx.setAllowsFontSubpixelQuantization(self.allowsFontSubpixelQuantization)
    }
    
    ///
    public override func draw(in context: CGContext) {
        guard let str = self.string else { return }
        
        // Set up attributed string styles, if we weren't given any:
        let style = NSMutableParagraphStyle()
        switch self.alignmentMode {
        case .natural: style.alignment = .natural
        case .left: style.alignment = .left
        case .center: style.alignment = .center
        case .right: style.alignment = .right
        case .justified: style.alignment = .justified
        }
        if self.isWrapped {
            style.lineBreakMode = .byCharWrapping /* word wrapping? */
        } else {
            switch self.truncationMode {
            case .none: style.lineBreakMode = .byClipping
            case .start: style.lineBreakMode = .byTruncatingHead
            case .middle: style.lineBreakMode = .byTruncatingMiddle
            case .end: style.lineBreakMode = .byTruncatingTail
            }
        }
        
        // Modify our, or create, a `CTFont` (if we were not provided one):
        let font = CTFontCreateCopyWithAttributes(self.font ?? TextLayer.defaultFont,
                                                  self.fontSize, nil, nil)
        
        // Modify out, or create, a `CFAttributedString` (if we were not provided one):
        let attr = NSAttributedString(string: str, attributes: [
            .font: font as NSFont,
            .paragraphStyle: style,
            .foregroundColor: NSColor(cgColor: (self.foregroundColor ?? .white))!
        ])
        
        // Create a framesetter and draw into the context:
        CTFramesetter.draw(attr, to: self.bounds, in: context)
    }
    
    /// Get the correct underlying `CTFont` for our `DrawableFont`.
    /*
    private var _font: CTFont {
        if let f = self.font as? String {
            return CTFontCreateWithName(f as CFString, 12.0, nil)
        } else if let f = self.font as? CGFont {
            return CTFontCreateWithGraphicsFont(f, 12.0, nil, nil)
        } else if let f = self.font as? NSFont {
            return f
        } else if let f = self.font as? CTFont {
            return f
        }
        // TODO:
        return TextLayer.defaultFont
    }
    */
    
    ///
    private static let defaultFont = CTFontCreateWithName("Helvetica" as CFString, 12.0, nil)
}

///
public protocol DrawableString {}

///
public protocol DrawableFont {}

extension String: DrawableString {}
extension CFAttributedString: DrawableString {}
extension String: DrawableFont {}
extension CTFont: DrawableFont {}
extension CGFont: DrawableFont {}
#if canImport(AppKit)
import AppKit
extension NSAttributedString: DrawableString {}
extension NSFont: DrawableFont {}
#endif

fileprivate extension CTFramesetter {
    
    /// Shorthand into `CTFrameDraw` to avoid really long function names.
    fileprivate static func draw(_ string: NSAttributedString,
                                 to rect: CGRect,
                                 in ctx: CGContext)
    {
        let fs = CTFramesetterCreateWithAttributedString(string as CFAttributedString)
        let frame = CTFramesetterCreateFrame(fs, CFRange(location: 0, length: 0),
                                             CGPath(rect: rect, transform: nil), nil)
        CTFrameDraw(frame, ctx)
        
        // While tempting, avoid invoking any `NSAttributedString` drawing code!
        //
        // This calls through into `UIFoundation` and is considerably more
        // "heavy-weight" than `CTFramesetter` might be, as it supports many
        // effects/shadows/whatnot, and involves shared code between iOS and macOS.
    }
}
