import CSDL2
import Basic

public protocol Font {

    func renderText(_: String, at: Vector2i, color: Color)

    func renderText(_: String, at: Vector2i, color: Color, align: Alignment)

    func textWidth(_: String) -> Int

    var height: Int { get }
}

/// A font that renders character sprites loaded from a bitmap.
public struct BitmapFont: Font {

    private let bitmap: Bitmap
    public let glyphSize: Vector2i

    /// - Parameter fileName: The image file that contains the character sprites.
    /// - Note: Currently only BMP files are supported.
    public init(fileName: String) {
        self.bitmap = Bitmap.get(fileName: fileName)
        self.glyphSize = self.bitmap.size / glyphCount
    }

    public func renderText(_ text: String, at position: Vector2i, color: Color) {
        renderText(text, at: position, color: color, align: .left)
    }

    public func renderText(_ text: String, at position: Vector2i, color: Color, align alignment: Alignment) {
        var position = Vector2<Int32>(position)
        switch alignment {
            case .left:   break
            case .center: position.x -= textWidth(text) / 2
            case .right:  position.x -= textWidth(text)
        }
        SDL_SetSurfaceColorMod(bitmap.surface, color.red, color.green, color.blue)
        SDL_SetSurfaceAlphaMod(bitmap.surface, color.alpha)

        for unicodeScalar in text.unicodeScalars {
            let i = Int(unicodeScalar.value - firstChar)
            let glyphPos = Vector2<Int32>(Vector2(i % glyphCount.x, i / glyphCount.x) * glyphSize)
            var src = SDL_Rect(x: glyphPos.x, y: glyphPos.y, w: Int32(glyphSize.x), h: Int32(glyphSize.y))
            var dst = SDL_Rect(x: position.x, y: position.y, w: Int32(glyphSize.x), h: Int32(glyphSize.y))
            position.x += src.w
            SDL_LowerBlit(bitmap.surface, &src, targetSurface, &dst)
        }
    }

    public func textWidth(_ text: String) -> Int {
        return text.characters.count * glyphSize.x
    }

    public var height: Int {
        return glyphSize.y
    }
}

private let glyphCount = Vector2(16, 6) // Glyphs per row/column in the font file.
private let firstChar = UInt32(0x20) // The first character in the font file.

public enum Alignment {
    case left
    case center
    case right
}
