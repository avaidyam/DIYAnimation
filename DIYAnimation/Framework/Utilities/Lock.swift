import os.lock

/// An object that coordinates the operation of multiple threads of execution
/// within the same application. A `Lock` can be used to mediate access to an
/// application’s global data or  to protect a critical section of code,
/// allowing it to run atomically.
///
/// Unless `reentrant` is `true`, calling the `lock()` method twice on the same
/// thread will lock up the thread permanently. If it is, it may be acquired
/// multiple times by the same thread without causing a deadlock, a situation
/// where a thread is permanently blocked waiting for itself to relinquish a lock.
/// While the locking thread has one or more locks, all other threads are
/// prevented from accessing the code protected by the lock.
///
/// **Warning:** Unlocking a lock from a different thread can result in undefined
/// behavior.
internal final class Lock: CustomStringConvertible, Hashable {
    internal enum Error: Swift.Error {
        
        /// Couldn't acquire the lock.
        case acquireFailed
    }
    
    /// The internal unfair lock.
    private var _lock = os_unfair_lock()
    
    /// The number of locking attempts made.
    internal var count: Int = 0
    
    /// Whether the lock is reentrant or not.
    internal let reentrant: Bool
    
    /// An identifier used to differentiate locks for debugging purposes.
    internal let name: String?
    
    /// Create a new `Lock`.
    internal init(reentrant: Bool = false, name: String? = nil) {
        self.reentrant = reentrant
        self.name = name
    }
    
    /// Locks the lock, or parks the thread until acquired.
    internal func lock() {
        self.count += 1
        if !self.reentrant || (self.reentrant && self.count - 1 == 0) {
            os_unfair_lock_lock(&self._lock)
        }
    }
    
    /// Unlocks the lock, if acquired.
    internal func unlock() {
        guard self.count >= 0 else { return }
        
        self.count -= 1
        if !self.reentrant || (self.reentrant && self.count == 0) {
            os_unfair_lock_unlock(&self._lock)
        }
    }
    
    /// Executes work between `lock()` and `unlock()` on the receiver.
    @discardableResult
    internal func whileLocked<R>(execute work: () throws -> R) rethrows -> R {
        lock()
        defer { unlock() }
        return try work()
    }
    
    ///
    internal var description: String {
        return "Lock(name: \(self.name ?? "<none>")"
    }
    
    ///
    internal static func ==(lhs: Lock, rhs: Lock) -> Bool {
        return lhs === rhs
    }
    
    /// 
	internal func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}
