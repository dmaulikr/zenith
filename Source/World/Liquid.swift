import Foundation
import Basic
import Graphics
import CSDL2

final class Liquid: Object, Configurable {

    private unowned let tileUnder: Tile
    private let amount: Double
    private var fadeLevel: Double
    private let sprite: Sprite
    private static let fadeStep = 0.001
    public static let config = Configuration.load(name: "material")

    init(tile: Tile, type: String, amount: Double) {
        tileUnder = tile
        self.amount = amount
        fadeLevel = 1
        sprite = Sprite(image: Bitmap(size: tileSizeVector))
        super.init(type: type, config: Liquid.config)
        addComponents(config: Liquid.config)
        createSprite()
    }

    convenience init(deserializedFrom stream: InputStream, tile: Tile) {
        self.init(tile: tile, type: stream.readString(), amount: stream.readDouble())
        fadeLevel = stream.readDouble()
        SDL_SetSurfaceAlphaMod(sprite.surface, UInt8(fadeLevel * 255))
    }

    deinit {
        sprite.deallocate()
    }

    override func update() {
        let oldFadeLevel = fadeLevel
        fadeLevel = max(0, fadeLevel - Liquid.fadeStep)
        if UInt8(fadeLevel * 255) != UInt8(oldFadeLevel * 255) {
            SDL_SetSurfaceAlphaMod(sprite.surface, UInt8(fadeLevel * 255))
            tileUnder.invalidateRenderCache()
        }
    }

    var hasFadedAway: Bool {
        return fadeLevel <= 0
    }

    func render() {
        sprite.render()
    }

    private func createSprite() {
        let size1 = Int(amount) + (Double.random(0...1) < amount.remainder(dividingBy: 1) ? 1 : 0)
        let size2 = Int(amount) + (Double.random(0...1) < amount.remainder(dividingBy: 1) ? 1 : 0)
        let width = max(size1, size2), height = min(size1, size2)
        let position = Vector2(Int32(Int.random(0...tileSize-width)), Int32(Int.random(0...tileSize-height)))
        let color = Liquid.config.color(type, "color")!
        var liquidRectangle = SDL_Rect(x: position.x, y: position.y, w: Int32(width), h: Int32(height))

        SDL_FillRect(sprite.surface, &liquidRectangle,
                     SDL_MapRGBA(sprite.surface.pointee.format, color.red, color.green, color.blue,
                                 UInt8((1 - Liquid.config.double(type, "transparency")!) * 255)))
    }

    override func serialize(to stream: OutputStream) {
        stream <<< type <<< amount <<< fadeLevel
    }

    override func deserialize(from stream: InputStream) {
        assertionFailure("use Liquid.init(deserializedFrom:)")
    }
}
