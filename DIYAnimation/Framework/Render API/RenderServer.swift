
// TODO: use xpc_pipe_t instead of mach ports directly!

///
public final class RenderServer {
    
    ///
    public private(set) var isRunning: Bool = false
    
    ///
    public init() {
        
    }
    
    deinit {
        self.stop()
        // release vm!
    }
    
    ///
    public func start() {
        defer { self.isRunning = true }
    }
    
    ///
    public func stop() {
        defer { self.isRunning = false }
    }
    
    // register client, notify client
    // register name with bootstrap server
    // render client, client_list
    
    ///
    private func main() {
        // call below funcs:
    }
    
    // dispatch_message, run_command_stream
}

// IPC:
//     - CLIENT: ImageProviderSignal // server -> client to request
// - ImageProviderGetSubImage // probably response to the ^ func?
// - {Get,Set}DebugFlags // Debug flags...
// - CreateSlot // Slots...
// - SetClientPorts // Context.connect_cgs() <-- not used
//
// - Client:
//     - RegisterClient[Options] // Context.remote()
//     - RenderClient[List] // NOT CALLED! Draws into IOSurface!
//     - UpdateClient // ImageQueue.ping()
//     - DeleteClient // Context.invalidate()
