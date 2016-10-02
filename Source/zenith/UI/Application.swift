import CSDL2

public class Application {

    public let window: Window
    private var stateStack: [State]
    private var activeState: State? { return stateStack.last }
    private var running: Bool
    private let frameTimer: Timer
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

    public func pushState(_ state: State) {
        stateStack.append(state)
        state.enter()
    }

    public func popState() {
        stateStack.removeLast()
        if runningTemporaryState { stop() }
    }

    public func run() {
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

    public func runTemporaryState() {
        runningTemporaryState = true
        let wasRunning = running
        run()
        running = wasRunning
        runningTemporaryState = false
    }

    public func stop() {
        running = false
    }

    public func waitForKeyPress() -> SDL_Keycode {
        var event = SDL_Event()
        while true {
            SDL_WaitEvent(&event)
            switch SDL_EventType(event.type) {
                case SDL_KEYDOWN:
                    return event.key.keysym.sym
                default:
                    handleSystemEvent(event)
            }
        }
    }

    private func handleEvents() {
        var event = SDL_Event()
        while SDL_PollEvent(&event) != 0 {
            handleEvent(event)
        }
    }

    private func handleEvent(_ event: SDL_Event) {
        switch SDL_EventType(event.type) {
            case SDL_KEYDOWN:
                handleKeyPressEvent(event)
            case SDL_KEYUP:
                handleKeyReleaseEvent(event)
            default:
                handleSystemEvent(event)
        }
    }

    private func handleKeyPressEvent(_ event: SDL_Event) {
        activeState?.keyWasPressed(key: event.key.keysym.sym)
    }

    private func handleKeyReleaseEvent(_ event: SDL_Event) {
        activeState?.keyWasReleased(key: event.key.keysym.sym)
    }

    private func handleSystemEvent(_ event: SDL_Event) {
        switch SDL_EventType(event.type) {
            case SDL_WINDOWEVENT:
                handleWindowEvent(event)
            case SDL_QUIT:
                running = false
            default:
                break
        }
    }

    private func handleWindowEvent(_ event: SDL_Event) {
        switch SDL_WindowEventID(UInt32(event.window.event)) {
            case SDL_WINDOWEVENT_CLOSE:
                running = false
            default:
                break
        }
    }
}
