import Foundation
import Basic
import Graphics

public class Item: Object, Configurable, Spawnable, Hashable, Equatable {

    weak var tileUnder: Tile?
    public static let config = Configuration.load(name: "item")
    public private(set) var sprite: Sprite
    let wieldedSprite: Sprite
    var emitsLight: Bool { return lightRange != 0 }
    let lightColor: Color
    let lightRange: Int

    override init(type: String) {
        if type.hasSuffix("Corpse") {
            let creatureType = type.replacingOccurrences(of: "Corpse", with: "")
            // Assumes corpse sprites are located in the third grid column.
            let spriteRect = Creature.spriteRect(forObjectType: creatureType).moved(by: Vector2(2 * tileSize, 0))
            sprite = Sprite(fileName: Assets.graphicsPath + "creature.bmp", bitmapRegion: spriteRect)
            wieldedSprite = sprite
            lightColor = Color.black
            lightRange = 0
            super.init(type: creatureType + "Corpse")
            return
        }
        assert(Item.config.hasTable(type))
        sprite = Sprite(fileName: Assets.graphicsPath + "item.bmp",
                        bitmapRegion: Item.spriteRect(forObjectType: type))
        wieldedSprite = Sprite(fileName: Assets.graphicsPath + "item.bmp",
                               bitmapRegion: Item.spriteRect(forObjectType: type, offset: Vector2(0, 1)))
        if Item.config.hasKey(type, "lightColor") {
            lightColor = Color(hue: Item.config.double(type, "lightColor", "hue")!,
                               saturation: Item.config.double(type, "lightColor", "saturation")!,
                               lightness: Item.config.double(type, "lightColor", "lightness")!)
            lightRange = Item.config.int(type, "lightRange")!
        } else {
            lightColor = Color.black
            lightRange = 0
        }
        super.init(type: type)
        addComponents(config: Item.config)
    }

    func render() {
        sprite.render()
    }

    static var _spawnInfoMap = SpawnInfoMap()

    public var isEdible: Bool {
        return Item.config.bool(type, "isEdible") ?? type.hasSuffix("Corpse")
    }

    public var isUsable: Bool {
        return Item.config.bool(type, "isUsable") ?? false
    }

    public func use(world: World, user: Creature) {
        for component in components {
            (component as! ItemComponent).use(world: world, user: user)
        }
    }

    public var leftover: Item? {
        if let leftoverType = Item.config.string(type, "leftover") {
            return Item(type: leftoverType)
        }
        return nil
    }

    func beHit(by hitter: Creature, direction hitDirection: Direction4, style: AttackStyle) {
        hitter.addMessage("You \(style.verb) \(name(.definite)).")
        fly(inDirection: hitDirection)
    }

    public var hashValue: Int { return type.hashValue }

    private func fly(inDirection flyDirection: Direction4) {
        guard let tileUnder = tileUnder else { return }
        guard let destinationTile = tileUnder.adjacentTile(flyDirection.vector) else { return }
        guard destinationTile.structure == nil else { return }

        tileUnder.removeItem(self)
        destinationTile.addItem(self)
    }
}

public func ==(lhs: Item, rhs: Item) -> Bool {
    return lhs.type == rhs.type
}
