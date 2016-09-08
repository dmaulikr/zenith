import Toml

/// A physical in-game object that has a name.
class Object: Entity, CustomStringConvertible {

    let id: String
    private let name: Name

    init(id: String) {
        self.id = id
        name = Name(id)
    }

    var description: String {
        return name()
    }

    func name(_ flags: NameFlag...) -> String {
        return name.name(flags: flags)
    }

    func addComponents(config: Toml) {
        config.array(id, "components")?.forEach {
            addComponent(getComponent(id: id, name: $0))
        }
    }

    func getComponent(id: String, name: String) -> Component {
        switch name {
            case "wall":
                return Wall()
            case "door":
                return Door(structure: self as! Structure, openSpritePositionOffset: Vector2(1, 0))
            case "dig":
                return Dig()
            default:
                fatalError("unknown component type '\(name)'")
        }
    }
}

typealias SpawnRateArray = Array<(id: String, levels: Array<Int>, spawnRate: Double)>

protocol Spawnable: Configurable {

    static var _spawnRates: SpawnRateArray { get set }
}

extension Spawnable {

    static var spawnRates: SpawnRateArray {
        if _spawnRates.isEmpty {
            // Initialize from config file
            for (id, data) in config.tables() {
                if let spawnRate = data.double("spawnRate") {
                    let levels = data.array("levels") ?? [-1, 0, 1]
                    _spawnRates.append((id: id, levels: levels, spawnRate: spawnRate))
                }
            }
        }
        return _spawnRates
    }
}
