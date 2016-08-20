import CSDL2

class Tile: Configurable {

    unowned let area: Area
    let position: Vector2i
    private(set) var items: Array<Item>
    var structure: Structure? {
        didSet {
            structure?.sprite.position = position * tileSize
        }
    }
    var creature: Creature?
    var lights: Array<Color>
    private var fogOfWar: Bool
    var groundId: String {
        didSet { loadGroundSprite() }
    }
    private var groundSprite: Sprite!
    static let config = Configuration.load(name: "terrain")
    private static let fogOfWarSprite = Sprite(fileName: Assets.graphicsPath + "fogOfWar.bmp")

    init(area: Area, position: Vector2i) {
        self.area = area
        self.position = position
        creature = nil
        lights = Array()
        fogOfWar = false
        items = Array()
        groundId = area.position.z < 0 ? "dirtFloor" : "grass"
        loadGroundSprite()

        if area.position.z < 0 {
            structure = Structure(id: "ground")
            structure!.sprite.position = position * tileSize
        } else {
            spawnStructures()
        }

        if structure == nil {
            spawnItems()
            spawnCreatures()
        }
    }

    func adjacentTile(_ direction: Vector2i) -> Tile? {
        var position = self.position + direction
        var relativeAreaPosition = Vector2(0, 0)

        while position.x < 0 {
            position.x += Area.size
            relativeAreaPosition.x -= 1
        }
        while position.x >= Area.size {
            position.x -= Area.size
            relativeAreaPosition.x += 1
        }
        while position.y < 0 {
            position.y += Area.size
            relativeAreaPosition.y -= 1
        }
        while position.y >= Area.size {
            position.y -= Area.size
            relativeAreaPosition.y += 1
        }

        if relativeAreaPosition == Vector2(0, 0) {
            return area.tile(at: position)
        } else {
            return area.adjacentArea(direction: relativeAreaPosition)?.tile(at: position)
        }
    }

    var adjacent4Tiles: Array<Tile?> {
        return [
            adjacentTile(Direction4.north.vector),
            adjacentTile(Direction4.east.vector),
            adjacentTile(Direction4.south.vector),
            adjacentTile(Direction4.west.vector)
        ]
    }

    var adjacent8Tiles: Array<Tile?> {
        return [
            adjacentTile(Direction8.north.vector),
            adjacentTile(Direction8.northEast.vector),
            adjacentTile(Direction8.east.vector),
            adjacentTile(Direction8.southEast.vector),
            adjacentTile(Direction8.south.vector),
            adjacentTile(Direction8.southWest.vector),
            adjacentTile(Direction8.west.vector),
            adjacentTile(Direction8.northWest.vector)
        ]
    }

    var tileBelow: Tile? { return area.areaBelow?.tile(at: position) }

    var tileAbove: Tile? { return area.areaAbove?.tile(at: position) }

    func update() {
        calculateLights()
    }

    func calculateLights() {
        for item in items {
            if !item.emitsLight { continue }
            let lightColor = item.lightColor
            let distance = item.lightRange
            let maxLengthSquared = Vector2(Double(distance), Double(distance)).lengthSquared

            for dx in -distance...distance {
                for dy in -distance...distance {
                    let lightVector = Vector2(dx, dy)

                    let stopped = raycastIntegerBresenham(from: position, to: position + lightVector) {
                        relativePosition in
                        guard let tile = self.adjacentTile(relativePosition - self.position) else {
                            return false
                        }
                        return tile.structure?.blocksSight == true
                    }

                    if stopped { continue }

                    if let tile = adjacentTile(lightVector) {
                        let lightIntensity = 1 - Double(lightVector.lengthSquared) / maxLengthSquared
                        tile.lights.append(lightColor.multipliedComponentwise(by: lightIntensity))
                    }
                }
            }
        }
    }

    func updateFogOfWar(lineOfSight: Vector2i) {
        fogOfWar = raycastIntegerBresenham(from: position - lineOfSight, to: position) {
            relativePosition in
            if relativePosition == self.position { return false }
            if let tile = self.adjacentTile(relativePosition - self.position) {
                if tile.structure?.blocksSight == true {
                    return true
                }
            }
            return false
        }
    }

    private func loadGroundSprite() {
        groundSprite = Sprite(fileName: Assets.graphicsPath + "terrain.bmp",
                              textureRegion: Tile.spriteRect(id: groundId))
        groundSprite.position = position * tileSize
    }

    func render() {
        groundSprite.render()
        for item in items { item.render() }
        structure?.render()
        if !fogOfWar { creature?.render() }
        renderLight()
        if fogOfWar { Tile.fogOfWarSprite.render(at: position * tileSize) }
    }

    private func renderLight() {
        var lightColor = Color.black
        for light in lights { lightColor.blend(with: light, blendMode: .additive) }
        let rect = Rect(position: position * tileSize, size: tileSizeVector)
        drawRectangle(rect, color: lightColor, filled: true, blendMode: SDL_BLENDMODE_ADD)
    }

    func addItem(_ item: Item) {
        items.append(item)
        item.tileUnder = self
    }

    func removeTopItem() -> Item? {
        items.last?.tileUnder = nil
        return items.popLast()
    }

    func removeItem(_ itemToBeRemoved: Item) {
        guard let index = items.index(where: { $0 === itemToBeRemoved }) else { return }
        items[index].tileUnder = nil
        items.remove(at: index)
    }

    func reactToMovementAttempt(of mover: Creature) {
        structure?.reactToMovementAttempt(of: mover)
    }

    func beKicked(by kicker: Creature, direction kickDirection: Direction4) {
        if let creatureOnTile = creature {
            creatureOnTile.beKicked(by: kicker, direction: kickDirection)
        } else if let structureOnTile = structure {
            structureOnTile.beKicked(by: kicker, direction: kickDirection)
        } else if let topmostItemOnTile = items.last {
            topmostItemOnTile.beKicked(by: kicker, direction: kickDirection)
        } else {
            kicker.addMessage("You kick the air.")
        }
    }

    func spawnStructures() {
        for (id, levels, spawnRate) in Structure.spawnRates {
            if levels.contains(area.position.z.sign) && Double.random(0...1) < spawnRate {
                structure = Structure(id: id)
            }
        }
    }

    func spawnItems() {
        for (id, levels, spawnRate) in Item.spawnRates {
            if levels.contains(area.position.z.sign) && Double.random(0...1) < spawnRate {
                addItem(Item(id: id))
            }
        }
    }

    func spawnCreatures() {
        for (id, _, spawnRate) in Creature.spawnRates {
            if Double.random(0...1) < spawnRate {
                _ = Creature(id: id, tile: self)
            }
        }
    }
}
