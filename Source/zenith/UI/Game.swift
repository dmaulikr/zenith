import CSDL2
import Foundation

class Game: State {

    private let world: World
    private unowned let mainMenu: MainMenu
    private var gui: GameGUI
    private let messageStream: MessageStream
    private let sidebar: Sidebar
    private var player: Creature { return world.player }

    init?(mainMenu: MainMenu, loadSavedGame: Bool = false) {
        self.mainMenu = mainMenu
        gui = GameGUI(resolution: app.window.resolution)

        if loadSavedGame {
            if !FileManager.default.fileExists(atPath: Assets.savedGamePath) {
                return nil
            }
            // Load a saved game.
            world = World(worldViewSize: gui.worldViewRect.size / tileSize)
            world.deserialize(from: FileHandle(forReadingAtPath: Assets.worldFilePath)!)
            world.updateAdjacentAreas(relativeTo: world.playerAreaPosition)
            messageStream = MessageStream(world: world)
            sidebar = Sidebar(gui: gui, world: world)
            player.controller = PlayerController(game: self)
            player.messageStream = messageStream
        } else {
            // Start a new game.
            world = World(worldViewSize: gui.worldViewRect.size / tileSize)
            world.generate()
            messageStream = MessageStream(world: world)
            sidebar = Sidebar(gui: gui, world: world)
            world.player = Creature(id: "human",
                                    tile: world.area(at: Vector3(0, 0, 0))!
                                               .tile(at: Area.sizeVector / 2),
                                    controller: PlayerController(game: self),
                                    messageStream: messageStream)
        }

        world.calculateFogOfWar()
    }

    func enter() {
        gui = GameGUI(resolution: app.window.resolution)
    }

    func update() {
        if !player.isDead {
            messageStream.makeMessagesOld()
        }

        do {
            try world.update()
        } catch CreatureUpdateInterruption.quitToMainMenu {
            app.popState()
        } catch {}
    }

    func keyWasPressed(key: SDL_Keycode) {
        if player.isDead && Int(key) == SDLK_ESCAPE {
            mainMenu.deleteGame()
            app.popState()
        }
    }

    func handlePlayerCommand(key: SDL_Keycode) -> Bool {
        switch Int(key) {
            case SDLK_UP:     return performMove(.north)
            case SDLK_RIGHT:  return performMove(.east)
            case SDLK_DOWN:   return performMove(.south)
            case SDLK_LEFT:   return performMove(.west)
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

    func render() {
        world.render(destination: gui.worldViewRect)
        sidebar.render(region: gui.sidebarRect)
        messageStream.render(region: gui.messageViewRect)
    }

    private func performMove(_ direction: Direction4) -> Bool {
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
            selectedItem!.use(world: world, gui: gui, user: player)
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
                player.tileUnder.structure = Structure(id: "brickWall")
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
                player.tileUnder.structure = Structure(id: "door")
            }
            return true
        #else
            return false
        #endif
    }

    func saveToFile() {
        let fileManager = FileManager()
        try? fileManager.createDirectory(atPath: Assets.savedGamePath,
                                         withIntermediateDirectories: false)
        fileManager.createFile(atPath: Assets.worldFilePath, contents: nil)
        world.serialize(to: FileHandle(forWritingAtPath: Assets.worldFilePath)!)
        world.serializeAreas(to: Assets.savedGamePath)
    }
}
