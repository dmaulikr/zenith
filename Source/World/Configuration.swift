import Toml
import Basic

public struct Assets {
    public static let assetsPath = #file.substring(to: #file.range(of: "/", options: .backwards)!.upperBound) + "../../"
    public static let configPath = assetsPath + "Config/"
    public static let graphicsPath = assetsPath + "Graphics/"
    public static let savedGamePath = assetsPath + ".SavedGame/"
    public static let globalSavePath = savedGamePath + "global.dat"
    public static let preferencesPath = assetsPath + "preferences.cfg"
}

public class Configuration {

    public static func load(name: String) -> Toml {
        return try! Toml(contentsOfFile: Assets.configPath + "\(name).cfg")
    }
}

public protocol Configurable {

    static var config: Toml { get }
}

private var spriteRectCache = [String: (Rect<Int>, spriteMultiplicity: Int)]()

extension Configurable {

    static func spriteRect(forObjectType type: String, offset: Vector2i = Vector2(0, 0)) -> Rect<Int> {
        if let spriteRectData = spriteRectCache[type] {
            return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
        }

        let positionArray: [Int] = Self.config.array(type, "spritePosition")!
        var spritePosition = Vector2(positionArray[0], positionArray[1])
        let spriteMultiplicity = Self.config.int(type, "spriteMultiplicity")
        spritePosition *= tileSize

        let spriteRectData = (Rect(position: spritePosition, size: tileSizeVector),
                              spriteMultiplicity ?? 1)
        spriteRectCache[type] = spriteRectData
        return createSpriteRect(from: spriteRectData).moved(by: offset * tileSize)
    }

    private static func createSpriteRect(from data: (Rect<Int>, Int)) -> Rect<Int> {
        return data.0.moved(by: Vector2(Int.random(0..<data.1)! * tileSize, 0))
    }
}
