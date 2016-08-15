import Yaml

protocol SpriteHelper {

    static var config: Yaml { get }
}

private var spriteRectCache = Dictionary<String, (Rect<Int>, Int)>()

extension SpriteHelper {

    static func spriteRect(id: String, offset: Vector2i = Vector2(0, 0)) -> Rect<Int> {
        if let spriteRectData = spriteRectCache[id] {
            return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
        }

        let positionArray = Self.config[.String(id)]["spritePosition"]
        var spritePosition = Vector2(positionArray[0].int!, positionArray[1].int!)
        let spriteMultiplicity = Self.config[.String(id)]["spriteMultiplicity"]
        spritePosition *= tileSize

        let spriteRectData = (Rect(position: spritePosition, size: tileSizeVector),
                              spriteMultiplicity.int ?? 0)
        spriteRectCache[id] = spriteRectData
        return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
    }

    private static func createSpriteRect(from data: (Rect<Int>, Int)) -> Rect<Int> {
        return data.0.moved(by: Vector2(Int.random(0..<data.1) * tileSize, 0))
    }
}
