import CSDL2

public struct Sprite {

    /// The current position in the coordinate system. The default is `(0, 0)`.
    public var position: Vector2i = Vector2(0, 0)

    public static var transparentColor: Color?
    private let texture: Texture

    /// The sub-region of the texture to use for this sprite.
    public var textureRegion: Rect<Int>

    /// Loads the sprite from a file.
    /// - Note: Currently only BMP files are supported.
    public init(fileName: String, textureRegion: Rect<Int>? = nil) {
        texture = Texture.get(fileName: fileName)
        let size = texture.size
        self.textureRegion = textureRegion ?? Rect(position: Vector2(0, 0), size: size)
    }

    init(texture: Texture, textureRegion: Rect<Int>? = nil) {
        self.texture = texture
        self.textureRegion = textureRegion ?? Rect(position: Vector2(0, 0), size: texture.size)
    }

    public func render() {
        var src = textureRegion.asSDLRect()
        var dst = SDL_Rect(x: Int32(position.x), y: Int32(position.y), w: src.w, h: src.h)
        SDL_RenderCopy(renderer, texture.sdlTexture, &src, &dst)
    }

    public func render(at position: Vector2i) {
        var src = textureRegion.asSDLRect()
        var dst = SDL_Rect(x: Int32(position.x), y: Int32(position.y), w: src.w, h: src.h)
        SDL_RenderCopy(renderer, texture.sdlTexture, &src, &dst)
    }

    init(fromSDLSurface surface: UnsafeMutablePointer<SDL_Surface>, window: Window) {
        texture = Texture(SDL_CreateTextureFromSurface(renderer, surface))
        textureRegion = Rect(position: Vector2(0, 0), size: texture.size)
    }
}

/// Memory-managing wrapper around `SDL_Texture`.
class Texture {

    let sdlTexture: OpaquePointer

    /// Textures loaded from image files. Keys are file paths.
    private static var textureCache = Dictionary<String, Texture>()

    var size: Vector2i {
        var size = Vector2<Int32>(0, 0)
        SDL_QueryTexture(sdlTexture, nil, nil, &size.x, &size.y)
        return Vector2i(size)
    }

    init(_ sdlTexture: OpaquePointer) {
        self.sdlTexture = sdlTexture
    }

    static func get(fileName: String) -> Texture {
        if let texture = Texture.textureCache[fileName] {
            return texture
        }
        let texture = Texture.loadFromFile(fileName)
        Texture.textureCache[fileName] = texture
        return texture
    }

    private static func loadFromFile(_ fileName: String) -> Texture {
        guard let sdlSurface = loadBitmapFromFile(fileName) else {
            fatalSDLError()
        }
        defer { SDL_FreeSurface(sdlSurface) }

        if let color = Sprite.transparentColor {
            let colorKey = SDL_MapRGB(sdlSurface.pointee.format,
                                      color.red, color.green, color.blue)
            SDL_SetColorKey(sdlSurface, 1, colorKey)
        }
        return Texture(SDL_CreateTextureFromSurface(renderer, sdlSurface))
    }

    private static func loadBitmapFromFile(_ fileName: String) -> UnsafeMutablePointer<SDL_Surface>? {
        guard let stream = SDL_RWFromFile(fileName, "rb") else { return nil }
        guard let surface = SDL_LoadBMP_RW(stream, 1) else { return nil }
        return surface
    }

    deinit {
        SDL_DestroyTexture(sdlTexture)
    }
}
