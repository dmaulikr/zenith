import CSDL2

public class Window {

    private var window: OpaquePointer?
    private let dpiScale: Float
    public var clearColor: Color

    public init(size: Vector2i, title: String = "") {
        SDL_Init(Uint32(SDL_INIT_VIDEO))

        window = SDL_CreateWindow(title,
                                  SDL_WINDOWPOS_CENTERED_MASK, SDL_WINDOWPOS_CENTERED_MASK,
                                  Int32(size.x), Int32(size.y), SDL_WINDOW_ALLOW_HIGHDPI.rawValue)
        guard window != nil else { fatalSDLError() }

        renderer = SDL_CreateRenderer(window, -1, 0)
        guard renderer != nil else { fatalSDLError() }

        var outputSize = Vector2<Int32>(0, 0)
        SDL_GetRendererOutputSize(renderer, &outputSize.x, &outputSize.y)
        let scale = Vector2f(outputSize) / Vector2f(size)
        SDL_RenderSetScale(renderer, scale.x, scale.y)
        dpiScale = scale.x

        clearColor = Color.black
    }

    deinit {
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(window)
        SDL_Quit()
    }

    public var resolution: Vector2i {
        get {
            return size / scale
        }
        set {
            size = newValue * scale
        }
    }

    public var size: Vector2i {
        get {
            var size = Vector2<Int32>(0, 0)
            SDL_GetWindowSize(window, &size.x, &size.y)
            return Vector2i(size)
        }
        set {
            // Maintain window center position when resizing.
            var position = Vector2<Int32>(0, 0)
            SDL_GetWindowPosition(window, &position.x, &position.y)
            position += Vector2<Int32>((size - newValue) / 2)
            SDL_SetWindowPosition(window, position.x, position.y)
            SDL_SetWindowSize(window, Int32(newValue.x), Int32(newValue.y))
        }
    }

    public var scale: Int {
        get {
            var scale = Float(0)
            SDL_RenderGetScale(renderer, &scale, nil)
            return Int(scale / dpiScale)
        }
        set {
            size = Vector2(Vector2d(size) * Double(newValue) / Double(scale))
            let actualScale = Float(newValue * Int(dpiScale))
            SDL_RenderSetScale(renderer, actualScale, actualScale)
        }
    }

    public func clear() {
        SDL_SetRenderDrawColor(renderer, clearColor.red, clearColor.green, clearColor.blue, clearColor.alpha)
        SDL_RenderClear(renderer)
    }

    public func display() {
        SDL_RenderPresent(renderer)
    }
}

private(set) var renderer: OpaquePointer!

func fatalSDLError() -> Never {
    fatalError(String(cString: SDL_GetError()))
}
