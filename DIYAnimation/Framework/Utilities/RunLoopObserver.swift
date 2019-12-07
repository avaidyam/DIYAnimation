import Foundation.NSRunLoop
import CoreFoundation.CFRunLoop

/// A `RunLoopObserver` provides a general means to receive callbacks at
/// different points within a running run loop. In contrast to sources, which
/// fire when an asynchronous event occurs, and timers, which fire when a
/// particular time passes, observers fire at special locations within the
/// execution of the run loop, such as before sources are processed or before
/// the run loop goes to sleep, waiting for an event to occur. Observers can be
/// either one-time events or repeated every time through the run loop’s loop.
///
/// Each run loop observer can be registered in only one run loop at a time,
/// although it can be added to multiple run loop modes within that run loop.
internal final class RunLoopObserver: Hashable {
    
    /// Run loop activity stages in which run loop observers can be scheduled.
    internal typealias Activity = CFRunLoopActivity
    
    /// The block invoked when an observer runs. It takes one argument: the
    /// current activity stage of the run loop.
    internal typealias Observer = (RunLoopObserver, Activity) -> Void
    
    /// The internal CF object.
    fileprivate var cf: CFRunLoopObserver!
    
    /// Returns a boolean value that indicates whether a `RunLoopObserver` is
    /// valid and able to fire. A nonrepeating observer is automatically
    /// invalidated after it is called once.
    internal var isValid: Bool {
        return CFRunLoopObserverIsValid(self.cf)
    }
    
    /// Returns the run loop stages during which an observer runs.
    internal var activities: Activity {
        return Activity(rawValue: CFRunLoopObserverGetActivities(self.cf))
    }
    
    /// Returns a Boolean value that indicates whether a `RunLoopObserver`
    /// repeats. `true` if observer is processed during every pass through the
    /// run loop; `false` if observer is processed once and then is invalidated.
    internal var repeats: Bool {
        return CFRunLoopObserverDoesRepeat(self.cf)
    }
    
    /// Returns the ordering parameter for a CFRunLoopObserver object. When
    /// multiple observers are scheduled in the same run loop mode and stage,
    /// this value determines the order (from small to large) in which the
    /// observers are called.
    internal var order: Int {
        return CFRunLoopObserverGetOrder(self.cf)
    }
    
    /// Creates a `RunLoopObserver` object with a block-based handler.
    ///
    /// - Parameter activities: Set of flags identifying the activity stages of
    ///   the run loop during which the observer is called. See
    ///   `RunLoopObserver.Activity` for the list of stages. To have the observer
    ///   called at multiple stages in the run loop, combine the
    ///   `RunLoopObserver.Activity` values using the bitwise-OR operator.
    ///
    /// - Parameter repeats: A flag identifying whether the observer is called
    ///   only once or every time through the run loop. If repeats is false, the
    ///   observer is invalidated after it is called once, even if the observer
    ///   was scheduled to be called at multiple stages within the run loop.
    ///
    /// - Parameter order: A priority index indicating the order in which run
    ///   loop observers are processed. When multiple run loop observers are
    ///   scheduled in the same activity stage in a given run loop mode, the
    ///   observers are processed in increasing order of this parameter. Pass `0`
    ///   unless there is a reason to do otherwise.
    ///
    /// - Parameter block: The block invoked when the observer runs.
    internal init(_ activities: Activity, _ repeats: Bool, _ order: Int,
                  _ block: @escaping Observer)
    {
        self.cf = CFRunLoopObserverCreateWithHandler(nil, activities.rawValue, repeats, order)
        { [weak self] _, act in guard let this = self else { return }
            block(this, act)
        }
    }
    
    deinit {
        self.invalidate()
    }
    
    /// Once invalidated, observer will never fire and call its callback
    /// function again. This function automatically removes observer from all
    /// run loop modes in which it had been added.
    internal func invalidate() {
        CFRunLoopObserverInvalidate(self.cf)
    }
    
    //
    // MARK: - Hashable & Equatable
    //
    
    internal static func ==(lhs: RunLoopObserver, rhs: RunLoopObserver) -> Bool {
        return lhs.cf === rhs.cf
    }
    
	internal func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}

internal extension RunLoop {
    
    /// Adds a `RunLoopObserver` to a run loop mode. A run loop observer can be
    /// registered in only one run loop at a time, although it can be added to
    /// multiple run loop modes within that run loop.
    ///
    /// If the receiver already contains `observer` in `mode`, this does nothing.
	func add(_ observer: RunLoopObserver, forMode mode: RunLoop.Mode) {
        CFRunLoopWakeUp(self.getCFRunLoop())
        CFRunLoopAddObserver(self.getCFRunLoop(), observer.cf,
                             CFRunLoopMode(mode.rawValue as CFString))
    }
    
    /// Removes a `RunLoopObserver` from a run loop mode. A run loop observer
    /// can be registered in only one run loop at a time, although it can be
    /// added to multiple run loop modes within that run loop.
    ///
    /// If the receiver does not contain `observer` in `mode`, this does nothing.
	func remove(_ observer: RunLoopObserver, forMode mode: RunLoop.Mode) {
        CFRunLoopRemoveObserver(self.getCFRunLoop(), observer.cf,
                                CFRunLoopMode(mode.rawValue as CFString))
    }
    
    /// Returns a boolean value that indicates whether a run loop mode contains
    /// a particular `RunLoopObserver`.
    ///
    /// If `observer` was added to `.commonModes`, this function returns `true`
    /// if mode is either `.commonModes` or any of the modes that has been added
    /// to the set of common modes.
	func contains(_ observer: RunLoopObserver, inMode mode: RunLoop.Mode) -> Bool {
        return CFRunLoopContainsObserver(self.getCFRunLoop(), observer.cf,
                                         CFRunLoopMode(mode.rawValue as CFString))
    }
}
