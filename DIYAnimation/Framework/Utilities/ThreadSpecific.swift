
///
internal final class ThreadLocal<Element> {
    
    ///
    private final class Wrapper {
        var value: Element?
        weak var parent: ThreadLocal<Element>?
        init(_ value: Element?, _ parent: ThreadLocal<Element>) {
            self.value = value
            self.parent = parent
        }
    }
    
    ///
    private var key = pthread_key_t()
    
    ///
    private var destructor: ((Element?) -> ())? = nil
    
    ///
    internal init(_ destructor: @escaping (Element?) -> ()) {
        pthread_key_create(&self.key, {
            let unmanaged = Unmanaged<AnyObject>.fromOpaque($0)
            //let wrapper = unmanaged.takeUnretainedValue()
            //wrapper.parent?.destructor?(wrapper.value)
            unmanaged.release()
        })
    }
    
    ///
    deinit {
        pthread_key_delete(self.key)
    }
    
    ///
    internal var value: Element? {
        get {
            guard let ptr = pthread_getspecific(self.key) else { return nil }
            return Unmanaged<Wrapper>.fromOpaque(ptr).takeUnretainedValue().value
        }
        set {
            if let ptr = pthread_getspecific(self.key) {
                Unmanaged<AnyObject>.fromOpaque(ptr).release()
            }
            let val = Unmanaged.passRetained(Wrapper(newValue, self)).toOpaque()
            pthread_setspecific(self.key, val)
        }
    }
}
