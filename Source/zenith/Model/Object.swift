import Toml

/// A physical in-game object that has a name.
class Object: Entity, CustomStringConvertible {

    let id: String
    private let name: Name

    init(id: String) {
        self.id = id
        name = Name(id)
        super.init()
    }

    var description: String {
        return name()
    }

    func name(_ flags: NameFlag...) -> String {
        return name.name(flags: flags)
    }

    func addComponents(config: Toml) {
        config.array(id, "components")?.forEach {
            addComponent(createComponent($0))
        }
    }

    func createComponent(_ name: String) -> Component {
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

/// About the `SpawnInfo` members:
///
/// - `levels` defines where to spawn the object.
///   -1 means underground, 0 means on the ground level, 1 means above the ground level.
///
/// - `spawnRate` defines how often to spawn the object.
///   0 means never, 0.5 means on every other tile (on average), 1 means on every tile.
///
/// - `populationDensityFactor` defines how the population density of an area affects the
///   spawn rate of the object.
///   0 will prefer low-density areas, 1 will prefer high-density areas.
typealias SpawnInfo = (levels: [Int], spawnRate: Double, populationDensityFactor: Double)
typealias SpawnInfoMap = [String: SpawnInfo]

protocol Spawnable: Configurable {

    static var _spawnInfoMap: SpawnInfoMap { get set }
}

extension Spawnable {

    static var spawnInfoMap: SpawnInfoMap {
        if _spawnInfoMap.isEmpty {
            // Initialize from config file
            for (id, data) in config.tables() {
                if let spawnRate = data.double("spawnRate") {
                    let levels = data.array("levels") ?? [-1, 0, 1]
                    _spawnInfoMap[id] = (
                        levels: levels,
                        spawnRate: spawnRate,
                        populationDensityFactor: data.double("spawnRatePopulationDensityFactor") ?? 0.5
                    )
                }
            }
        }
        return _spawnInfoMap
    }
}
