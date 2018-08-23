import Foundation
import CoreVideo.CVDisplayLink

/// Class representing a timer bound to the display vsync.
public final class DisplayLink {
    
    /// The internal CVDisplayLink object.
    private var displayLink: CVDisplayLink? = nil
    
    /// The `RunLoop` the receiver is scheduled to call its `action` on.
    private weak var runloop: RunLoop? = nil
    
    /// The set of `RunLoopMode`s in which the receiver's action will be called.
    private var modes: Set<RunLoopMode> = []
    
    /// The current timestamp of the display frame associated with the most
    /// recent target invocation.
    public private(set) var timestamp: CFTimeInterval = 0.0
    
    /// The current duration of the display frame associated with the most
    /// recent target invocation.
    public private(set) var duration: CFTimeInterval = 0.0
    
    /// The next timestamp that the client should target their render for.
    public private(set) var targetTimestamp: CFTimeInterval = 0.0
    
    /// When `true` the object is prevented from firing.
    public var isPaused: Bool {
        get { return CVDisplayLinkIsRunning(self.displayLink!) }
        set { CVDisplayLinkSetPaused(self.displayLink!, newValue) }
    }
    
    /// The display that the receiver is currently synchronized to.
    public var display: CGDirectDisplayID = CGMainDisplayID() {
        didSet {
            guard self.displayLink != nil else { return }
            CVDisplayLinkSetCurrentCGDisplay(self.displayLink!, self.display)
        }
    }
    
    /// Defines the desired callback rate in frames-per-second for this display
    /// link. If set to `0`, the default value, the display link will fire at the
    /// native cadence of the display hardware. The display link will make a
    /// best-effort attempt at issuing callbacks at the requested rate.
    public var preferredFramesPerSecond: Int = 0 {
        didSet {
            // ???
        }
    }
    
    /// The action to be executed upon the receiver firing.
    private let action: () -> ()
    
    /// Create a new display link object for the main display. It will
    /// invoke the handler provided.
    public init(_ action: @escaping () -> ()) {
        self.action = action
    }
    
    deinit {
        self.invalidate()
    }
    
    /// Removes the object from all runloop modes (releasing the receiver if
    /// it has been implicitly retained) and releases its `action`.
    public func invalidate() {
        self.stopDisplayLink()
    }
    
    /// Adds the receiver to the given run-loop and mode. Unless paused, it
    /// will fire every vsync until removed. Each object may only be added
    /// to a single run-loop, but it may be added in multiple modes at once.
    /// While added to a run-loop it will implicitly be retained.
    public func add(to runloop: RunLoop, forMode mode: RunLoopMode) {
        guard self.runloop == nil else { return }
        self.runloop = runloop
        self.modes.insert(mode)
        
        if self.modes.count > 0 {
            self.createDisplayLink()
        }
    }
    
    /// Removes the receiver from the given mode of the runloop. This will
    /// implicitly release it when removed from the last mode it has been
    /// registered for.
    public func remove(from runloop: RunLoop, forMode mode: RunLoopMode) {
        guard self.runloop == runloop else { return }
        self.modes.remove(mode)
        if self.modes.count == 0 {
            self.runloop = nil
            self.invalidate()
        }
    }
    
    ///
    private func createDisplayLink() {
        guard self.displayLink == nil else { return }
        
        //
        let error = CVDisplayLinkCreateWithCGDisplay(self.display, &self.displayLink)
        guard let dLink = self.displayLink, kCVReturnSuccess == error else {
            self.displayLink = nil
            print("DisplayLink could not be created: \(error)"); return
        }
        
        /// nowTime is the current frame time
        /// outputTime is when the frame will be displayed
        CVDisplayLinkSetOutputHandler(dLink) { (_, nowTime, outputTime, _, _) in
            
            // Configure current timing:
            self.duration = 1.0 / ((outputTime.pointee.rateScalar *
                Double(outputTime.pointee.videoTimeScale) /
                Double(outputTime.pointee.videoRefreshPeriod)))
            self.timestamp = Double(nowTime.pointee.videoTime) /
                Double(nowTime.pointee.videoTimeScale)
            self.targetTimestamp = self.timestamp + self.duration
            
            // Execute on our runloop and return:
            self.runloop?.perform(inModes: self.modes.map{$0}, block: self.action)
            return kCVReturnSuccess
        }
        CVDisplayLinkStart(dLink)
    }
    
    ///
    private func stopDisplayLink() {
        if let v = self.displayLink {
            CVDisplayLinkStop(v)
            self.displayLink = nil
        }
    }
}

/// Private `CVDisplayLink` facility to pause updates.
@_silgen_name("CVDisplayLinkSetPaused")
private func CVDisplayLinkSetPaused(_ displayLink: CVDisplayLink, _ paused: Bool)
