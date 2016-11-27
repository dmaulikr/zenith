import XCTest
import Foundation
import Basic
@testable import World

class SerializationTests: XCTestCase {

    private var file: FileHandle!
    private let testFileName = "temporaryTestFile"

    override func setUp() {
        FileManager.default.createFile(atPath: testFileName, contents: nil)
        file = FileHandle(forUpdatingAtPath: testFileName)!
    }

    override func tearDown() {
        try? FileManager.default.removeItem(atPath: testFileName)
    }

    func testTileSerialization() {
        let sourceTile: Tile

        do {
            let world = World(startTime: Time(ticks: 0))
            let area = Area(world: world, position: Vector3(666, -666, 0))
            area.generate()
            sourceTile = area.tile(at: Vector2(Area.size - 1, Area.size - 1))
            sourceTile.groundType = "woodenFloor"
            sourceTile.structure = Structure(type: "tree")
            sourceTile.addItem(Item(type: "bananaPeel"))
            sourceTile.addItem(Item(type: "bananaPeel"))
            sourceTile.addItem(Item(type: "humanCorpse"))
            sourceTile.creature = Creature(type: "bat", tile: sourceTile, controller: AIController())
            sourceTile.creature!.takeDamage(1)
            let saveStream = OutputStream(toMemory: ())
            saveStream.open()
            sourceTile.serialize(to: saveStream)
            saveStream.writeDataToFile(testFileName)
        }

        let world = World(startTime: Time(ticks: 1))
        let area = Area(world: world, position: Vector3(-666, 666, 0))
        let targetTile = Tile(area: area, position: Vector2(Area.size - 1, Area.size - 1))
        let loadStream = InputStream(fileAtPath: testFileName)!
        loadStream.open()
        targetTile.deserialize(from: loadStream)
        XCTAssertEqual(sourceTile, targetTile)
    }

    static let allTests = [
        ("testTileSerialization", testTileSerialization),
    ]
}

protocol EqualAssertable {
    static func assertEqual(_ expression1: Self, _ expression2: Self)
}

func XCTAssertEqual(_ expression1: Tile, _ expression2: Tile) {
    XCTAssertEqual(expression1.position, expression2.position)
    XCTAssertEqual(expression1.items, expression2.items)
    XCTAssertEqual(expression1.structure, expression2.structure)
    XCTAssertEqual(expression1.creature, expression2.creature)
    XCTAssertEqual(expression1.lightColor, expression2.lightColor)
    XCTAssertEqual(expression1.groundType, expression2.groundType)
}

func XCTAssertEqual<T: EqualAssertable>(_ expression1: T?, _ expression2: T?) {
    if let expression1Unwrapped = expression1, let expression2Unwrapped = expression2 {
        T.assertEqual(expression1Unwrapped, expression2Unwrapped)
    } else {
        XCTAssertNil(expression1)
        XCTAssertNil(expression2)
    }
}

extension Entity {
    static func assertEqual(_ entity1: Entity, _ entity2: Entity) {
        XCTAssertEqual(entity1.components.count, entity2.components.count)
        for (component1, component2) in zip(entity1.components, entity2.components) {
            XCTAssert(type(of: component1) == type(of: component2))
            // TODO: Downcast the components and check for equality.
        }
    }
}

extension Object {
    static func assertEqual(_ object1: Object, _ object2: Object) {
        super.assertEqual(object1, object2)
        XCTAssertEqual(object1.type, object2.type)
    }
}

extension Structure: EqualAssertable {
    static func assertEqual(_ structure1: Structure, _ structure2: Structure) {
        super.assertEqual(structure1, structure2)
    }
}

extension Creature: EqualAssertable {
    static func assertEqual(_ creature1: Creature, _ creature2: Creature) {
        super.assertEqual(creature1, creature2)
        XCTAssertEqual(creature1.backpack, creature2.backpack)
        XCTAssertEqual(creature1.wieldedItem, creature2.wieldedItem)
        XCTAssertEqual(creature1.currentAction, creature2.currentAction)
        XCTAssertEqual(creature1.health, creature2.health)
        XCTAssertEqual(creature1.maxHealth, creature2.maxHealth)
        XCTAssertEqual(creature1.energy, creature2.energy)
        XCTAssertEqual(creature1.maxEnergy, creature2.maxEnergy)
        XCTAssertEqual(creature1.mana, creature2.mana)
        XCTAssertEqual(creature1.maxMana, creature2.maxMana)
        XCTAssertEqual(creature1.strength, creature2.strength)
        XCTAssertEqual(creature1.dexterity, creature2.dexterity)
        XCTAssertEqual(creature1.agility, creature2.agility)
        XCTAssertEqual(creature1.endurance, creature2.endurance)
        XCTAssertEqual(creature1.perception, creature2.perception)
        XCTAssertEqual(creature1.intelligence, creature2.intelligence)
        XCTAssertEqual(creature1.psyche, creature2.psyche)
        XCTAssertEqual(creature1.charisma, creature2.charisma)
        if creature1.type == "human" { // basetype == "humanoid"
            XCTAssertEqual(creature1.rightArmStrength, creature2.rightArmStrength)
            XCTAssertEqual(creature1.leftArmStrength, creature2.leftArmStrength)
            XCTAssertEqual(creature1.armStrength, creature2.armStrength)
            XCTAssertEqual(creature1.rightLegStrength, creature2.rightLegStrength)
            XCTAssertEqual(creature1.leftLegStrength, creature2.leftLegStrength)
            XCTAssertEqual(creature1.legStrength, creature2.legStrength)
            XCTAssertEqual(creature1.rightArmDexterity, creature2.rightArmDexterity)
            XCTAssertEqual(creature1.leftArmDexterity, creature2.leftArmDexterity)
            XCTAssertEqual(creature1.rightLegAgility, creature2.rightLegAgility)
            XCTAssertEqual(creature1.leftLegAgility, creature2.leftLegAgility)
        }
    }
}

extension Action: EqualAssertable {
    static func assertEqual(_ action1: Action, _ action2: Action) {
        switch (action1, action2) {
            case (let .resting(action1TicksLeft), let .resting(action2TicksLeft)):
                XCTAssertEqual(action1TicksLeft, action2TicksLeft)
        }
    }
}
