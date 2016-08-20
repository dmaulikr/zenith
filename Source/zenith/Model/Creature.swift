import Foundation

class Creature: Object, Configurable {

    private(set) var tileUnder: Tile {
        didSet {
            sprite.position = tileUnder.position * tileSize
        }
    }
    var backpack: Array<Item>
    private let messageStream: MessageStream?

    private(set) var health, maxHealth, energy, maxEnergy, mana, maxMana: Int!
    private var attributes: Dictionary<Attribute, Int>

    private let sprite: Sprite
    static let config = Configuration.load(name: "creature")
    static var allCreatures = Array<Creature>()

    init(id: String, tile: Tile, messageStream: MessageStream? = nil) {
        self.tileUnder = tile
        backpack = Array()
        self.messageStream = messageStream
        sprite = Sprite(fileName: Assets.graphicsPath + "creature.bmp",
                        textureRegion: Creature.spriteRect(id: id))
        sprite.position = tileUnder.position * tileSize
        attributes = Creature.initAttributes(id: id)
        super.init(id: id)
        calculateDerivedStats()
        tile.creature = self
        Creature.allCreatures.append(self)
    }

    deinit {
        if let index = Creature.allCreatures.index(where: { $0 === self }) {
            Creature.allCreatures.remove(at: index)
        }
    }

    enum Attribute: String {
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
    }

    private func attributeValue(_ attribute: Attribute) -> Int {
        if let value = attributes[attribute] {
            return value
        }
        let subAttributes = Creature.subAttributes(of: attribute)
        let subAttributeValues = subAttributes.map { attributeValue($0) }
        return subAttributeValues.reduce(0, +) / subAttributes.count
    }

    var rightArmStrength:  Int { return attributeValue(.rightArmStrength) }
    var leftArmStrength:   Int { return attributeValue(.leftArmStrength) }
    var armStrength:       Int { return attributeValue(.armStrength) }
    var rightLegStrength:  Int { return attributeValue(.rightLegStrength) }
    var leftLegStrength:   Int { return attributeValue(.leftLegStrength) }
    var legStrength:       Int { return attributeValue(.legStrength) }
    var strength:          Int { return attributeValue(.strength) }
    var rightArmDexterity: Int { return attributeValue(.rightArmDexterity) }
    var leftArmDexterity:  Int { return attributeValue(.leftArmDexterity) }
    var dexterity:         Int { return attributeValue(.dexterity) }
    var rightLegAgility:   Int { return attributeValue(.rightLegAgility) }
    var leftLegAgility:    Int { return attributeValue(.leftLegAgility) }
    var agility:           Int { return attributeValue(.agility) }
    var endurance:         Int { return attributeValue(.endurance) }
    var perception:        Int { return attributeValue(.perception) }
    var intelligence:      Int { return attributeValue(.intelligence) }
    var psyche:            Int { return attributeValue(.psyche) }
    var charisma:          Int { return attributeValue(.charisma) }

    func tryToMove(_ direction: Direction4) {
        guard let destinationTile = tileUnder.adjacentTile(direction.vector) else {
            return
        }
        if destinationTile.creature != nil { return }
        let canMove = destinationTile.structure?.preventsMovement != true
        destinationTile.reactToMovementAttempt(of: self)
        if !canMove { return }
        tileUnder.creature = nil
        tileUnder = destinationTile
        tileUnder.creature = self
        addMoveMessages()
    }

    func useStairs() -> Bool {
        switch tileUnder.structure?.id {
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
        destinationTile.structure = Structure(id: "stairsUp")
        tileUnder.creature = nil
        tileUnder = destinationTile
        tileUnder.creature = self
        addMessage("You go down the stairs.")
    }

    private func goUpStairs() {
        let destinationTile = tileUnder.tileAbove!
        destinationTile.structure = Structure(id: "stairsDown")
        tileUnder.creature = nil
        tileUnder = destinationTile
        tileUnder.creature = self
        addMessage("You go up the stairs.")
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

    func pickUpItems() {
        guard let item = tileUnder.removeTopItem() else {
            addMessage("There's nothing to pick up here.")
            return
        }

        backpack.append(item)
        addMessage("You pick up \(item.name(.definite)).")
    }

    func tryToClose(direction: Direction4) {
        tileUnder.adjacentTile(direction.vector)?.structure?.tryToClose(closer: self)
    }

    var inventory: Array<Item> {
        return backpack
    }

    var equipment: Array<(item: Item, amount: Int)> {
        var result = Dictionary<Item, Int>()
        for item in backpack {
            result[item] = (result[item] ?? 0) + 1
        }
        return result.map { ($0.key, $0.value) }
    }

    func dropItem(_ item: Item) {
        assert(inventory.contains { $0 === item })
        removeItem(item)
        tileUnder.addItem(item)
    }

    func removeItem(_ item: Item) {
        backpack.remove(at: backpack.index(where: { $0 === item })!)
    }

    override func update() {
        if !isPlayer {
            tryToMove(Direction4.random)
        }
    }

    override func render() {
        sprite.render()
    }

    var area: Area { return tileUnder.area }

    func addMessage(_ messageText: @autoclosure () -> String) {
        messageStream?.write(messageText())
    }

    func eat(_ food: Item) {
        removeItem(food)
        addMessage("You eat \(food.name(.definite)).")
    }

    func kick(direction kickDirection: Direction4) {
        tileUnder.adjacentTile(kickDirection.vector)?.beKicked(by: self, direction: kickDirection)
    }

    func beKicked(by kicker: Creature, direction kickDirection: Direction4) {
        kicker.addMessage("You kick \(name(.definite)).")
        addMessage("\(kicker.name(.definite)) kicks you.")
        // TODO: Deal damage.
    }

    // TODO: Remove this copy-paste code.
    private static var _spawnRates = Array<(id: String, levels: Array<Int>, spawnRate: Double)>()
    static var spawnRates: Array<(id: String, levels: Array<Int>, spawnRate: Double)> {
        if _spawnRates.isEmpty {
            // Initialize from config file
            for key in Creature.config.keys {
                let id = key.components(separatedBy: CharacterSet(charactersIn: "[\", ]"))[2]
                if let spawnRate = try? Creature.config.double(id, "spawnRate") {
                    _spawnRates.append((id: id, levels: [-1, 0, 1], spawnRate: spawnRate))
                }
            }
        }
        return _spawnRates
    }

    private var isPlayer: Bool {
        return messageStream != nil
    }

    private static func initAttributes(id: String) -> Dictionary<Attribute, Int> {
        var attributes = Dictionary<Attribute, Int>()
        let baseType = try! config.string(id, "basetype")
        let baseTypeAttributes: Array<String> = try! config.array(baseType, "attributes")

        for attribute in baseTypeAttributes {
            let attributeEnum = Attribute(rawValue: attribute)!

            if let attributeValue = try? config.int(id, attribute) {
                attributes[attributeEnum] = attributeValue
            } else {
                guard var superAttribute = Creature.superAttribute(of: attributeEnum) else {
                    fatalError() // TODO: Look up baseType attribute.
                }

                if (try? config.int(id, superAttribute.rawValue)) == nil {
                    superAttribute = Creature.superAttribute(of: superAttribute)!
                    assert(config.hasKey(id, superAttribute.rawValue))
                }

                attributes[attributeEnum] = try! config.int(id, superAttribute.rawValue)
            }
        }

        return attributes
    }

    private func calculateDerivedStats() {
        maxHealth = 2 * endurance + strength / 2
        maxEnergy = 2 * agility + dexterity / 2
        maxMana = 2 * psyche + intelligence / 2
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
}
