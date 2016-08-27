import CSDL2

class Tile: Configurable {

    unowned let area: Area
    let position: Vector2i
    private var bounds: SDL_Rect
    private(set) var items: Array<Item>
    var structure: Structure? {
        didSet {
            structure?.sprite.position = position * tileSize
        }
    }
    var creature: Creature?
    var lightColor: Color
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
        bounds = Rect(position: self.position * tileSize, size: tileSizeVector).asSDLRect()
        creature = nil
        lightColor = area.globalLight
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

    private var lightEmitters: Array<Item> {
        var lightEmitters = items.filter { $0.emitsLight }
        if let wieldedItem = creature?.wieldedItem, wieldedItem.emitsLight {
            lightEmitters.append(wieldedItem)
        }
        return lightEmitters
    }

    func calculateLights() {
        for item in lightEmitters {
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
                        var actualLight = lightColor
                        actualLight.lightness *= lightIntensity
                        tile.lightColor.blend(with: actualLight, blendMode: .screen)
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
                              bitmapRegion: Tile.spriteRect(id: groundId))
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
        var tileRect = bounds
        if let viewport = targetViewport {
            tileRect.x += viewport.x
            tileRect.y += viewport.y
        }
        var clipRect = SDL_Rect()
        SDL_GetClipRect(targetSurface, &clipRect)
        SDL_IntersectRect(&tileRect, &clipRect, &tileRect)
        if tileRect.w <= 0 || tileRect.h <= 0 { return }

        let lightR = Double(lightColor.red)   / 255
        let lightG = Double(lightColor.green) / 255
        let lightB = Double(lightColor.blue)  / 255
        let pixelsPointer = targetSurface.pointee.pixels.assumingMemoryBound(to: UInt16.self)
        let targetWidth = targetSurface.pointee.w
        let xMax = tileRect.x + tileRect.w
        let yMax = tileRect.y + tileRect.h

        var x = tileRect.x
        while x < xMax {
            var y = tileRect.y
            while y < yMax {
                let pixel = pixelsPointer.advanced(by: Int(y * targetWidth + x)).pointee
                var r = Double((pixel & 0b0111_1100_0000_0000) >> 10) / 0b11111
                var g = Double((pixel & 0b0000_0011_1110_0000) >> 5)  / 0b11111
                var b = Double((pixel & 0b0000_0000_0001_1111))       / 0b11111

                // Use the Linear Light blend mode.
                if lightR > 0.5 { r += 2 * lightR - 1 } else { r = r + 2 * lightR - 1 }
                if lightG > 0.5 { g += 2 * lightG - 1 } else { g = g + 2 * lightG - 1 }
                if lightB > 0.5 { b += 2 * lightB - 1 } else { b = b + 2 * lightB - 1 }

                // Clamp components to 0...1.
                if r > 1 { r = 1 } else if r < 0 { r = 0 }
                if g > 1 { g = 1 } else if g < 0 { g = 0 }
                if b > 1 { b = 1 } else if b < 0 { b = 0 }

                let newPixel = UInt16(0b11111 * r) << 10 | UInt16(0b11111 * g) << 5 | UInt16(0b11111 * b)
                pixelsPointer.advanced(by: Int(y * targetWidth + x)).pointee = newPixel
                y += 1
            }
            x += 1
        }
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
