class Item: Object, Configurable, Hashable, Equatable {

    weak var tileUnder: Tile? {
        didSet {
            if let tile = tileUnder {
                sprite.position = tile.position * tileSize
            }
        }
    }
    static let config = Configuration.load(name: "item")
    var sprite: Sprite

    override init(id: String) {
        assert(Item.config.hasTable(id))
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
            for (id, data) in try! Item.config.tables() {
                if let spawnRate = try? data.double("spawnRate") {
                    _spawnRates.append((id: id, levels: try! data.array("levels"), spawnRate: spawnRate))
                }
            }
        }
        return _spawnRates
    }

    var isEdible: Bool {
        return (try? Item.config.bool(id, "isEdible")) ?? false
    }

    var isUsable: Bool {
        return (try? Item.config.bool(id, "isUsable")) ?? false
    }

    func use(world: World, gui: GraphicalUserInterface, user: Creature) {
        for component in components {
            (component as! ItemComponent).use(world: world, gui: gui, user: user)
        }
    }

    var leftover: Item? {
        if let leftoverID = try? Item.config.string(id, "leftover") {
            return Item(id: leftoverID)
        }
        return nil
    }

    var emitsLight: Bool {
        return Item.config.hasKey(id, "lightColor")
    }

    var lightColor: Color {
        let hex = Int(String(try! Item.config.int(id, "lightColor")), radix: 16)!
        return Color(r: UInt8(truncatingBitPattern: hex >> 16),
                     g: UInt8(truncatingBitPattern: hex >> 8),
                     b: UInt8(truncatingBitPattern: hex))
    }

    var lightRange: Int {
        return try! Item.config.int(id, "lightRange")
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
