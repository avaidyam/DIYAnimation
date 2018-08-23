import Foundation

// TODO: media timing cache: getRenderTiming(obj), invalidate(obj), lock/unlock

///
public protocol MediaTiming {
    
    ///
    var beginTime: TimeInterval { get set }
    
    ///
    var duration: TimeInterval { get set }
    
    ///
    var speed: TimeInterval { get set }
    
    ///
    var timeOffset: TimeInterval { get set }
    
    ///
    var repeatCount: Int { get set }
    
    ///
    var repeatDuration: TimeInterval { get set }
    
    ///
    var autoreverses: Bool { get set }
    
    ///
    var fillMode: Animation.FillMode { get set }
}

/// The current media time used by all layer and animation objects.
public func CurrentMediaTime() -> TimeInterval {
    return TimeWithHostTime(mach_absolute_time())
}

/// Convert the given `mach_absolute_time` to a normalized `time`.
internal func TimeWithHostTime(_ time: UInt64) -> TimeInterval {
    return TimeInterval(time * _timescale.forward) / 1_000_000_000
}

/// Convert the given normalized `time` to a `mach_absolute_time`.
internal func HostTimeWithTime(_ time: TimeInterval) -> UInt64 {
    return UInt64(time * 1_000_000_000) * _timescale.reverse
}

// Initialize and store once; could be costly to do multiple times.
private let _timescale: (forward: UInt64, reverse: UInt64) = {
    var info = mach_timebase_info()
    guard mach_timebase_info(&info) == KERN_SUCCESS else {
        fatalError("Couldn't initialize the timing subsystem.")
    }
    return (forward: UInt64(info.numer) / UInt64(info.denom),
            reverse: UInt64(info.denom) / UInt64(info.numer))
}()
