import Basic
import Graphics

public final class Structure: Object, Configurable, Spawnable {

    var sprite: Sprite
    weak var tile: Tile!

    public static let config = Configuration.load(name: "structure")

    public init(type: String) {
        sprite = Sprite(fileName: Assets.graphicsPath + "structure.bmp",
                        bitmapRegion: Structure.spriteRect(forObjectType: type))
        super.init(type: type, config: Structure.config)
        addComponents(config: Structure.config)
    }

    func render() {
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

    func beHit(by hitter: Creature, direction hitDirection: Direction4, style: AttackStyle) {
        hitter.addMessage("You \(style.verb) \(name(.definite)).")
    }

    static var _spawnInfoMap = SpawnInfoMap()
}
