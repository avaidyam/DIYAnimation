import Foundation.NSThread

// TODO: pthread_cleanup_push to commit transactions on deleted threads

/// A mechanism for grouping multiple layer-tree operations into atomic updates
/// to the render tree.
///
/// `Transaction` is the mechanism for batching multiple layer-tree operations
/// into atomic updates to the render tree. Every modification to a layer tree
/// must be part of a transaction. Nested transactions are supported.
///
/// There are two types of transactions: implicit transactions and explicit
/// transactions. Implicit transactions are created automatically when the layer
/// tree is modified by a thread without an active transaction and are committed
/// automatically when the thread's runloop next iterates. Explicit transactions
/// occur when the the application sends the `Transaction` class a `begin()`
/// message before modifying the layer tree, and a `commit()` message afterwards.
///
/// `Transaction` allows you to override default animation properties that are
/// set for animatable properties. You can customize duration, timing function,
/// whether changes to properties trigger animations, and provide a handler that
/// informs you when all animations from the transaction group are completed.
///
/// During a transaction you can temporarily acquire a recursive spin lock for
/// managing property atomicity.
public final class Transaction: Hashable {
    
    /// The current phase of the `Transaction`.
    public enum Phase {
        
        /// The `Transaction` is not in a `Phase`.
        case none
        
        /// Layer layout has not been invalidated yet for this `Transaction`.
        case preLayout
        
        /// The `Transaction` is about to be committed to `Context`s.
        case preCommit
        
        /// The `Transaction` has just been committed to `Context`s.
        case postCommit
    }
    
    /// Determines how a `Transaction` was created.
    public enum State {
        
        /// This `Transaction` was created implicitly because there was no
        /// pre-existing one on its `Thread`.
        case implicit
        
        /// This `Transaction` was created explicitly by calling `begin()`.
        case explicit
    }
    
    /// The list of layer mutation commands that can be issued to a `Transaction`.
    /// Upon `commit()`, the `Transaction` vends these enqueued commands to all
    /// `Context`s, which then batch and send changes to their `RenderServer`s.
    internal enum Command {
        
        ///
        case addRoot(Layer)
        
        ///
        case setLayer(Layer)
        
        ///
        case removeLayer(Layer)
        
        ///
        case addAnimation
        
        ///
        case removeAnimation
        
        ///
        case removeAllAnimations
        
        ///
        case deleteLayer(UUID)
    }
    
    /// The thread-specific key used to store the current `Transaction`.
    private static let key: String = "transaction"
    
    /// Duration, in seconds, for animations triggered within the transaction
    /// group. The value for this key must be a number.
    public static let animationDurationKey: String = "animationDuration"
    
    /// If true, implicit actions for property changes made within the transaction
    /// group are suppressed. The value for this key must be a number.
    public static let disableActionsKey: String = "disableActions"
    
    /// An instance of `TimingFunction` that overrides the timing function for
    /// all animations triggered within the transaction group.
    public static let animationTimingFunctionKey: String = "animationTimingFunction"
    
    /// A completion block object that is guaranteed to be called (on the main
    /// thread) as soon as all animations subsequently added by this transaction
    /// group have completed (or have been removed.) If no animations are added
    /// before the current transaction group is committed (or the completion
    /// block is set to a different value), the block will be invoked immediately.
    public static let completionBlockKey: String = "completionBlock"
    
    /// The current thread's `Transaction`, if any.
    private static var current: Transaction? {
        get { return Thread.current.threadDictionary[Transaction.key] as? Transaction }
        set { Thread.current.threadDictionary[Transaction.key] = newValue }
    }
    
    /// Ensures that the current thread and run loop mode have a `Transaction`.
    @discardableResult
    internal static func ensure() -> Transaction {
        
        // If there was no existing `Transaction`, create a new implicit one:
        let transaction = Transaction.current ?? .init(.implicit)
        transaction.setup()
        return transaction
    }
    
    /// Attempts to acquire a recursive spin-lock, ensuring that returned layer
    /// values are valid until unlocked.
    ///
    /// The framework uses a data model that promises not to corrupt the
    /// internal data structures when called from multiple threads concurrently,
    /// but not that data returned is still valid if the property was valid on
    /// another thread. By locking during a transaction you can ensure data that
    /// is read, modified, and set is correctly managed.
    public static func lock() {
         Transaction.ensure().lock.lock()
    }
    
    /// Relinquishes a previously acquired transaction lock.
    public static func unlock() {
        Transaction.ensure().lock.unlock()
    }
    
    /// Performs a set of atomic operations on the `Transaction`. See `lock()`
    /// and `unlock()` for further details.
    @discardableResult
    public static func whileLocked<Result>(_ handler: () throws -> (Result)) rethrows -> Result {
        Transaction.lock()
        defer { Transaction.unlock() }
        return try handler()
    }
    
    /// Begin a new transaction for the current thread. The transaction is nested
    /// within the thread’s current transaction, if there is one.
    public static func begin() {
        Transaction(.explicit)
    }
    
    /// Commit all changes made during the current transaction. Raises an exception
    /// if no current transaction exists.
    public static func commit() {
        assert(Transaction.current != nil, "There was no existing transaction to commit!")
        Transaction.current = nil
    }
    
    /// Flushes any extant implicit transaction. Delays the commit until any
    /// nested explicit transactions have completed.
    ///
    /// Flush is typically called automatically at the end of the current
    /// runloop, regardless of the runloop mode. If your application does not
    /// have a runloop, you must call this method explicitly.
    ///
    /// However, you should attempt to avoid calling flush explicitly. By
    /// allowing flush to execute during the runloop your application will
    /// achieve better performance, atomic screen updates will be preserved,
    /// and transactions and animations that work from transaction to
    /// transaction will continue to function.
    public static func flush() {
        Transaction.current = nil
    }
    
    // add commit handlers per phase!
    
    //
    //
    //
    
    /// Sets or returns the arbitrary keyed-data specified by a given key.
    ///
    /// Nested transactions have nested data scope. Requesting a value for a
    /// key first searches the innermost scope, then the enclosing transactions.
    public class var values: AttributeList {
        return Transaction.ensure().values
    }
    
    // TODO: values should search the nested scope's parents!!
    
    /// The animation duration used by all animations within this transaction group.
    public class var animationDuration: TimeInterval {
        get { return Transaction.ensure().values.animationDuration! }
        set { Transaction.ensure().values.animationDuration = newValue }
    }
    
    /// The timing function used for all animations within this transaction group.
    public class var animationTimingFunction: TimingFunction? {
        get { return Transaction.ensure().values.animationTimingFunction }
        set { Transaction.ensure().values.animationTimingFunction = newValue }
    }
    
    /// Whether actions triggered as a result of property changes made within
    /// this transaction group are suppressed.
    public class var disableActions: Bool {
        get { return Transaction.ensure().values.disableActions! }
        set { Transaction.ensure().values.disableActions = newValue }
    }
    
    /// The completion block object
    public class var completionBlock: (() -> ())? {
        get { return Transaction.ensure().values.completionBlock }
        set { Transaction.ensure().values.completionBlock = newValue }
    }
    
    
    //
    //
    //
    
    ///
    private static var commands: [Command] = []
    
    ///
    private var transactionId = UUID()
    
    ///
    private lazy var values = AttributeList(values: [:], nil)
    
    ///
    private var parent: Transaction? = nil
    
    ///
    private var observer: RunLoopObserver? = nil
    
    ///
    private var lock = Lock(reentrant: true)
    
    ///
    internal let state: State
    
    /// Pushes a new `Transaction` on the current `Thread`.
    /// All layer mutations are now encoded within this nested `Transaction`.
    @discardableResult
    internal init(_ state: State = .explicit) {
        self.state = state
        self.parent = Transaction.current
        Transaction.current = self
    }
    
    /// Pops this `Transaction` off of the current `Thread`.
    /// All layer mutations encoded within this `Transaction` are committed to
    /// their respective `Context`s.
    deinit {
        Transaction.current = self.parent
        
        if self.parent == nil /* the root-most transaction */ {
            let commands = Transaction.commands
            Transaction.commands = []
            Context.commit(commands)
        }
    }
    
    /// Sets up the current `Transaction`'s run loop observer.
    private func setup() {
        
        // TODO: add thread destructor to call commit()!
        
        // Create the new transaction's observer, if there was none:
        if self.observer == nil {
            let obs = RunLoopObserver([.beforeWaiting, .exit], true, 2_000_000) { o, _ in
                guard Transaction.current?.observer == o else { return }
                Transaction.current = nil
            }
			RunLoop.current.add(obs, forMode: .common)
            self.observer = obs
        }
        
        // Attach the transaction's observer to the current run loop mode:
		if let mode = RunLoop.current.currentMode, mode != .common {
            RunLoop.current.add(self.observer!, forMode: mode)
        }
    }
    
    ///
    internal func add(_ commands: Command...) {
        Transaction.commands.append(contentsOf: commands)
    }
    
    public static func ==(_ lhs: Transaction, _ rhs: Transaction) -> Bool {
        return lhs === rhs
    }
    
	public func hash(into hasher: inout Hasher) {
		hasher.combine(ObjectIdentifier(self))
	}
}
