import Foundation
import Basic
import Graphics
import CSDL2

final class Liquid: Object, Configurable {

    private let amount: Double
    private let sprite: Sprite
    public static let config = Configuration.load(name: "material")

    init(type: String, amount: Double) {
        self.amount = amount
        sprite = Sprite(image: Bitmap(size: tileSizeVector))
        super.init(type: type, config: Liquid.config)
        addComponents(config: Liquid.config)
        createSprite()
    }

    convenience init(deserializedFrom stream: InputStream) {
        self.init(type: stream.readString(), amount: stream.readDouble())
    }

    deinit {
        sprite.deallocate()
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
        stream <<< type <<< amount
    }

    override func deserialize(from stream: InputStream) {
        assertionFailure("use Liquid.init(deserializedFrom:)")
    }
}
