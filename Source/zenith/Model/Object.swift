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
