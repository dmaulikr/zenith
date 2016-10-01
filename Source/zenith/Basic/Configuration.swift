import Toml

class Configuration {

    static func load(name: String) -> Toml {
        return try! Toml(contentsOfFile: Assets.configPath + "\(name).cfg")
    }
}

protocol Configurable {

    static var config: Toml { get }
}

private var spriteRectCache = Dictionary<String, (Rect<Int>, spriteMultiplicity: Int)>()

extension Configurable {
    
    static func spriteRect(id: String, offset: Vector2i = Vector2(0, 0)) -> Rect<Int> {
        if let spriteRectData = spriteRectCache[id] {
            return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
        }

        let positionArray: [Int] = Self.config.array(id, "spritePosition")!
        var spritePosition = Vector2(positionArray[0], positionArray[1])
        let spriteMultiplicity = Self.config.int(id, "spriteMultiplicity")
        spritePosition *= tileSize

        let spriteRectData = (Rect(position: spritePosition, size: tileSizeVector),
                              spriteMultiplicity ?? 1)
        spriteRectCache[id] = spriteRectData
        return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
    }

    private static func createSpriteRect(from data: (Rect<Int>, Int)) -> Rect<Int> {
        return data.0.moved(by: Vector2(Int.random(0..<data.1)! * tileSize, 0))
    }
}
