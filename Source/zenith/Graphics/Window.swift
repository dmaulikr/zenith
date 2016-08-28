import CSDL2

public class Window {

    private var window: OpaquePointer?
    private let dpiScale: Double
    private var frameTexture: OpaquePointer
    private var frameSurface: UnsafeMutablePointer<SDL_Surface>

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
        dpiScale = Double(scale.x)

        frameTexture = SDL_CreateTexture(renderer, UInt32(SDL_PIXELFORMAT_RGB888),
                                         Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
                                         Int32(size.x), Int32(size.y))
        frameSurface = SDL_CreateRGBSurface(0, Int32(size.x), Int32(size.y), 32, 0, 0, 0, 0)
        targetSurface = frameSurface
    }

    deinit {
        SDL_FreeSurface(frameSurface)
        SDL_DestroyTexture(frameTexture)
        SDL_DestroyRenderer(renderer)
        SDL_DestroyWindow(window)
        SDL_Quit()
    }

    public var resolution: Vector2i {
        get {
            return Vector2i(Vector2d(size) / scale)
        }
        set {
            size = Vector2i(Vector2d(newValue) * scale)
            recreateFrameTextureAndSurface()
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

    public var scale: Double {
        get {
            var scale = Float(0)
            SDL_RenderGetScale(renderer, &scale, nil)
            return Double(scale) / dpiScale
        }
        set {
            size = Vector2(Vector2d(size) * Double(newValue) / Double(scale))
            let actualScale = Float(newValue * Double(dpiScale))
            SDL_RenderSetScale(renderer, actualScale, actualScale)
        }
    }

    public var isHighDPI: Bool {
        return dpiScale >= 2
    }

    public func clear() {
        SDL_FillRect(frameSurface, nil, SDL_MapRGB(frameSurface.pointee.format, 0, 0, 0))
    }

    public func display() {
        var pixels: UnsafeMutableRawPointer? = nil
        var pitch: Int32 = 0

        SDL_LockTexture(frameTexture, nil, &pixels, &pitch)
        memcpy(pixels, frameSurface.pointee.pixels, Int(pitch * frameSurface.pointee.h))
        SDL_UnlockTexture(frameTexture)

        SDL_RenderCopy(renderer, frameTexture, nil, nil)
        SDL_RenderPresent(renderer)
    }

    private func recreateFrameTextureAndSurface() {
        frameTexture = SDL_CreateTexture(renderer, UInt32(SDL_PIXELFORMAT_RGB888),
                                         Int32(SDL_TEXTUREACCESS_STREAMING.rawValue),
                                         Int32(resolution.x), Int32(resolution.y))
        frameSurface = SDL_CreateRGBSurface(0, Int32(resolution.x), Int32(resolution.y), 32, 0, 0, 0, 0)
        targetSurface = frameSurface
    }
}

private(set) var renderer: OpaquePointer!

func fatalSDLError() -> Never {
    fatalError(String(cString: SDL_GetError()))
}
