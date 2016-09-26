import CSDL2

public class Application {

    public let window: Window
    private var stateStack: Array<State>
    private var activeState: State? { return stateStack.last }
    private var running: Bool
    private let frameTimer: Timer

    /// The number of seconds since the last call to `update`, i.e. the time it
    /// took to process the last frame. Use this to scale the amount of updating
    /// to be done. [More info](https://en.wikipedia.org/wiki/Delta_timing).
    public private(set) var deltaTime: Float = 0

    public init(size: Vector2i, title: String = "") {
        window = Window(size: size, title: title)
        stateStack = Array<State>()
        running = false
        frameTimer = Timer()
    }

    public func pushState(_ state: State) {
        stateStack.append(state)
        state.enter()
    }

    public func popState() {
        stateStack.removeLast()
    }

    public func run() {
        running = true

        while running {
            activeState?.update()
            deltaTime = Float(frameTimer.elapsedTime) / 1000
            frameTimer.restart()
            if activeState?.shouldRenderStateBelow ?? false {
                stateStack[stateStack.endIndex - 2].render()
            }
            activeState?.render()
            window.display()
            window.clear()
            SDL_Delay(2)
            handleEvents()
        }
    }

    public func stop() {
        running = false
    }

    private func handleEvents() {
        var event = SDL_Event()
        SDL_WaitEvent(&event)
        handleEvent(event)
    }

    private func handleEvent(_ event: SDL_Event) {
        switch SDL_EventType(event.type) {
            case SDL_KEYDOWN:
                handleKeyPressEvent(event)
            case SDL_KEYUP:
                handleKeyReleaseEvent(event)
            case SDL_WINDOWEVENT:
                handleWindowEvent(event)
            case SDL_QUIT:
                running = false
            default:
                break
        }
    }

    private func handleKeyPressEvent(_ event: SDL_Event) {
        activeState?.keyWasPressed(key: event.key.keysym.sym)
    }

    private func handleKeyReleaseEvent(_ event: SDL_Event) {
        activeState?.keyWasReleased(key: event.key.keysym.sym)
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
