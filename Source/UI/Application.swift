import CSDL2
import Basic
import Graphics

public struct Application {

    public let window: Window
    private var stateStack: [State]
    private var activeState: State? { return stateStack.last }
    private var running: Bool
    private var frameTimer: Timer
    private var runningTemporaryState: Bool = false

    /// The number of seconds since the last call to `update`, i.e. the time it
    /// took to process the last frame. Use this to scale the amount of updating
    /// to be done. [More info](https://en.wikipedia.org/wiki/Delta_timing).
    public private(set) var deltaTime: Float = 0

    public init(size: Vector2i, title: String = "") {
        window = Window(size: size, title: title)
        stateStack = [State]()
        running = false
        frameTimer = Timer()
    }

    public mutating func pushState(_ state: State) {
        stateStack.append(state)
        state.enter()
    }

    public mutating func popState() {
        stateStack.removeLast()
        if runningTemporaryState { stop() }
    }

    public mutating func run() {
        running = true

        while running {
            deltaTime = Float(frameTimer.elapsedTime) / 1000
            frameTimer.restart()
            if activeState?.shouldRenderStateBelow ?? false {
                stateStack[stateStack.endIndex - 2].render()
            }
            activeState?.render()
            window.display()
            window.clear()
            SDL_Delay(2)
            activeState?.update()
            handleEvents()
        }
    }

    public mutating func runTemporaryState() {
        runningTemporaryState = true
        let wasRunning = running
        run()
        running = wasRunning
        runningTemporaryState = false
    }

    public mutating func stop() {
        running = false
    }

    public mutating func waitForKeyPress() -> SDL_Keycode {
        var event = SDL_Event()
        while true {
            SDL_WaitEvent(&event)
            switch SDL_EventType(event.type) {
                case SDL_KEYDOWN:
                    return event.key.keysym.sym
                default:
                    _ = handleSystemEvent(event)
            }
        }
    }

    public func pollForKeyPress() -> SDL_Keycode? {
        var event = SDL_Event()
        var removedEvents = [SDL_Event]()
        var result: SDL_Keycode? = nil

        while SDL_PollEvent(&event) != 0 {
            if SDL_EventType(event.type) == SDL_KEYDOWN {
                result = event.key.keysym.sym
                break
            }
            removedEvents.append(event)
        }
        for var event in removedEvents { SDL_PushEvent(&event) }
        return result
    }

    private mutating func handleEvents() {
        var event = SDL_Event()
        var unhandledEvents = [SDL_Event]()

        while SDL_PollEvent(&event) != 0 {
            if !handleEvent(event) {
                unhandledEvents.append(event)
            }
        }
        for var event in unhandledEvents { SDL_PushEvent(&event) }
    }

    private mutating func handleEvent(_ event: SDL_Event) -> Bool {
        switch SDL_EventType(event.type) {
            case SDL_KEYDOWN:
                return handleKeyPressEvent(event)
            default:
                return handleSystemEvent(event)
        }
    }

    private func handleKeyPressEvent(_ event: SDL_Event) -> Bool {
        return activeState?.keyWasPressed(key: event.key.keysym.sym) ?? false
    }

    private mutating func handleSystemEvent(_ event: SDL_Event) -> Bool {
        switch SDL_EventType(event.type) {
            case SDL_WINDOWEVENT:
                return handleWindowEvent(event)
            case SDL_QUIT:
                running = false
                return true
            default:
                return false
        }
    }

    private mutating func handleWindowEvent(_ event: SDL_Event) -> Bool {
        switch SDL_WindowEventID(UInt32(event.window.event)) {
            case SDL_WINDOWEVENT_CLOSE:
                running = false
                return true
            default:
                return false
        }
    }
}

public var app: Application!
public var font: Font! // FIXME: Should be of type Font.
