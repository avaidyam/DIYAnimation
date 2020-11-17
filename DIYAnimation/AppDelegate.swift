import Foundation
import protocol AppKit.NSApplicationDelegate
import class AppKit.NSBezierPath

/// README
/// To run this demo, turn off `Metal API Validation` and `GPU Frame Capture`. They currently cause memory leaks.

class AppDelegate: NSObject, NSApplicationDelegate, LayerDelegate {
	private var display: Render.Display!
	private var link: DisplayLink!
	private var renderer: Renderer!
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
		
		// Create some basic utilities for the layers we're about to create.
        let r1 = Transform3D.scale(x: 1.2, y: 1.2)
        let r2 = Transform3D.rotation(angle: Float.pi, z: 1)
        let r3 = Transform3D.translation(x: 100, y: 100)
        let a = BasicAnimation(keyPath: "transform")
        a.fromValue = Transform3D.identity
        a.toValue = r3 * r2 * r1
        a.repeatCount = Int.max
        
        // Create all the randomized layer nodes
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
                l.addAnimation(a, forKey: nil)
            }
			
			let l = TestGL()
			l.position = CGPoint(x: .random(in: 500...1000),
								 y: .random(in: 500...1000))
			l.bounds = CGRect(x: 0, y: 0,
							  width: .random(in: 200...600),
							  height: .random(in: 200...600))
			l.prepareContents() // TODO: should not need this!
		    root.addSublayer(l)
		}
		
		// Create the renderer and link it to the main display.
		self.display = Render.Display()
		self.renderer = Renderer(self.display.device)
        self.renderer.layer = root
		
		// Create a display link to drive render updates.
		self.link = DisplayLink {
			
			// Create a display-sized render surface once and update bounds if needed.
			if self.display.currentDrawable == nil {
				self.display.currentDrawable = self.display.drawable(self.display.bounds.size)
			}
			if self.renderer.bounds != self.display.bounds {
				self.renderer.bounds = self.display.bounds
			}
			let drawable = self.display.currentDrawable!

			// Renders a frame into the `currentDrawable` at the current media time.
			self.renderer.renderTarget = drawable
			self.renderer.beginFrame(atTime: CurrentMediaTime())
			self.renderer.render {
				self.display.render(drawable)
				// TODO: release and re-obtain a drawable here?
			}
			self.renderer.endFrame()
		}
		self.link.add(to: .current, forMode: .common)
    }
    
    /*
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
    */
}


class TestGL: OpenGLLayer {
	
	private let path = NSBezierPath(roundedRect: NSMakeRect(0.1, 0.1, 0.9, 0.9), xRadius: 0.25, yRadius: 0.25)
	
	public override func draw(in context: GLContext, pixelFormat: GLPixelFormat,
							  forLayerTime t: CFTimeInterval,
							  displayTime ts: UnsafePointer<CVTimeStamp>)
	{
        print("hi drawing")
		
		glClearColor(1.0, 1.0, 1.0, 1.0)
		glClear(GLbitfield(GL_COLOR_BUFFER_BIT))
		glEnable(GLenum(GL_MAP1_VERTEX_3))
		glColor4f(0.0, 1.0, 0.0, 1.0)
		
		var _point: CGPoint?
		var points = [CGPoint](repeating: .zero, count: 3)
		for i in 0 ..< self.path.elementCount {
            let type = self.path.element(at: i, associatedPoints: &points)
            switch type {
			case .moveTo:
				/*
				// do nothing
				*/
				if let _point = _point {
					glBegin(GLenum(GL_TRIANGLES))
					glColor4f(0.0, 0.0, 0.0, 1.0)
					glVertex2f(GLfloat(0.5), GLfloat(0.5))
					glVertex2f(GLfloat(_point.x), GLfloat(_point.y))
					glVertex2f(GLfloat(points[0].x), GLfloat(points[0].y))
					glEnd()
				}
				_point = points[0]
			case .lineTo:
				/*
				glBegin(GLenum(GL_LINE_STRIP))
				glVertex2f(GLfloat(_point.x), GLfloat(_point.y))
				glVertex2f(GLfloat(points[0].x), GLfloat(points[0].y))
				glEnd()
				*/
				if let _point = _point {
					glBegin(GLenum(GL_TRIANGLES))
					glColor4f(0.0, 0.0, 0.0, 1.0)
					glVertex2f(GLfloat(0.5), GLfloat(0.5))
					glVertex2f(GLfloat(_point.x), GLfloat(_point.y))
					glVertex2f(GLfloat(points[0].x), GLfloat(points[0].y))
					glEnd()
				}
				_point = points[0]
			case .curveTo:
				/*
				var ctrlPoints = [
					_point.x,    _point.y, 0.0,
					points[0].x, points[0].y, 0.0,
					points[1].x, points[1].y, 0.0,
					points[2].x, points[2].y, 0.0,
				].map(GLfloat.init)
				glMap1f(GLenum(GL_MAP1_VERTEX_3),
						0.0 /* u_min*/, 1.0 /* u_max*/,
						3 /* stride*/, 4 /*num points */,
						&ctrlPoints)
				glBegin(GLenum(GL_LINE_STRIP))
				for i in 0..<1000 {
				    glEvalCoord1f(GLfloat(i) / 1000.0);
				}
				glEnd()
				*/
				if let _point = _point {
					glBegin(GLenum(GL_TRIANGLES))
					glColor4f(0.0, 0.0, 0.0, 1.0)
					glVertex2f(GLfloat(0.5), GLfloat(0.5))
					glVertex2f(GLfloat(_point.x), GLfloat(_point.y))
					glVertex2f(GLfloat(points[2].x), GLfloat(points[2].y))
					glEnd()
				}
				_point = points[2]
			case .closePath:
				_point = nil // reset
			@unknown default: fatalError()
			}
        }
		
		//glRectf(-0.5, -0.5, 0.5, 0.5)
		glFlush()
    }
}
