import XPC

// TODO: MACH_PORT_RIGHT_PORT_SET -> support port sets!
// mach_port_allocate(mach_task_self(), MACH_PORT_RIGHT_PORT_SET, &set)
// mach_port_insert_member(mach_task_self(), x, set)

///
internal final class Pipe: Codable, Hashable { // basically CFMessagePort!
    private enum CodingKeys: CodingKey {}
    
    ///
    private var queue: DispatchQueue!
    
    ///
    private var pipe: xpc_pipe_t!
    
    ///
    private var source: DispatchSourceMachReceive!
    
    ///
    init(remote port: MachPort) {
        self.queue = DispatchQueue(label: "...")
        
        self.pipe = xpc_pipe_create_from_port(port.port, 0x0)
    }
    
    ///
    init(remote name: String) {
        self.queue = DispatchQueue(label: "...")
        
        self.pipe = xpc_pipe_create(name, 0x0)
    }
    
    ///
    init(local port: MachPort) {
        self.queue = DispatchQueue(label: "...")
        
        self.source = DispatchSource.makeMachReceiveSource(port: port.port, queue: self.queue)
        self.source!.setEventHandler {
            //
        }
        self.source!.setCancelHandler {
            //
        }
        self.source!.setRegistrationHandler {
            //
        }
        self.source!.activate()
    }
    
    ///
    init(local name: String) {
        guard __bootstrap_register(name, MachPort.null.port) == 0 else {
            return // uh die here...
        }
    }
    
    ///
    private static func makePort() -> mach_port_t {
        return 0
    }
    
    
	internal func hash(into hasher: inout Hasher) {
		hasher.combine(xpc_hash(self.pipe))
	}
    
    internal static func == (lhs: Pipe, rhs: Pipe) -> Bool {
        return xpc_equal(lhs.pipe, rhs.pipe)
    }
}
