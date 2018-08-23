import Foundation

extension Render {
    
    /// A cacheable sub-container for `Animation` and `Layer` to host their timing info.
    internal struct Timing: MediaTiming, RenderValue {
        var beginTime: TimeInterval = 0.0
        var duration: TimeInterval = 0.0
        var speed: TimeInterval = 0.0
        var timeOffset: TimeInterval = 0.0
        var repeatCount: Int = 0
        var repeatDuration: TimeInterval = 0.0
        var autoreverses: Bool = false
        var fillMode: DIYAnimation.Animation.FillMode = .removed
        
        ///
        var activeDuration: TimeInterval {
            return 0.0
        }
        
        ///
        var endTime: TimeInterval {
            return self.beginTime + self.activeDuration
        }
        
        ///
        func next(beginTime: TimeInterval) -> TimeInterval {
            return 0.0
        }
        
        ///
        func map(time: Double) -> Double {
            // map parent to active
            // map active to local
            return 0.0
        }
        
        ///
        func inverseMap(time: Double) -> Double {
            // map local to active
            // map active to parent
            return 0.0
        }
        
        ///
        func map(activeToLocal: Double) -> Double {
            return 0.0
        }
        
        ///
        func map(activeToParent: Double) -> Double {
            return 0.0
        }
        
        ///
        func map(localToActive: Double) -> Double {
            return 0.0
        }
        
        ///
        func map(parentToActive: Double) -> Double {
            return 0.0
        }
    }
}



/*
        TimeInterval parentToActiveTime(TimeInterval tp) const {
            return (tp - beginTime()) * speed() + timeOffset();
        }

        TimeInterval activeToParentTime(TimeInterval t) const {
            return (t - timeOffset()) / speed() + beginTime();
        }

        TimeInterval activeToLocalTime(TimeInterval tp) const {
            // If total duration < tp or tp < 0, account for fillmode
            double totalRepeats = tp / duration();
            double progress = totalRepeats - (int)totalRepeats;
 
            // derive repeatCount from repeatDuration
            double repeats = 1.0;
 
            if (repeatCount() > 0.0) {
                repeats = repeatCount();
            }
 
            if (autoreverses()) {
                repeats *= 2.0;
 
                if ((int)totalRepeats % 2 == 1) {
                    progress = 1 - progress;
                }
            }
 
            if (repeatDuration() > 0.0) {
                repeats = repeatDuration() / duration();
            }
 
            repeats += timeOffset() / duration();
 
            double activeDuration = repeats * duration();
 
            if (tp < 0.0) {
                switch (fillMode()) {
                    case Removed:
                        progress = 1.001;
                        break;
                    case Forwards:
                        progress = -0.001;
                        break;
                    case Backwards:
                        progress = 0.0;
                        break;
                    case ForwardsBackwards:
                        progress = 0.0;
                        break;
                    default:
                        break;
                }
 
            } else if (tp > activeDuration) {
                switch (fillMode()) {
                    case Removed:
                        progress = 1.001;
                        break;
                    case Forwards:
                        progress = 1.0;
                        break;
                    case Backwards:
                        progress = -0.001;
                        break;
                    case ForwardsBackwards:
                        progress = 1.0;
                        break;
                    default:
                        break;
                }
            }
 
            return progress;
        };
*/





