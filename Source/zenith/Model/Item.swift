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
    let wieldedSprite: Sprite

    override init(id: String) {
        assert(Item.config.hasTable(id))
        sprite = Sprite(fileName: Assets.graphicsPath + "item.bmp",
                        textureRegion: Item.spriteRect(id: id))
        wieldedSprite = Sprite(fileName: Assets.graphicsPath + "item.bmp",
                               textureRegion: Item.spriteRect(id: id, offset: Vector2(0, 1)))
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
            for (id, data) in Item.config.tables() {
                if let spawnRate = data.double("spawnRate") {
                    _spawnRates.append((id: id, levels: data.array("levels")!, spawnRate: spawnRate))
                }
            }
        }
        return _spawnRates
    }

    var isEdible: Bool {
        return Item.config.bool(id, "isEdible") ?? false
    }

    var isUsable: Bool {
        return Item.config.bool(id, "isUsable") ?? false
    }

    func use(world: World, gui: GraphicalUserInterface, user: Creature) {
        for component in components {
            (component as! ItemComponent).use(world: world, gui: gui, user: user)
        }
    }

    var leftover: Item? {
        if let leftoverID = Item.config.string(id, "leftover") {
            return Item(id: leftoverID)
        }
        return nil
    }

    var emitsLight: Bool {
        return Item.config.hasKey(id, "lightColor")
    }

    var lightColor: Color {
        return Color(hue: Item.config.double(id, "lightColor", "hue")!,
              saturation: Item.config.double(id, "lightColor", "saturation")!,
               lightness: Item.config.double(id, "lightColor", "lightness")!)
    }

    var lightRange: Int {
        return Item.config.int(id, "lightRange")!
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
