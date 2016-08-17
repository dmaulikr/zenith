import Foundation

class Structure: Object, SpriteHelper {

    let sprite: Sprite

    static let config = Configuration.load(name: "structure")

    override init(id: String) {
        sprite = Sprite(fileName: Assets.graphicsPath + "structure.bmp",
                        textureRegion: Structure.spriteRect(id: id))
        super.init(id: id)
        addComponents(config: Structure.config)
    }

    override func render() {
        sprite.render()
    }

    var blocksSight: Bool {
        for component in components {
            if (component as! StructureComponent).blocksSight {
                return true
            }
        }
        return false
    }

    var preventsMovement: Bool {
        for component in components {
            if (component as! StructureComponent).preventsMovement {
                return true
            }
        }
        return false
    }

    func reactToMovementAttempt(of mover: Creature) {
        for component in components {
            (component as! StructureComponent).reactToMovementAttempt(of: mover)
        }
    }

    func tryToClose(closer: Creature) {
        for component in components {
            if let closeable = component as? Closeable {
                closeable.close(closer: closer)
            }
        }
    }

    func beKicked(by kicker: Creature, direction kickDirection: Direction4) {
        kicker.addMessage("You kick \(name(.definite)).")
    }

    // TODO: Remove this copy-paste code.
    typealias SpawnRateArray = Array<(id: String, levels: Array<Int>, spawnRate: Double)>
    private static var _spawnRates = SpawnRateArray()
    static var spawnRates: SpawnRateArray {
        if _spawnRates.isEmpty {
            // Initialize from config file
            for key in Structure.config.keys {
                let id = key.components(separatedBy: CharacterSet(charactersIn: "[\", ]"))[2]
                if let spawnRate = try? Structure.config.double(id, "spawnRate") {
                    _spawnRates.append((id: id,
                                        levels: try! Structure.config.array(id, "levels"),
                                        spawnRate: spawnRate))
                }
            }
        }
        return _spawnRates
    }
}
