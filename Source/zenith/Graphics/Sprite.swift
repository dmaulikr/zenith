import CSDL2

public struct Sprite {

    /// The current position in the coordinate system. The default is `(0, 0)`.
    public var position: Vector2i = Vector2(0, 0)

    public static var transparentColor: Color?

    /// The underlying image containing the actual pixel data for this sprite.
    let bitmap: Bitmap

    /// The sub-rectangle of `image` to use for this sprite.
    public var bitmapRegion: Rect<Int>

    /// Loads the sprite from a file.
    /// - Note: Currently only BMP files are supported.
    public init(fileName: String, bitmapRegion: Rect<Int>? = nil) {
        bitmap = Bitmap.get(fileName: fileName)
        let size = bitmap.size
        self.bitmapRegion = bitmapRegion ?? Rect(position: Vector2(0, 0), size: size)
    }

    init(image: Bitmap, bitmapRegion: Rect<Int>? = nil) {
        self.bitmap = image
        self.bitmapRegion = bitmapRegion ?? Rect(position: Vector2(0, 0), size: image.size)
    }

    public func render() {
        render(at: position)
    }

    public func render(at position: Vector2i) {
        var src = bitmapRegion.asSDLRect()
        var dst = SDL_Rect(x: Int32(position.x), y: Int32(position.y), w: src.w, h: src.h)
        if let viewport = targetViewport {
            dst.x += viewport.x
            dst.y += viewport.y
        }
        SDL_UpperBlit(bitmap.surface, &src, targetSurface, &dst)
    }

    init(fromSDLSurface surface: UnsafeMutablePointer<SDL_Surface>) {
        bitmap = Bitmap(surface)
        bitmapRegion = Rect(position: Vector2(0, 0), size: bitmap.size)
    }
}

var targetSurface: UnsafeMutablePointer<SDL_Surface>!
var targetViewport: SDL_Rect?

/// Memory-managing wrapper around `SDL_Surface`.
class Bitmap {

    let surface: UnsafeMutablePointer<SDL_Surface>

    /// Bitmaps loaded from image files. Keys are file paths.
    private static var cache = Dictionary<String, Bitmap>()

    var size: Vector2i {
        return Vector2i(Int(surface.pointee.w), Int(surface.pointee.h))
    }

    init(_ surface: UnsafeMutablePointer<SDL_Surface>) {
        self.surface = surface
    }

    init(size: Vector2i) {
        surface = SDL_CreateRGBSurface(0, Int32(size.x), Int32(size.y), 32, 0, 0, 0, 0)
    }

    static func get(fileName: String) -> Bitmap {
        if let cachedBitmap = Bitmap.cache[fileName] {
            return cachedBitmap
        }
        let bitmap = Bitmap.loadFromFile(fileName)
        Bitmap.cache[fileName] = bitmap
        return bitmap
    }

    private static func loadFromFile(_ fileName: String) -> Bitmap {
        guard let sdlSurface = loadBitmapFromFile(fileName) else {
            fatalSDLError()
        }

        if let color = Sprite.transparentColor {
            let colorKey = SDL_MapRGB(sdlSurface.pointee.format,
                                      color.red, color.green, color.blue)
            SDL_SetColorKey(sdlSurface, 1, colorKey)
        }
        return Bitmap(sdlSurface)
    }

    private static func loadBitmapFromFile(_ fileName: String) -> UnsafeMutablePointer<SDL_Surface>? {
        guard let stream = SDL_RWFromFile(fileName, "rb") else { return nil }
        guard let surface = SDL_LoadBMP_RW(stream, 1) else { return nil }
        return surface
    }

    deinit {
        SDL_FreeSurface(surface)
    }
}
