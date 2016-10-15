import Foundation
import Basic
import Graphics

public class Creature: Object, Configurable, Spawnable {

    public private(set) var tileUnder: Tile
    var backpack: [Item]
    private(set) var wieldedItem: Item? {
        didSet {
            tileUnder.invalidateRenderCache()
        }
    }
    public var currentAction: Action?
    public var controller: CreatureController
    public var messageStream: TextOutputStream?

    public private(set) var health, maxHealth, energy, maxEnergy, mana, maxMana: Double
    private var attributes: [Attribute: Int]

    private var sprite: Sprite
    public static let config = Configuration.load(name: "creature")

    public init(type: String, tile: Tile, controller: CreatureController, messageStream: TextOutputStream? = nil) {
        self.tileUnder = tile
        backpack = []
        self.controller = controller
        self.messageStream = messageStream
        sprite = Sprite(fileName: Assets.graphicsPath + "creature.bmp",
                        bitmapRegion: Creature.spriteRect(forObjectType: type))
        health = 0
        maxHealth = 0
        energy = 0
        maxEnergy = 0
        mana = 0
        maxMana = 0
        attributes = Creature.initAttributes(forCreatureType: type)
        super.init(type: type)
        calculateDerivedStats()
        tile.creature = self
    }

    enum Attribute: String, Serializable {
        case rightArmStrength
        case leftArmStrength
        case armStrength
        case rightLegStrength
        case leftLegStrength
        case legStrength
        case strength
        case rightArmDexterity
        case leftArmDexterity
        case dexterity
        case rightLegAgility
        case leftLegAgility
        case agility
        case endurance
        case perception
        case intelligence
        case psyche
        case charisma

        func serialize(to file: FileHandle) {
            switch self {
                case .rightArmStrength:  file.write(0)
                case .leftArmStrength:   file.write(1)
                case .armStrength:       file.write(2)
                case .rightLegStrength:  file.write(3)
                case .leftLegStrength:   file.write(4)
                case .legStrength:       file.write(5)
                case .strength:          file.write(6)
                case .rightArmDexterity: file.write(7)
                case .leftArmDexterity:  file.write(8)
                case .dexterity:         file.write(9)
                case .rightLegAgility:   file.write(10)
                case .leftLegAgility:    file.write(11)
                case .agility:           file.write(12)
                case .endurance:         file.write(13)
                case .perception:        file.write(14)
                case .intelligence:      file.write(15)
                case .psyche:            file.write(16)
                case .charisma:          file.write(17)
            }
        }

        mutating func deserialize(from file: FileHandle) {
            var number = 0
            file.read(&number)
            switch number {
                case 0:  self = .rightArmStrength
                case 1:  self = .leftArmStrength
                case 2:  self = .armStrength
                case 3:  self = .rightLegStrength
                case 4:  self = .leftLegStrength
                case 5:  self = .legStrength
                case 6:  self = .strength
                case 7:  self = .rightArmDexterity
                case 8:  self = .leftArmDexterity
                case 9:  self = .dexterity
                case 10: self = .rightLegAgility
                case 11: self = .leftLegAgility
                case 12: self = .agility
                case 13: self = .endurance
                case 14: self = .perception
                case 15: self = .intelligence
                case 16: self = .psyche
                case 17: self = .charisma
                default: assert(false)
            }
        }
    }

    private func attributeValue(_ attribute: Attribute) -> Int {
        if let value = attributes[attribute] {
            return value
        }
        let subAttributes = Creature.subAttributes(of: attribute)
        let subAttributeValues = subAttributes.map { attributeValue($0) }
        return subAttributeValues.reduce(0, +) / subAttributes.count
    }

    public var rightArmStrength:  Int { return attributeValue(.rightArmStrength) }
    public var leftArmStrength:   Int { return attributeValue(.leftArmStrength) }
    public var armStrength:       Int { return attributeValue(.armStrength) }
    public var rightLegStrength:  Int { return attributeValue(.rightLegStrength) }
    public var leftLegStrength:   Int { return attributeValue(.leftLegStrength) }
    public var legStrength:       Int { return attributeValue(.legStrength) }
    public var strength:          Int { return attributeValue(.strength) }
    public var rightArmDexterity: Int { return attributeValue(.rightArmDexterity) }
    public var leftArmDexterity:  Int { return attributeValue(.leftArmDexterity) }
    public var dexterity:         Int { return attributeValue(.dexterity) }
    public var rightLegAgility:   Int { return attributeValue(.rightLegAgility) }
    public var leftLegAgility:    Int { return attributeValue(.leftLegAgility) }
    public var agility:           Int { return attributeValue(.agility) }
    public var endurance:         Int { return attributeValue(.endurance) }
    public var perception:        Int { return attributeValue(.perception) }
    public var intelligence:      Int { return attributeValue(.intelligence) }
    public var psyche:            Int { return attributeValue(.psyche) }
    public var charisma:          Int { return attributeValue(.charisma) }

    public func tryToMove(_ direction: Direction4) {
        guard let destinationTile = tileUnder.adjacentTile(direction.vector) else {
            return
        }
        if destinationTile.creature != nil { return }
        let canMove = destinationTile.structure?.preventsMovement != true
        destinationTile.reactToMovementAttempt(of: self)
        if !canMove { return }
        move(to: destinationTile)
    }

    private func move(to destinationTile: Tile) {
        tileUnder.invalidateRenderCache()
        destinationTile.invalidateRenderCache()

        tileUnder.creature = nil
        tileUnder = destinationTile
        tileUnder.creature = self
        addMoveMessages()
    }

    public func useStairs() -> Bool {
        switch tileUnder.structure?.type {
            case .some("stairsDown"):
                goDownStairs()
                return true
            case .some("stairsUp"):
                goUpStairs()
                return true
            default:
                return false
        }
    }

    private func goDownStairs() {
        let destinationTile = tileUnder.tileBelow!
        destinationTile.structure = Structure(type: "stairsUp")
        addMessage("You go down the stairs.")
        move(to: destinationTile)
    }

    private func goUpStairs() {
        let destinationTile = tileUnder.tileAbove!
        destinationTile.structure = Structure(type: "stairsDown")
        addMessage("You go up the stairs.")
        move(to: destinationTile)
    }

    func addMoveMessages() {
        switch tileUnder.items.count {
            case 0:
                break
            case 1:
                addMessage("\(tileUnder.items[0].name(.indefinite, .capitalize)) is lying here.")
            default:
                addMessage("Some items are lying here.")
        }
    }

    public func pickUpItems() {
        guard let item = tileUnder.removeTopItem() else {
            addMessage("There's nothing to pick up here.")
            return
        }

        backpack.append(item)
        addMessage("You pick up \(item.name(.definite)).")
    }

    public var canOpenAndClose: Bool {
        return Creature.config.bool(type, "canOpenAndClose") ?? true
    }

    public func tryToClose(direction: Direction4) {
        tileUnder.adjacentTile(direction.vector)?.structure?.tryToClose(closer: self)
    }

    var inventory: [Item] {
        return backpack
    }

    public var equipment: [(item: Item, amount: Int)] {
        var result = [Item: Int]()
        for item in backpack {
            result[item] = (result[item] ?? 0) + 1
        }
        return result.map { ($0.key, $0.value) }
    }

    public func wieldItem(_ item: Item?) {
        wieldedItem = item
        if let item = item {
            addMessage("You wield \(item.name(.definite)).")
        }
    }

    public func dropItem(_ item: Item) {
        assert(inventory.contains { $0 === item })
        removeItem(item)
        tileUnder.addItem(item)
        addMessage("You drop \(item.name(.definite)).")
    }

    func removeItem(_ item: Item) {
        if wieldedItem === item { wieldedItem = nil }
        backpack.remove(at: backpack.index(where: { $0 === item })!)
    }

    override func update() throws {
        if case .some(.resting(let ticksLeft)) = currentAction {
            if ticksLeft > 0 {
                currentAction = .resting(ticksLeft: ticksLeft - 1)
                return
            } else {
                currentAction = nil
            }
        }
        try controller.control(self)
    }

    override func render() {
        sprite.render()
        wieldedItem?.wieldedSprite.render(at: sprite.position)
    }

    public var area: Area { return tileUnder.area }

    public func addMessage(_ messageText: @autoclosure () -> String) {
        messageStream?.write(messageText())
    }

    public func eat(_ food: Item) {
        removeItem(food)
        addMessage("You eat \(food.name(.definite)).")
    }

    public var attackStyles: [AttackStyle] {
        return Creature.config.array(type, "attackStyles")!.map { AttackStyle(rawValue: $0)! }
    }

    public func hit(direction hitDirection: Direction4, style: AttackStyle) {
        let damage = calculateDamage(style: style)
        tileUnder.adjacentTile(hitDirection.vector)?.beHit(by: self, direction: hitDirection,
                                                           style: style, damage: damage)
    }

    func beHit(by attacker: Creature, direction hitDirection: Direction4,
               style: AttackStyle, damage: Int) {
        let weaponDescription: String
        if style == .hit, let weapon = attacker.wieldedItem?.name(.definite) {
            weaponDescription = " with \(weapon)"
        } else {
            weaponDescription = ""
        }
        attacker.addMessage("You \(style.verb) \(name(.definite))\(weaponDescription).")
        addMessage("\(attacker.name(.definite, .capitalize)) \(style.verbThirdPerson) you\(weaponDescription).")

        if isResting {
            addMessage("The attack wakes you up.")
            currentAction = nil
        }
        takeDamage(damage)
    }

    private func calculateDamage(style: AttackStyle) -> Int {
        switch style {
            case .hit:  return armStrength
            case .kick: return legStrength
            case .bite: return Creature.config.int(type, "biteStrength")! // TODO: Use tooth material strength?
        }
    }

    func takeDamage(_ damage: Int) {
        assert(damage > 0)
        health -= Double(damage) / Double(endurance)

        if health <= 0 {
            die()
        }
    }

    func die() {
        tileUnder.creature = nil
        tileUnder.addItem(Item(type: type + "Corpse"))

        for area in [.some(area)] + area.adjacent8Areas {
            if let area = area {
                for observer in area.creatures {
                    if observer.canSee(self) {
                        observer.addMessage("\(name(.definite, .capitalize)) dies.")
                    }
                }
            }
        }
        addMessage("You die.")

        if isPlayer {
            addMessage("Press ESC to go to main menu.")
            try? FileManager.default.removeItem(atPath: Assets.savedGamePath)
        }
    }

    public var isDead: Bool {
        return health <= 0
    }

    var isResting: Bool {
        if case .some(.resting) = currentAction {
            return true
        }
        return false
    }

    func canSee(_ tile: Tile) -> Bool {
        let sightVector = tile.globalPosition - tileUnder.globalPosition

        for vector in raycastIntegerBresenham(direction: sightVector) {
            if vector == sightVector {
                return true
            }
            if tileUnder.adjacentTile(vector)?.structure?.blocksSight == true {
                return false
            }
        }
        return true
    }

    func canSee(_ other: Creature) -> Bool {
        return other.tileUnder.structure?.blocksSight != true && canSee(other.tileUnder)
    }

    static var _spawnInfoMap = SpawnInfoMap()

    var isPlayer: Bool {
        return messageStream != nil
    }

    private static func initAttributes(forCreatureType type: String) -> [Attribute: Int] {
        var attributes = [Attribute: Int]()
        let baseType = config.string(type, "basetype")!
        let baseTypeAttributes: [String] = config.array(baseType, "attributes")!

        for attribute in baseTypeAttributes {
            let attributeEnum = Attribute(rawValue: attribute)!

            if let attributeValue = config.int(type, attribute) {
                attributes[attributeEnum] = attributeValue
            } else {
                guard var superAttribute = Creature.superAttribute(of: attributeEnum) else {
                    fatalError() // TODO: Look up baseType attribute.
                }

                if config.int(type, superAttribute.rawValue) == nil {
                    superAttribute = Creature.superAttribute(of: superAttribute)!
                    assert(config.hasKey(type, superAttribute.rawValue))
                }

                attributes[attributeEnum] = config.int(type, superAttribute.rawValue)!
            }
        }

        return attributes
    }

    private func calculateDerivedStats() {
        maxHealth = 2 * Double(endurance) + Double(strength) / 2
        maxEnergy = 2 * Double(agility) + Double(dexterity) / 2
        maxMana = 2 * Double(psyche) + Double(intelligence) / 2
        health = maxHealth
        energy = maxEnergy
        mana = maxMana
    }

    private static func superAttribute(of attribute: Attribute) -> Attribute? {
        switch attribute {
            case .rightArmStrength, .leftArmStrength: return .armStrength
            case .rightLegStrength, .leftLegStrength: return .legStrength
            case .armStrength, .legStrength: return .strength
            case .rightArmDexterity, .leftArmDexterity: return .dexterity
            case .rightLegAgility, .leftLegAgility: return .agility
            default: return nil
        }
    }

    private static func subAttributes(of attribute: Attribute) -> [Attribute] {
        switch attribute {
            case .strength: return [.armStrength, .legStrength]
            case .armStrength: return [.rightArmStrength, .leftArmStrength]
            case .legStrength: return [.rightLegStrength, .leftLegStrength]
            case .dexterity: return [.rightArmDexterity, .leftArmDexterity]
            case .agility: return [.rightLegAgility, .leftLegAgility]
            default: return []
        }
    }

    public override func serialize(to file: FileHandle) {
        file.write(backpack.count)
        for item in backpack {
            file.write(item.type)
        }

        file.write(wieldedItem?.type)

        file.write(attributes)
        file.write(health)
        file.write(energy)
        file.write(mana)
    }

    public override func deserialize(from file: FileHandle) {
        var backpackSize = 0
        file.read(&backpackSize)
        backpack.removeAll(keepingCapacity: true)
        backpack.reserveCapacity(backpackSize)
        for _ in 0..<backpackSize {
            var itemType = ""
            file.read(&itemType)
            backpack.append(Item(type: itemType))
        }

        var wieldedItemType: String? = nil
        file.read(&wieldedItemType, elementInitializer: { "" })
        wieldedItem = backpack.first(where: { $0.type == wieldedItemType })

        file.read(&attributes, keyInitializer: { .charisma }, valueInitializer: { 0 })
        calculateDerivedStats()
        file.read(&health)
        file.read(&energy)
        file.read(&mana)
        assert(health <= maxHealth && energy <= maxEnergy && mana <= maxMana)
    }
}

public enum Action: Serializable {

    case resting(ticksLeft: Int)

    public func serialize(to file: FileHandle) {
        switch self {
            case .resting(let ticksLeft):
                file.write(0)
                file.write(ticksLeft)
        }
    }

    public mutating func deserialize(from file: FileHandle) {
        var whichCase = 0
        file.read(&whichCase)
        switch whichCase {
            case 0:
                var ticksLeft = 0
                file.read(&ticksLeft)
                self = .resting(ticksLeft: ticksLeft)
            default:
                assert(false)
        }
    }
}

public enum AttackStyle: String {

    case hit
    case kick
    case bite

    var verb: String {
        return rawValue
    }

    var verbThirdPerson: String {
        switch self {
            case .hit: return "hits"
            case .kick: return "kicks"
            case .bite: return "bites"
        }
    }
}