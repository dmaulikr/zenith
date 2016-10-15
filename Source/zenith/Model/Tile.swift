import CSDL2
import Foundation

class Tile: Configurable, Serializable {

    unowned let area: Area
    let position: Vector2i
    var globalPosition: Vector2i {
        return Vector2(area.position) * Area.size + position
    }
    private(set) var items: [Item]
    var structure: Structure? {
        didSet {
            structure?.tile = self
            invalidateRenderCache()
        }
    }
    var creature: Creature? {
        willSet {
            if let newCreature = newValue {
                area.registerCreature(newCreature)
            } else if let oldCreature = creature {
                area.unregisterCreature(oldCreature)
            }
        }
    }
    var lightColor: Color
    var groundType: String {
        didSet {
            groundSprite = Sprite(fileName: Assets.graphicsPath + "terrain.bmp",
                                  bitmapRegion: Tile.spriteRect(forObjectType: groundType))
        }
    }
    private var groundSprite: Sprite!
    private var renderCache: Sprite
    private var renderCacheIsInvalidated: Bool
    private var renderCacheLightColor: Color = Color.black
    static let config = Configuration.load(name: "terrain")
    private static let fogOfWarSprite = Sprite(fileName: Assets.graphicsPath + "fogOfWar.bmp")
    private static var bounds = Rect(position: Vector2(0, 0), size: tileSizeVector).asSDLRect()

    init(area: Area, position: Vector2i) {
        self.area = area
        self.position = position
        creature = nil
        lightColor = area.globalLight
        items = []
        renderCache = Sprite(image: Bitmap(size: tileSizeVector))
        renderCacheIsInvalidated = true
        groundType = ""
    }

    deinit {
        renderCache.bitmap.deallocate()
    }

    func generate() {
        groundType = area.position.z < 0 ? "dirtFloor" : "grass"

        if area.position.z < 0 {
            structure = Structure(type: "ground")
            structure!.tile = self
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

    var adjacent4Tiles: [Tile?] {
        return Direction4.allDirections.map { adjacentTile($0.vector) }
    }

    var adjacent8Tiles: [Tile?] {
        return Direction8.allDirections.map { adjacentTile($0.vector) }
    }

    var tileBelow: Tile? { return area.areaBelow?.tile(at: position) }

    var tileAbove: Tile? { return area.areaAbove?.tile(at: position) }

    func update() {
        calculateLightEmission()
    }

    private var lightEmitters: [Item] {
        var lightEmitters = items.filter { $0.emitsLight }
        if let wieldedItem = creature?.wieldedItem, wieldedItem.emitsLight {
            lightEmitters.append(wieldedItem)
        }
        return lightEmitters
    }

    func calculateLightEmission() {
        if structure?.blocksSight == true { return }

        for item in lightEmitters {
            let lightColor = item.lightColor
            let distance = item.lightRange
            let maxLengthSquared = Vector2(Double(distance), Double(distance)).lengthSquared

            func raycast(lightVector: Vector2i) {
                var wasBlocked = false

                for vector in raycastIntegerBresenham(direction: lightVector) {
                    if let tile = self.adjacentTile(vector) {
                        tile.invalidateRenderCache()
                        if wasBlocked { continue }
                        wasBlocked = tile.structure?.blocksSight == true
                        let lightIntensity = 1 - Double(vector.lengthSquared) / maxLengthSquared
                        var actualLight = lightColor
                        actualLight.lightness *= lightIntensity
                        tile.lightColor.blend(with: actualLight, blendMode: .lighten)
                    }
                }
            }

            for dx in -distance...distance {
                raycast(lightVector: Vector2(dx, -distance))
                raycast(lightVector: Vector2(dx,  distance))
            }
            for dy in -distance...distance {
                raycast(lightVector: Vector2(-distance, dy))
                raycast(lightVector: Vector2( distance, dy))
            }
        }
    }

    func invalidateRenderCachesOfAdjacentTiles(illuminatedBy lightEmitter: Item) {
        if structure?.blocksSight == true { return }
        let distance = lightEmitter.lightRange

        for dx in -distance...distance {
            for dy in -distance...distance {
                adjacentTile(Vector2(dx, dy))?.invalidateRenderCache()
            }
        }
    }

    func render() {
        if renderCacheIsInvalidated || renderCacheLightColor != lightColor {
            let targetSurfaceBackup = targetSurface
            let targetViewportBackup = targetViewport
            targetSurface = renderCache.bitmap.surface
            targetViewport = Tile.bounds
            renderActual()
            targetSurface = targetSurfaceBackup
            targetViewport = targetViewportBackup
            renderCacheLightColor = lightColor
            renderCacheIsInvalidated = false
        }
        renderCache.render()
    }

    private func renderActual() {
        groundSprite.render()
        for item in items { item.render() }
        structure?.render()
        creature?.render()
        renderLight()
    }

    func invalidateRenderCache() {
        renderCacheIsInvalidated = true
    }

    private func renderLight() {
        var tileRect = Tile.bounds
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
        let pixelsPointer = targetSurface.pointee.pixels.assumingMemoryBound(to: UInt32.self)
        let targetWidth = targetSurface.pointee.w
        let xMax = tileRect.x + tileRect.w
        let yMax = tileRect.y + tileRect.h

        var x = tileRect.x
        while x < xMax {
            var y = tileRect.y
            while y < yMax {
                let pixel = pixelsPointer.advanced(by: Int(y * targetWidth + x)).pointee
                var r = Double((pixel & 0xFF0000) >> 16) / 255
                var g = Double((pixel & 0x00FF00) >> 8)  / 255
                var b = Double((pixel & 0x0000FF))       / 255

                // Use the Linear Light blend mode.
                if lightR > 0.5 { r += 2 * lightR - 1 } else { r = r + 2 * lightR - 1 }
                if lightG > 0.5 { g += 2 * lightG - 1 } else { g = g + 2 * lightG - 1 }
                if lightB > 0.5 { b += 2 * lightB - 1 } else { b = b + 2 * lightB - 1 }

                // Clamp components to 0...1.
                if r > 1 { r = 1 } else if r < 0 { r = 0 }
                if g > 1 { g = 1 } else if g < 0 { g = 0 }
                if b > 1 { b = 1 } else if b < 0 { b = 0 }

                let newPixel = UInt32(255 * r) << 16 | UInt32(255 * g) << 8 | UInt32(255 * b)
                pixelsPointer.advanced(by: Int(y * targetWidth + x)).pointee = newPixel
                y += 1
            }
            x += 1
        }
    }

    func addItem(_ item: Item) {
        invalidateRenderCache()
        items.append(item)
        item.tileUnder = self
    }

    func removeTopItem() -> Item? {
        guard let topItem = items.popLast() else {
            return nil
        }
        invalidateRenderCache()
        if topItem.emitsLight {
            invalidateRenderCachesOfAdjacentTiles(illuminatedBy: topItem)
        }
        topItem.tileUnder = nil
        return topItem
    }

    func removeItem(_ itemToBeRemoved: Item) {
        guard let index = items.index(where: { $0 === itemToBeRemoved }) else { return }
        invalidateRenderCache()
        if itemToBeRemoved.emitsLight {
            invalidateRenderCachesOfAdjacentTiles(illuminatedBy: itemToBeRemoved)
        }
        items[index].tileUnder = nil
        items.remove(at: index)
    }

    func reactToMovementAttempt(of mover: Creature) {
        structure?.reactToMovementAttempt(of: mover)
    }

    func beHit(by hitter: Creature, direction hitDirection: Direction4,
               style: AttackStyle, damage: Int) {
        if let creatureOnTile = creature {
            creatureOnTile.beHit(by: hitter, direction: hitDirection, style: style, damage: damage)
        } else if let structureOnTile = structure {
            structureOnTile.beHit(by: hitter, direction: hitDirection, style: style)
        } else if let topmostItemOnTile = items.last {
            topmostItemOnTile.beHit(by: hitter, direction: hitDirection, style: style)
        } else {
            hitter.addMessage("You \(style.verb) the air.")
        }
    }

    func spawnStructures() {
        for (type, spawnInfo) in Structure.spawnInfoMap {
            let spawnRateScale = 1.0 - abs(spawnInfo.populationDensityFactor - area.populationDensity)
            if spawnInfo.levels.contains(area.position.z.sign)
                && Double.random(0...1) < spawnInfo.spawnRate * spawnRateScale {
                structure = Structure(type: type)
            }
        }
    }

    func spawnItems() {
        for (type, spawnInfo) in Item.spawnInfoMap {
            let spawnRateScale = 1.0 - abs(spawnInfo.populationDensityFactor - area.populationDensity)
            if spawnInfo.levels.contains(area.position.z.sign)
                && Double.random(0...1) < spawnInfo.spawnRate * spawnRateScale {
                addItem(Item(type: type))
            }
        }
    }

    func spawnCreatures() {
        for (type, spawnInfo) in Creature.spawnInfoMap {
            let spawnRateScale = 1.0 - abs(spawnInfo.populationDensityFactor - area.populationDensity)
            if Double.random(0...1) < spawnInfo.spawnRate * spawnRateScale {
                _ = Creature(type: type, tile: self, controller: AIController())
            }
        }
    }

    func serialize(to file: FileHandle) {
        file.write(items.count)
        for item in items {
            file.write(item.type)
        }

        file.write(structure != nil)
        if let structure = structure {
            file.write(structure.type)
            file.write(structure)
        }

        file.write(creature != nil)
        if let creature = creature {
            file.write(creature.type)
            file.write(creature)
        }

        file.write(groundType)
    }

    func deserialize(from file: FileHandle) {
        var itemCount = 0
        file.read(&itemCount)
        items = []
        for _ in 0..<itemCount {
            var itemType = ""
            file.read(&itemType)
            items.append(Item(type: itemType))
        }

        var hasStructure = false
        file.read(&hasStructure)
        if hasStructure {
            var structureType = ""
            file.read(&structureType)
            structure = Structure(type: structureType)
            file.read(&structure!)
        } else {
            structure = nil
        }

        var hasCreature = false
        file.read(&hasCreature)
        if hasCreature {
            var creatureType = ""
            file.read(&creatureType)
            creature = Creature(type: creatureType, tile: self, controller: AIController())
            file.read(&creature!)
        } else {
            creature = nil
        }

        file.read(&groundType)
    }
}
