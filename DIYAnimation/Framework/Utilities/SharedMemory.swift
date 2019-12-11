import Foundation.NSData

// TODO: ShmemBitmap: new, retain, release, copy, LOD[width/height/data/rowbytes],
// 					  create[cg]image, fill, incrementSeed, createContext

/// A container for a piece of memory that is shared among multiple threads or
/// processes.
internal final class SharedMemory: RenderValue {
    
    /// The access protection level of the `SharedMemory` instance, local or remote.
    internal struct Access: OptionSet {
        internal var rawValue: Int32
        internal init(rawValue: Int32) {
            self.rawValue = rawValue
        }
        
        /// The receiver is readable.
        internal static let read = Access(rawValue: 1 << 0)
        
        /// The receiver is writable.
        internal static let write = Access(rawValue: 1 << 1)
    }
    
    /// Maintains a list of all `SharedMemory`s allocated by the client process.
    internal static var allAllocations: [Weak<SharedMemory>] = [] // TODO: lock against this
    
    /// The pointer containing access to the receiver.
    internal lazy var pointer: UnsafeMutableRawBufferPointer = {
        let ptr = UnsafeMutableRawPointer(bitPattern: UInt(self.address))!
        return UnsafeMutableRawBufferPointer(start: ptr, count: Int(self.size))
    }()
    
    /// The `Data` wrapping the receiver's contents, referencing it.
    ///
    /// **Note:** The destruction of this object does not lead to the destruction
    /// of the contents of the receiver. Maintain a strong reference to it!
    internal lazy var data: Data = {
        return Data(bytesNoCopy: self.pointer.baseAddress!, count: self.pointer.count,
                    deallocator: .none)
    }()
    
    /// The local-only address mapped from the receiving `SharedMemory` instance.
    private var address: mach_vm_address_t = 0
    
    /// The size of the memory connected by the receiver. Not page-aligned.
    private var size: mach_vm_size_t = 0
    
    /// The memory entry-containing object to send over the wire to connect.
    internal private(set) var port: MachPort = .null
    
    /// The reserved page-aligned size of memory from `size`.
    private var pageSize: mach_vm_size_t {
        return mach_round_page(self.size)
    }
    
    /// Change the access protection level of the receiver; this affects all
    /// connected `SharedMemory` instances.
    internal var access: Access {
        get {
            
            // Do some weird pointer magic to get the VM region data:
            var info = vm_region_basic_info_data_t()
            let info_ptr = {
                (_ o: UnsafeMutableRawPointer) -> vm_region_info_t in
                o.assumingMemoryBound(to: Int32.self)
            } (&info)
            
            // Grab the region's VM info, convert from `VM_PROT` to `Access`:
            var count: mach_msg_type_number_t = 0
            var sz = self.pageSize
            mach_vm_region(mach_task_self_, &self.address, &sz,
                           VM_REGION_BASIC_INFO_64, info_ptr, &count, nil)
            return Access(rawValue: info.protection)
        }
        set {
            mach_vm_protect(mach_task_self_, self.address, self.pageSize,
                            0, newValue.rawValue)
        }
    }
    
    /// Mark the receiver as volatile, and able to be reclaimed by the kernel if
    /// the system is under memory constraints.
    internal var isVolatile: Bool {
        get {
            var state: Int32 = -1
            mach_vm_purgable_control(mach_task_self_, self.address,
                                     VM_PURGABLE_GET_STATE, &state)
            return state != VM_PURGABLE_NONVOLATILE /* empty is also a volatility */
        }
        set {
            let state = newValue ? VM_PURGABLE_VOLATILE : VM_PURGABLE_NONVOLATILE
            mach_vm_purgable_control(mach_task_self_, self.address, state, nil)
        }
    }
    
    /// Create a local `SharedMemory` instance.
    internal init(_ size: UInt64) throws {
        self.size = size
        var pageSize = self.pageSize
        
        // Create a new VM allocation and create a global memory entry:
        //
        // Note: `vm_map(...) with a NULL port is equivalent to `vm_allocate(...)`,
        //       `vm_protect(...)`, and `vm_inhert(...)` in a single call.
        var res = KERN_SUCCESS
        res = mach_vm_map(mach_task_self_, &self.address, pageSize, 0,
                          VM_FLAGS_ANYWHERE | VM_FLAGS_PURGABLE, 0, 0, 0,
                          VM_PROT_READ | VM_PROT_WRITE, VM_PROT_READ | VM_PROT_WRITE, VM_INHERIT_NONE)
        guard res == KERN_SUCCESS else { throw res }
        var _port: mach_port_t = 0
        res = mach_make_memory_entry_64(mach_task_self_, &pageSize, address,
                                        VM_PROT_READ | VM_PROT_WRITE, &_port, 0)
        self.port = MachPort(port: _port) // TODO: maybe make this lazy?
        guard res == KERN_SUCCESS else {
            mach_vm_deallocate(mach_task_self_, self.address, pageSize)
            throw res
        }
        assert(size <= pageSize, "Allocated size is smaller than requested size!")
        
        SharedMemory.allAllocations.append(Weak(self))
    }
    
    /// Connect to a remote `SharedMemory` instance.
    internal init(_ size: UInt64, _ port: MachPort) throws {
        self.size = size
        self.port = port
        
        // Map the remote VM allocation from a global memory entry:
        var res = KERN_SUCCESS
        res = mach_vm_map(mach_task_self_, &self.address, self.pageSize, 0,
                          VM_FLAGS_ANYWHERE | VM_FLAGS_PURGABLE, self.port.port, 0, 0,
                          VM_PROT_READ | VM_PROT_WRITE, VM_PROT_READ | VM_PROT_WRITE, VM_INHERIT_NONE)
        guard res == KERN_SUCCESS else { throw res }
        
        SharedMemory.allAllocations.append(Weak(self))
    }
    
    /// Deallocate both the port and the VM pages on both ends of the memory.
    deinit {
        mach_vm_deallocate(mach_task_self_, self.address, self.pageSize)
        SharedMemory.allAllocations.removeAll { $0.value == self }
    }
}

/// Wrappers for `#define`s in the `mach_vm_*` APIs.

fileprivate let mach_vm_page_size = mach_vm_size_t(vm_page_size)
fileprivate func mach_trunc_page(_ x: mach_vm_size_t) -> mach_vm_size_t {
    return ((x) & (~(mach_vm_page_size - 1)));
}
fileprivate func mach_round_page(_ x: mach_vm_size_t) -> mach_vm_size_t {
    return mach_trunc_page((x) + (mach_vm_page_size - 1));
}
extension kern_return_t: Error {}
