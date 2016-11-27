import XCTest
import CSDL2
import Basic
import Graphics
@testable import World
@testable import UI

class CommandTests: XCTestCase {

    var game: Game!

    override func setUp() {
        app = Application(size: Vector2(512, 384))
        font = MockFont()
        let mainMenu = MainMenu(font: font)
        game = Game(mainMenu: mainMenu)!
        app.pushState(game)
    }

    override func tearDown() {
        game = nil
        app = nil
    }

    func testMove() {
        let oldPosition = game.player.tileUnder.globalPosition

        game.player.tileUnder.adjacentTile(Vector2(-1, 0))!.structure = nil
        game.player.tileUnder.adjacentTile(Vector2(-1, 0))!.creature = nil
        sendKeyDownEvent(SDLK_LEFT) // Move west.
        game.update()
        XCTAssertEqual(game.player.tileUnder.globalPosition, oldPosition + Vector2(-1, 0))

        game.player.tileUnder.adjacentTile(Vector2(0, 1))!.structure = nil
        game.player.tileUnder.adjacentTile(Vector2(0, 1))!.creature = nil
        sendKeyDownEvent(SDLK_DOWN) // Move south.
        game.update()
        XCTAssertEqual(game.player.tileUnder.globalPosition, oldPosition + Vector2(-1, 1))
    }

    func testPickUp() {
        game.player.backpack = []
        game.player.tileUnder.removeAllItems()
        game.player.tileUnder.addItem(Item(type: "lantern"))
        game.player.tileUnder.addItem(Item(type: "pickaxe"))
        sendKeyDownEvent(SDLK_COMMA) // Pick up the pickaxe.
        game.update()
        XCTAssertEqual(game.player.backpack, [Item(type: "pickaxe")])
        sendKeyDownEvent(SDLK_COMMA) // Pick up the lantern.
        game.update()
        XCTAssertEqual(game.player.backpack, [Item(type: "pickaxe"), Item(type: "lantern")])
    }

    func testWield() {
        game.player.backpack = [Item(type: "lantern"), Item(type: "pickaxe")]
        game.player.wieldItem(nil)
        sendKeyDownEvent(SDLK_w) // Open wield menu.
        sendKeyDownEvent(SDLK_DOWN) // Select pickaxe.
        sendKeyDownEvent(SDLK_RETURN) // Wield it.
        game.update()
        XCTAssertEqual(game.player.wieldedItem, Item(type: "pickaxe"))
    }

    func testDig() {
        game.player.backpack = [Item(type: "lantern"), Item(type: "pickaxe")]
        game.player.tileUnder.adjacentTile(Vector2(-1, 0))!.structure = Structure(type: "ground")
        sendKeyDownEvent(SDLK_u) // Open use menu, the pickaxe should be selected.
        sendKeyDownEvent(SDLK_RETURN) // Use pickaxe.
        sendKeyDownEvent(SDLK_LEFT) // Select dig direction.
        game.update()
        XCTAssertNil(game.player.tileUnder.adjacentTile(Vector2(-1, 0))!.structure)
    }

    func testEat() {
        game.player.backpack = [Item(type: "lantern"), Item(type: "banana")]
        game.player.tileUnder.removeAllItems()
        sendKeyDownEvent(SDLK_e) // Open eat menu, the banana should be selected.
        sendKeyDownEvent(SDLK_RETURN) // Eat it.
        game.update()
        XCTAssertEqual(game.player.backpack, [Item(type: "lantern")])
        XCTAssertEqual(game.player.tileUnder.items, [Item(type: "bananaPeel")])
    }

    func testDrop() {
        game.player.backpack = [Item(type: "lantern"), Item(type: "banana")]
        game.player.tileUnder.removeAllItems()
        sendKeyDownEvent(SDLK_d) // Open drop menu.
        sendKeyDownEvent(SDLK_DOWN) // Select banana.
        sendKeyDownEvent(SDLK_RETURN) // Drop it.
        game.update()
        XCTAssertEqual(game.player.backpack, [Item(type: "lantern")])
        XCTAssertEqual(game.player.tileUnder.items, [Item(type: "banana")])
    }

    func testCloseDoor() {
        let door = Structure(type: "door")
        game.player.tileUnder.adjacentTile(Vector2(-1, 0))?.structure = door
        let doorComponent: Door = door.getComponent()
        doorComponent.open(opener: game.player) // Set initial state to open.
        sendKeyDownEvent(SDLK_c) // Open close menu.
        sendKeyDownEvent(SDLK_LEFT) // Select direction.
        sendKeyDownEvent(SDLK_RETURN) // Close the door.
        game.update()
        XCTAssert(doorComponent.state == .closed)
    }

    static let allTests = [
        ("testMove", testMove),
        ("testPickUp", testPickUp),
        ("testWield", testWield),
        ("testDig", testDig),
        ("testEat", testEat),
        ("testDrop", testDrop),
        ("testCloseDoor", testCloseDoor),
    ]
}

struct MockFont: Font {
    func renderText(_: String, at: Vector2i, color: Color) { }
    func renderText(_: String, at: Vector2i, color: Color, align: Alignment) { }
    func textWidth(_ text: String) -> Int { return 0 }
    var height: Int { return 0 }
}

private func sendKeyDownEvent(_ key: Int) {
    var mockEvent = SDL_Event()
    mockEvent.type = SDL_KEYDOWN.rawValue
    mockEvent.key.keysym.sym = SDL_Keycode(key)
    XCTAssertEqual(SDL_PushEvent(&mockEvent), 1)
}
