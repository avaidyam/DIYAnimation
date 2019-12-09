
// TODO: use xpc_pipe_t instead of mach ports directly!

extension Render {
	///
	public final class Server {
		
		///
		public private(set) var isRunning: Bool = false
		
		///
		public private(set) var port: MachPort? = nil
		///
		public private(set) var portSet: [MachPort]? = nil
		
		// A thread with receive rights for many ports may create a ``port set'', a first-class object containing an arbitrary subset of these receive rights[7]. The thread may then invoke msg_receive() on that port set (rather than on the underlying ports), receiving messages from all of the contained ports in FIFO order. Each message is marked with the identity of the original receiving port, allowing the thread to demultiplex the messages. The port set approach scales efficiently: the time required to retrieve a message from a port set should be independent of the number of ports in that set.
		
		
		///
		public init() {
			
		}
		
		deinit {
			self.stop()
			// release vm!
		}
		
		///
		public func start() {
			// mutex lock
			// create thread
			// wait for thread to spin up
			// mutex unlock
			self.isRunning = true
		}
		
		///
		public func stop() {
			self.isRunning = false
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
