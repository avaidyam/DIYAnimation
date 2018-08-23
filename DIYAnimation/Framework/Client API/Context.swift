import Foundation

// TODO: fix the mach port stuff!

///
public final class Context: Hashable {
    
    ///
    public enum Options {
        
        ///
        case portName
        
        ///
        case portNumber
        
        ///
        case clientPortNumber
    }
    
    ///
    public struct Fence {
        
    }
    
    //
    // MARK: - Static Properties
    //
    
    ///
    public static var clientPort: MachPort? = nil
    
    ///
    internal static var allContexts: [Weak<Context>] {
        get { return Context.contextLock.whileLocked {
            Context._allContexts
        }}
        set { Context.contextLock.whileLocked {
            Context._allContexts = newValue
        }}
    }
    
    ///
    private static var _allContexts: [Weak<Context>] = []
    
    ///
    private static var contextLock = Lock()
    
    //
    // MARK: - Properties
    //
    
    ///
    private let contextId = UUID()
    
    ///
    private var lock = Lock()
    
    ///
    public let remote: Bool
    
    ///
    private var clientPort: MachPort? = nil {
        didSet {
            // dealloc old port
        }
    }
    
    ///
    private var serverPort: MachPort? = nil {
        didSet {
            // dealloc old port
        }
    }
    
    ///
    public private(set) var isValid: Bool = true
    
    ///
    public var colorSpace = CGColorSpaceCreateDeviceRGB() {
        didSet {
            self.lock.lock()
            Transaction.ensure()
            Transaction.whileLocked {
                self.layer?.perform {
                    $0.colorSpaceDidChange(self.colorSpace)
                }
            }
            self.lock.unlock()
        }
    }
    
    ///
    public var layer: Layer? = nil {
        willSet {
            assert(newValue?.context == nil,
                   "Cannot assign a new Context to a Layer that already has one!")
        }
        didSet {
            self.lock.whileLocked {
                
                // Remove and unlink the old layer, if any:
                if let old = oldValue {
                    old.context = nil
                    Transaction.ensure().add(.removeLayer(old))
                }
                
                // Attach and link the new layer, if any:
                if let new = self.layer {
                    new.context = self
                    Transaction.ensure().add(.setLayer(new))
                }
            }
        }
    }
    
    //
    // MARK: - Init & Deinit
    //
    
    ///
    public static func local(_ options: [Options: Any] = [:]) -> Context {
        return Context(remote: false, options: options)
    }
    
    ///
    public static func remote(_ options: [Options: Any] = [:]) -> Context {
        return Context(remote: true, options: options)
    }
    
    /// Create a new local or remote context with provided options.
    private init(remote: Bool, options: [Options: Any]) {
        self.remote = remote
        
        // Keep track of this new context:
        Context.allContexts.append(Weak(self))
        
        // Configure the client and server ports for a remote `Context`:
        guard self.remote else { return }
        if let p = options[.portName] as? MachPort {
            self.serverPort = p // RenderServer.port(for: options[Context.portNameKey])
        } else if let p = options[.portNumber] as? MachPort {
            self.serverPort = p
        } else {
            self.serverPort = .null //RenderServer.defaultPort
        }
        
        if let c = options[.clientPortNumber] as? MachPort {
            self.clientPort = c
        } else if let c = Context.clientPort {
            self.clientPort = c
        } else {
            let p = MachPort(right: .send).inserting(right: .send)
            self.clientPort = p == .null ? nil : p
        }
    }
    
    /// Invalidate and unregister the context:
    deinit {
        self.invalidate()
        Context.allContexts.removeAll { $0.value == self }
    }
    
    ///
    public func invalidate() {
        self.isValid = false
        self.layer = nil
        self.clientPort = nil
    }
    
    ///
    private func flush() {
        self.layer?.layoutIfNeeded()
        self.layer?.displayIfNeeded()
        // self.rendercontext.willcommit OR create encoder
        // 1. delete objects
        // 2. commit commands
        Context.commit([])
        // 3. self.layer?.commitIfNeeded() -> perform() instead
        self.layer?.perform { l in
            // copy render value...
            // commit any shmems (via set objects)
            // set object OR encode set object
        }
        // 4. commit commands (again)
        Context.commit([])
        // 5. delete shmem's
        // self.rendercontext.didcommit OR send encoded msg
    }
    
    //
    // MARK: - Fences
    //
    
    private func createFencePort() -> MachPort {
        //
        return .null
    }
    
    private func setFence(_ fence: UInt32, _ count: Int) {
        //
    }
    
    private func setFencePort(_ fence: MachPort, _ handler: (() -> ())? = nil) {
        //
    }
    
    private func invalidateFences() {
        //
    }
    
    //
    // MARK: - Transaction Commit
    //
    
    ///
    internal static func commit(_ commands: [Transaction.Command]) {
        //let contexts = Context.allContexts.compactMap { $0.value }
        // do stuff
        // call transaction handlers too
    }
    
    // synchronize: check current seed vs server's seed
}

//
// MARK: - Hashable
//

extension Context {
    public static func ==(lhs: Context, rhs: Context) -> Bool {
        return lhs.contextId == rhs.contextId
    }
    public var hashValue: Int {
        return self.contextId.hashValue
    }
}
