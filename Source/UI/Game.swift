import CSDL2
import Foundation
import Basic
import World

public class Game: State, Serializable {

    private(set) var world: World!
    private(set) var tick: Int = 0
    private var startTime: Time = Time(hours: Int.random(7...17), minutes: Int.random(0...59))
    private unowned let mainMenu: MainMenu
    private(set) var gui: GameGUI
    private var messageStream: MessageStream!
    private var sidebar: Sidebar!
    private(set) var player: Creature!
    private var playerAreaPosition = Vector3i(0, 0, 0)

    public init?(mainMenu: MainMenu, loadSavedGame: Bool = false) {
        self.mainMenu = mainMenu
        gui = GameGUI(resolution: app.window.resolution)

        if loadSavedGame {
            if !FileManager.default.fileExists(atPath: Assets.savedGamePath) {
                return nil
            }
            // Load a saved game.
            guard let saveFile = FileHandle(forReadingAtPath: Assets.globalSavePath) else {
                let globalSaveFileName = Assets.globalSavePath.components(separatedBy: "/").last!
                fatalError("\(globalSaveFileName) not found in \(Assets.savedGamePath)")
            }
            deserialize(from: saveFile)
            world = World(startTime: startTime)
            world.updateAdjacentAreas(relativeTo: playerAreaPosition)
            messageStream = MessageStream(game: self)
            sidebar = Sidebar(gui: gui, game: self)
            var playerTilePosition = Vector2(0, 0)
            saveFile.read(&playerTilePosition)
            player = world.area(at: playerAreaPosition)?.tile(at: playerTilePosition).creature!
            player.controller = PlayerController(game: self)
            player.messageStream = messageStream
        } else {
            // Start a new game.
            world = World(startTime: startTime)
            world.generate()
            messageStream = MessageStream(game: self)
            sidebar = Sidebar(gui: gui, game: self)
            player = Creature(type: "human",
                              tile: world.area(at: Vector3(0, 0, 0))!
                                         .tile(at: Area.sizeVector / 2),
                              controller: PlayerController(game: self),
                              messageStream: messageStream)
        }
    }

    public func enter() {
        gui = GameGUI(resolution: app.window.resolution)
    }

    public func update() {
        if !player.isDead {
            messageStream.makeMessagesOld()
        }

        if playerAreaPosition != player.area.position {
            playerAreaPosition = player.area.position
            world.saveNonAdjacentAreas(player: player)
        }

        do {
            try world.update(player: player)
        } catch CreatureUpdateInterruption.quitToMainMenu {
            app.popState()
        } catch {}

        tick += 1
    }

    public func keyWasPressed(key: SDL_Keycode) -> Bool {
        if player.isDead && Int(key) == SDLK_ESCAPE {
            mainMenu.deleteGame()
            app.popState()
            return true
        }
        return false
    }

    func handlePlayerCommand(key: SDL_Keycode) -> Bool {
        switch Int(key) {
            case SDLK_UP:     return performMoveOrAttack(.north)
            case SDLK_RIGHT:  return performMoveOrAttack(.east)
            case SDLK_DOWN:   return performMoveOrAttack(.south)
            case SDLK_LEFT:   return performMoveOrAttack(.west)
            case SDLK_COMMA:  return performPickUp()
            case SDLK_PERIOD: return performWait()
            case SDLK_r:      return performRest()
            case SDLK_g:      return performGo()
            case SDLK_w:      return performWield()
            case SDLK_u:      return performUse()
            case SDLK_e:      return performEat()
            case SDLK_d:      return performDrop()
            case SDLK_c:      return performClose()
            case SDLK_a:      return performAttack()
            case SDLK_k:      return performKick()
            case SDLK_1:      return performSpawnWall()
            case SDLK_2:      return performSpawnDoor()
            default:          return false
        }
    }

    public func render() {
        world.render(destination: gui.worldViewRect, player: player)
        sidebar.render(region: gui.sidebarRect)
        messageStream.render(region: gui.messageViewRect)
    }

    private func performMoveOrAttack(_ direction: Direction4) -> Bool {
        if let otherCreature = player.tileUnder.adjacentTile(direction.vector)?.creature {
            if player.relationship(to: otherCreature) == .hostile {
                player.hit(direction: direction, style: player.attackStyles.randomElement!)
                return true
            }
        }
        player.tryToMove(direction)
        return true
    }

    private func performPickUp() -> Bool {
        player.pickUpItems()
        return true
    }

    private func performWait() -> Bool {
        return true
    }

    private func performRest() -> Bool {
        let state = TimeQuestion(gui: gui, title: "Rest how long?")
        if let timeToRest = state.waitForResult() {
            player.currentAction = .resting(ticksLeft: timeToRest.ticks)
            return true
        }
        return false
    }

    func performShowInventory() {
        let state = ItemMenu(gui: gui, title: "Inventory", items: player.equipment)
        while state.waitForResult() != nil {}
    }

    private func performGo() -> Bool {
        return player.useStairs()
    }

    private func performWield() -> Bool {
        let state = ItemMenu(gui: gui, title: "Wield what?", items: player.equipment, allowNothingAsOption: true)
        if let selectedItem = state.waitForResult() {
            player.wieldItem(selectedItem)
            return true
        }
        return false
    }

    private func performUse() -> Bool {
        let usableItems = player.equipment.filter { $0.item.isUsable }
        let state = ItemMenu(gui: gui, title: "Use what?", items: usableItems)
        if let selectedItem = state.waitForResult() {
            selectedItem!.use(world: world, user: player)
            return true
        }
        return false
    }

    private func performEat() -> Bool {
        let edibleItems = player.equipment.filter { $0.item.isEdible }
        if edibleItems.isEmpty {
            player.addMessage("You have nothing to eat.")
            return false
        }

        let state = ItemMenu(gui: gui, title: "Eat what?", items: edibleItems)
        if let selectedItem = state.waitForResult() {
            player.eat(selectedItem!)
            if let leftover = selectedItem!.leftover {
                player.tileUnder.addItem(leftover)
            }
            return true
        }
        return false
    }

    private func performDrop() -> Bool {
        let state = ItemMenu(gui: gui, title: "Drop what?", items: player.equipment)
        if let selectedItem = state.waitForResult() {
            player.dropItem(selectedItem!)
            return true
        }
        return false
    }

    private func performClose() -> Bool {
        if !player.canOpenAndClose {
            player.addMessage("You cannot close anything.")
            return false
        }

        let state = DirectionQuestion(gui: gui, title: "Close what?")
        if let direction = state.waitForResult() {
            player.tryToClose(direction: direction)
            return true
        }
        return false
    }

    private func performAttack() -> Bool {
        let state = DirectionQuestion(gui: gui, title: "Attack in which direction?")
        if let direction = state.waitForResult() {
            player.hit(direction: direction, style: player.attackStyles[0])
            return true
        }
        return false
    }

    private func performKick() -> Bool {
        let state = DirectionQuestion(gui: gui, title: "Kick in which direction?")
        if let direction = state.waitForResult() {
            player.hit(direction: direction, style: .kick)
            return true
        }
        return false
    }

    func performShowHelp() {
        app.pushState(HelpView(gui: gui))
        app.runTemporaryState()
    }

    private func performSpawnWall() -> Bool {
        #if !release
            if player.tileUnder.structure != nil {
                player.tileUnder.structure = nil
            } else {
                player.tileUnder.structure = Structure(type: "brickWall")
            }
            return true
        #else
            return false
        #endif
    }

    private func performSpawnDoor() -> Bool {
        #if !release
            if player.tileUnder.structure != nil {
                player.tileUnder.structure = nil
            } else {
                player.tileUnder.structure = Structure(type: "door")
            }
            return true
        #else
            return false
        #endif
    }

    func saveToFile() {
        try? FileManager.default.createDirectory(atPath: Assets.savedGamePath,
                                                 withIntermediateDirectories: false)
        FileManager.default.createFile(atPath: Assets.globalSavePath, contents: nil)
        serialize(to: FileHandle(forWritingAtPath: Assets.globalSavePath)!)
        world.saveUnsavedAreas(player: player)
    }

    public func serialize(to file: FileHandle) {
        file.write(tick)
        file.write(startTime.ticks)
        file.write(player.area.position)
        file.write(player.tileUnder.position)
    }

    public func deserialize(from file: FileHandle) {
        file.read(&tick)
        var startTimeTicks = 0
        file.read(&startTimeTicks)
        startTime = Time(ticks: startTimeTicks)
        file.read(&playerAreaPosition)
    }
}

class PlayerController: CreatureController {

    private unowned let game: Game
    private static var initialized = false

    init(game: Game) {
        self.game = game
        assert(!PlayerController.initialized)
        PlayerController.initialized = true
    }

    deinit {
        PlayerController.initialized = false
    }

    func control(_ player: Creature) throws {
        if player.isResting {
            if app.pollForKeyPress() == SDL_Keycode(SDLK_ESCAPE) {
                player.currentAction = nil
            }
            return
        }

        while true {
            let key = app.waitForKeyPress()

            switch Int(key) {
                case SDLK_ESCAPE: throw CreatureUpdateInterruption.quitToMainMenu
                case SDLK_i: game.performShowInventory()
                case SDLK_h: game.performShowHelp()
                default: if game.handlePlayerCommand(key: key) { return }
            }

            game.render()
            app.window.display()
            app.window.clear()
        }
    }

    func decideDirection() -> Direction4? {
        let state = DirectionQuestion(gui: game.gui, title: "Dig in which direction?")
        return state.waitForResult()
    }
}
