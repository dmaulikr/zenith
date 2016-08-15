import Yaml

class Item: Object, SpriteHelper, Hashable, Equatable {

    weak var tileUnder: Tile? {
        didSet {
            if let tile = tileUnder {
                sprite.position = tile.position * tileSize
            }
        }
    }
    static let config: Yaml = Configuration.load(name: "item")
    let sprite: Sprite

    override init(id: String) {
        assert(Item.config[.String(id)] != nil)
        sprite = Sprite(fileName: Assets.graphicsPath + "item.bmp",
                        textureRegion: Item.spriteRect(id: id))
        super.init(id: id)
        addComponents(config: Item.config)
    }

    override func render() {
        sprite.render()
    }

    // TODO: Remove this copy-paste code.
    private static var _spawnRates = Array<(id: String, levels: Array<Int>, spawnRate: Double)>()
    static var spawnRates: Array<(id: String, levels: Array<Int>, spawnRate: Double)> {
        if _spawnRates.isEmpty {
            // Initialize from config file
            for (id, data) in Item.config.dictionary! {
                if data["spawnRate"] != nil {
                    _spawnRates.append((id: id.string!,
                                        levels: data["levels"].array!.map { $0.int! },
                                        spawnRate: data["spawnRate"].double!))
                }
            }
        }
        return _spawnRates
    }

    var isEdible: Bool {
        return Item.config[.String(id)]["isEdible"].bool == true
    }

    var isUsable: Bool {
        return Item.config[.String(id)]["isUsable"].bool == true
    }

    func use(world: World, gui: GraphicalUserInterface, user: Creature) {
        for component in components {
            (component as! ItemComponent).use(world: world, gui: gui, user: user)
        }
    }

    var leftover: Item? {
        if let leftoverID = Item.config[.String(id)]["leftover"].string {
            return Item(id: leftoverID)
        }
        return nil
    }

    var emitsLight: Bool {
        return Item.config[.String(id)]["lightColor"] != nil
    }

    var lightColor: Color {
        let hex = Int(String(Item.config[.String(id)]["lightColor"].int!), radix: 16)!
        return Color(r: UInt8(truncatingBitPattern: hex >> 16),
                     g: UInt8(truncatingBitPattern: hex >> 8),
                     b: UInt8(truncatingBitPattern: hex))
    }

    var lightRange: Int {
        return Item.config[.String(id)]["lightRange"].int!
    }

    func beKicked(by kicker: Creature, direction kickDirection: Direction4) {
        kicker.addMessage("You kick \(name(.definite)).")
        fly(inDirection: kickDirection)
    }

    var hashValue: Int { return id.hashValue }

    private func fly(inDirection flyDirection: Direction4) {
        guard let tileUnder = tileUnder else { return }
        guard let destinationTile = tileUnder.adjacentTile(flyDirection.vector) else { return }
        guard destinationTile.structure == nil else { return }

        tileUnder.removeItem(self)
        destinationTile.addItem(self)
    }
}

func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.id == rhs.id
}
