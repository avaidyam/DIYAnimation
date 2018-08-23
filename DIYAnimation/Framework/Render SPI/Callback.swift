import Foundation

///
internal final class Callback {
    
    /// All queue mutation operations must first acquire this lock.
    private static var lock = Lock()
    
    /// The global queue of all pending `Callback`s.
    private static var queue: [Callback] = [] {
        didSet {
            Callback.queue.sort { $0.time < $1.time }
            Callback.update()
        }
    }
    
    /// The timer that drives the action and removal of queued callbacks.
    private static var timer: Timer = {
        let t = Timer(timeInterval: 0, repeats: false) { _ in
            Callback.perform()
            Callback.update()
        }
        RunLoop.main.add(t, forMode: .defaultRunLoopMode)
        return t
    }()
    
    /// The time at which the callback should be invoked.
    private var time: TimeInterval
    
    /// The action to be invoked at the receiver's `time`.
    private var action: () -> ()
    
    /// Enqueues a callback at the given `time` to perform `action`. The resultant
    /// object need not be retained, as it will be automatically managed.
    @discardableResult
    internal init(at time: TimeInterval, _ action: @escaping () -> ()) {
        self.time = time
        self.action = action
        
        // Retains `self` on the queue:
        Callback.lock.whileLocked {
            Callback.queue.append(self)
        }
    }
    
    /// Update the `timer` to match the earliest queued `Callback`.
    private static func update() {
        guard Callback.queue.count > 0 else { return }
        
        // Convert from framework media time to `CFAbsoluteTime` as a `Date`:
        let t = Callback.queue[0].time - CurrentMediaTime()
        let s = CFAbsoluteTimeGetCurrent() + t
        let date = Date(timeIntervalSinceReferenceDate: s)
        
        // Queue the timer change on its origin `RunLoop`:
        RunLoop.main.perform {
            Callback.timer.fireDate = date
        }
    }
    
    /// Performing the actions of `Callback`s whose deadlines have passed by
    /// the time of this method's invocation, and remove them.
    private static func perform() {
        
        // Lock against the list to prevent inflight mutation:
        Callback.lock.whileLocked {
            let todo = Callback.queue.enumerated()
                .filter { $0.1.time < CurrentMediaTime() }
            
            // First invoke, then remove, each "past" callback:
            todo.forEach {
                $0.1.action()
                Callback.queue.remove(at: $0.0)
            }
        }
    }
}
