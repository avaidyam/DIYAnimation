import Cocoa
autoreleasepool {
    var delegate: NSApplicationDelegate? = AppDelegate()
    withExtendedLifetime(delegate) {
        NSApplication.shared.delegate = delegate
        NSApplication.shared.run()
    }
    delegate = nil
}
