import CSDL2

public class Timer {

    public typealias TimeType = Int

    private var startTime: TimeType

    /// Number of milliseconds since the timer was last restarted.
    public var elapsedTime: TimeType {
        return Timer.currentTime - startTime
    }

    public init() {
        startTime = Timer.currentTime
    }

    public func restart() {
        startTime = Timer.currentTime
    }

    private static var currentTime: TimeType {
        return TimeType(SDL_GetTicks())
    }
}
