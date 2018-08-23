import AppKit
import MetalKit

///
class AppDelegate: NSObject, NSApplicationDelegate, LayerDelegate {
    
    ///
    private lazy var view: MTKView = MTKView(frame: CGRect(x: 0, y: 0, width: 800, height: 600),
                                             device: MTLCreateSystemDefaultDevice()!)
    
    ///
    private lazy var window: NSWindow = {
        let x = NSWindow(contentViewController: NSViewController(view: self.view))
        x.titlebarAppearsTransparent = true
        x.titleVisibility = .hidden
        x.styleMask.formUnion(.fullSizeContentView)
        x.center()
        return x
    }()
    
    ///
    private var renderer = Renderer()
    
    ///
    private var timer: Timer!
    
    ///
    private var observer: Any? = nil
    
    /*
    override init() {
        super.init()
        
        
        
        func makePair() -> (Transform3D, CATransform3D) {
            let r: ClosedRange<Float> = -100.0...100.0
            let zz1 = Transform3D(.random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r),
                                  .random(in: r), .random(in: r))
            let zz2 = CATransform3D(m11: CGFloat(zz1.m11), m12: CGFloat(zz1.m12),
                                    m13: CGFloat(zz1.m13), m14: CGFloat(zz1.m14),
                                    m21: CGFloat(zz1.m21), m22: CGFloat(zz1.m22),
                                    m23: CGFloat(zz1.m23), m24: CGFloat(zz1.m24),
                                    m31: CGFloat(zz1.m31), m32: CGFloat(zz1.m32),
                                    m33: CGFloat(zz1.m33), m34: CGFloat(zz1.m34),
                                    m41: CGFloat(zz1.m41), m42: CGFloat(zz1.m42),
                                    m43: CGFloat(zz1.m43), m44: CGFloat(zz1.m44))
            return (zz1, zz2)
        }
        
        func vals(_ t: CATransform3D) -> [Float] {
            return [
                t.m11, t.m12, t.m13, t.m14,
                t.m21, t.m22, t.m23, t.m24,
                t.m31, t.m32, t.m33, t.m34,
                t.m41, t.m42, t.m43, t.m44
            ].map { Float($0) }
        }
        
        print("\n\n\n\n")
        var (from1, from2) = makePair()
        var (to1, to2) = makePair()
        assert(from1.values == vals(from2))
        assert(to1.values == vals(to2))
        print(from1.values, to1.values)
        print("\n\n\n\n")
        
        for i in stride(from: 0.0, to: 1.0, by: 0.01) {
            let out1 = Transform3D.interpolate(from: from1, to: to1, Float(i))
            var out2 = CATransform3D()
            CATransform3DInterpolate(&out2, &from2, &to2, i)
            
            print("\niter: \(i)")
            for (x, y) in zip(out1.values, vals(out2)) {
                if x != y {
                    print("error:", x, y)
                } else {
                    print("OK VALUE")
                }
            }
            print("\n")
        }
        print("\n\n\n\n")
        
        
        exit(0)
        
        
    }
    */
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        self.window.makeKeyAndOrderFront(nil)
        self.renderer.configure(for: self.view)
        
        let r1 = Transform3D.scale(x: 1.2, y: 1.2)
        let r2 = Transform3D.rotation(angle: Float.pi, z: 1)
        let r3 = Transform3D.translation(x: 100, y: 100)
        
        let a = BasicAnimation(keyPath: "transform")
        a.fromValue = Transform3D.identity
        a.toValue = r3 * r2 * r1
        a.repeatCount = Int.max
        
        
        // FIXME: Create all the randomized layer nodes:
        //let model = NSImage(named: NSImage.Name("sample"))!
        let root = Layer()
        do {
            for i in 0..<10 {
                let l = TextLayer()
                l.string = "\(i)"
                l.alignmentMode = .center
                
                //l.name = "\(i)"
                //l.delegate = self
                //l.contents = model
                l.position = CGPoint(x: .random(in: 500...1000),
                                     y: .random(in: 500...1000))
                l.bounds = CGRect(x: 0, y: 0,
                                  width: .random(in: 200...600),
                                  height: .random(in: 200...600))
                l.cornerRadius = l.bounds.width * 0.25
                l.borderWidth = l.bounds.width * 0.1
                l.fontSize = l.bounds.height * 0.75
                l.backgroundColor = CGColor(red: .random(in: 0.0...1.0),
                                            green: .random(in: 0.0...1.0),
                                            blue: .random(in: 0.0...1.0),
                                            alpha: 1.0)
                l.borderColor = CGColor(red: .random(in: 0.0...1.0),
                                        green: .random(in: 0.0...1.0),
                                        blue: .random(in: 0.0...1.0),
                                        alpha: 1.0)
                if i == 9 {
                    
                    let m = Layer()
                    m.backgroundColor = .black
                    m.frame = l.frame.insetBy(dx: l.bounds.width * 0.1,
                                              dy: l.bounds.width * 0.1)
                    m.cornerRadius = l.bounds.width * 0.25
                    l.mask = m
                    
                    m.addAnimation(a, forKey: nil)
                    
                    //l.masksToBounds = true
                    //l.shadowOpacity = 1.0
                    
                    //l.compositingFilter = CIFilter(name: "CILinearBurnBlendMode")!
                    //l.backgroundFilters = [CIFilter(name: "CIGaussianBlur")!]
                    //l.filters = [CIFilter(name: "CIGaussianBlur")!]
                }
                if i == 8 {
                    //l.filters = [CIFilter(name: "CIColorInvert")!]
                    //l.backgroundFilters = [CIFilter(name: "CIPhotoEffectNoir")!]
                    //l.filters = [CIFilter(name: "CIColorInvert")!]
                }
                root.addSublayer(l)
                
                //
                // 
                //
                
                
                
                l.addAnimation(a, forKey: nil)
            }
        }
        self.renderer.layer = root
        
        /*
        // Create layer hierarchy.
        let root = Layer()
        let child1 = Layer()
        let child2 = Layer()
        root.addSublayer(child1)
        root.addSublayer(child2)
        
        // Initialize renderer and display link.
        self.context = Renderer()
        self.context.layer = root
        self.timer = Timer.scheduledTimer(withTimeInterval: 1.0 / 60.0, repeats: true) { _ in
            self.context.render()
            self.context.flush()
        }
        
        // Configure `NSOpenGLView` and reshape updates.
        self.view.openGLContext = self.context.ctx
        self.context.bounds = self.view.bounds
        root.frame = self.view.bounds
        self.observer = NotificationCenter.default.addObserver(forName: NSWindow.didResizeNotification, object: self.view.window!, queue: nil, using: { _ in
            self.context.bounds = self.view.bounds
            root.frame = self.view.bounds
        })
        
        // Modify layer properties.
        root.anchorPoint = .zero
        root.backgroundColor = .white
        child1.borderWidth = 10.0
        child2.borderWidth = 20.0
        child1.borderColor = .white
        child2.borderColor = .black
        child1.cornerRadius = 25.0
        child2.cornerRadius = 50.0
        child1.contents = Texture(filePath: "sample.jpg")!
        child1.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        child2.frame = CGRect(x: 0, y: 0, width: 100, height: 100)
        */
    }
    
    func applicationShouldTerminateAfterLastWindowClosed(_ sender: NSApplication) -> Bool {
        return true
    }
}

// -----------------
// --- UTILITIES ---
// -----------------

extension NSViewController {
    
    /// Create a view controller containing `view`; does not load any nibs.
    public convenience init(view: NSView) {
        self.init()
        self.view = view
    }
}
