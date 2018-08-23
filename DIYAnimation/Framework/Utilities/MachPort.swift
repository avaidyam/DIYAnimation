
/// Mach ports are the endpoints to Mach-implemented communications channels
/// (usually unidirectional message queues, but other types also exist).
///
/// Unique collections of these endpoints are maintained for each Mach task.
/// Each Mach port in the task's collection is given a [task-local] name to
/// identify it - and the the various "rights" held by the task for that
/// specific endpoint.
///
/// In user-space, "rights" are represented by the name of the right in the Mach
/// port namespace. Even so, this type is presented as a unique one to more
/// clearly denote the presence of a right coming along with the name.
///
/// Often, various rights for a port held in a single name space will coalesce
/// and are, therefore, be identified by a single name [this is the case for
/// send and receive rights]. But not always [send-once rights currently get a
/// unique name for each right].
public final class MachPort: Codable, Hashable {
    
    /// Represents a `Right` that may be held by the `MachPort`.
    public enum Right: mach_port_right_t {
        
        /// Equivalent to `MACH_PORT_RIGHT_SEND`.
        case send = 0
        
        /// Equivalent to `MACH_PORT_RIGHT_RECEIVE`.
        case receive = 1
        
        /// Equivalent to `MACH_PORT_RIGHT_SEND_ONCE`.
        case sendOnce = 2
    }
    
    ///
    public enum RightType: mach_msg_type_name_t {
        
        ///
        case none = 0
        
        /// Equivalent to `MACH_MSG_TYPE_MOVE_RECEIVE`. Must hold receive rights.
        case moveReceive = 16
        
        /// Equivalent to `MACH_MSG_TYPE_MOVE_SEND`. Must hold send rights.
        case moveSend = 17
        
        /// Equivalent to `MACH_MSG_TYPE_MOVE_SEND_ONCE`. Must hold send-once rights.
        case moveSendOnce = 18
        
        /// Equivalent to `MACH_MSG_TYPE_COPY_SEND`. Must hold send rights.
        case copySend = 19
        
        /// Equivalent to `MACH_MSG_TYPE_MAKE_SEND`. Must hold receive rights.
        case makeSend = 20
        
        /// Equivalent to `MACH_MSG_TYPE_MAKE_SEND_ONCE`. Must hold receive rights.
        case makeSendOnce = 21
        
        /// Equivalent to `MACH_MSG_TYPE_COPY_RECEIVE`. Must hold receive rights.
        case copyReceive = 22
    }
    
    /// `null` is a legal value that can be carried in messages. It indicates the
    /// absence of any port or port rights. (A port argument keeps the message
    /// from being "simple", even if the value is `null`.)
    public static let null = MachPort(port: 0)
    
    /// The value `dead` is a legal value that can be carried in messages.
    /// It indicates that a port right was present, but it died.
    public static let dead = MachPort(port: mach_port_t(bitPattern: Int32(-1)))
    
    /// The underlying kernel task type of the owner of the port.
    public let task: ipc_space_t
    
    /// The underlying kernel port type.
    public let port: mach_port_t
    
    ///
    public init(task: ipc_space_t = mach_task_self_, port: mach_port_t) {
        self.task = task
        self.port = port
    }
    
    /// Allocates a new port with the Kernel with the given `right`.
    public init(right: Right) {
        self.task = mach_task_self_
        var port: mach_port_name_t = 0
        mach_port_allocate(self.task, right.rawValue, &port)
        self.port = port
    }
    
    deinit {
        mach_port_deallocate(self.task, self.port)
    }
    
    ///
    @discardableResult
    public func inserting(right: Right, type: RightType = .none) -> Self {
        assert(self != .null, "Cannot insert a right into a null port!")
        assert(self != .dead, "Cannot insert a right into a dead port!")
        mach_port_insert_right(self.task, self.port, right.rawValue, type.rawValue)
        return self
    }
    
    // TODO: not sure why we need to re-implement this?
    public var hashValue: Int {
        var x = Hasher()
        self.hash(into: &x)
        return x.finalize()
    }
    
    /// Hash the receiver.
    public func hash(into hasher: inout Hasher) {
        hasher.combine(self.task, self.port)
    }
    
    /// Two `MachPort`s are equal iff their `task`s and `port`s are equal.
    /// However, `null` and `dead` ports are always equal regardless of the
    /// owning task.
    public static func ==(_ lhs: MachPort, _ rhs: MachPort) -> Bool {
        if lhs.port == MachPort.null.port && rhs.port == MachPort.null.port {
            return true
        }
        if lhs.port == MachPort.dead.port && rhs.port == MachPort.dead.port {
            return true
        }
        return lhs.task == rhs.task && lhs.port == rhs.port
    }
}

///
public struct MachSendRight: Codable, Hashable {
    
}

///
public struct MachReceiveRight: Codable, Hashable {
    
}
