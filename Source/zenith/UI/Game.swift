import CSDL2

class Game: State {

    private let world: World
    private unowned let mainMenu: MainMenu
    private var gui: GameGUI
    private let messageStream: MessageStream
    private let sidebar: Sidebar
    private var player: Creature { return world.player }

    init(mainMenu: MainMenu) {
        self.mainMenu = mainMenu
        gui = GameGUI(resolution: app.window.resolution)
        world = World(worldViewSize: gui.worldViewRect.size / tileSize)
        messageStream = MessageStream(world: world)
        world.player = Creature(id: "human",
                                tile: world.area(at: Vector3(0, 0, 0))!
                                           .tile(at: Area.sizeVector / 2),
                                messageStream: messageStream)
        sidebar = Sidebar(gui: gui, world: world)
        world.update()
    }

    func enter() {
        gui = GameGUI(resolution: app.window.resolution)
    }

    func keyWasPressed(key: SDL_Keycode) {
        if player.isDead {
            if Int(key) != SDLK_ESCAPE {
                return
            }
            mainMenu.deleteGame()
        }

        messageStream.makeMessagesOld()

        switch Int(key) {
            case SDLK_ESCAPE: performQuit()
            case SDLK_UP:     performMove(.north)
            case SDLK_RIGHT:  performMove(.east)
            case SDLK_DOWN:   performMove(.south)
            case SDLK_LEFT:   performMove(.west)
            case SDLK_COMMA:  performPickUp()
            case SDLK_PERIOD: performWait()
            case SDLK_r:      performRest()
            case SDLK_i:      performShowInventory()
            case SDLK_g:      performGo()
            case SDLK_w:      performWield()
            case SDLK_u:      performUse()
            case SDLK_e:      performEat()
            case SDLK_d:      performDrop()
            case SDLK_c:      performClose()
            case SDLK_a:      performAttack()
            case SDLK_k:      performKick()
            case SDLK_h:      performShowHelp()
            case SDLK_1:      performSpawnWall()
            case SDLK_2:      performSpawnDoor()
            default:          break
        }
    }

    func render() {
        world.render(destination: gui.worldViewRect)
        sidebar.render(region: gui.sidebarRect)
        messageStream.render(region: gui.messageViewRect)
    }

    private func performQuit() {
        app.popState()
    }

    private func performMove(_ direction: Direction4) {
        player.tryToMove(direction)
        world.update()
    }

    private func performPickUp() {
        player.pickUpItems()
        world.update()
    }

    private func performWait() {
        world.update()
    }

    private func performRest() {
        let state = TimeQuestion(gui: gui, title: "Rest how long?")
        if let timeToRest = state.waitForResult() {
            player.currentAction = .resting
            for _ in 0..<timeToRest.ticks {
                world.update(playerIsResting: true)
                if player.currentAction != .resting {
                    break
                }
            }
            player.currentAction = nil
        }
    }

    private func performShowInventory() {
        let state = ItemMenu(gui: gui, title: "Inventory", items: player.equipment)
        while state.waitForResult() != nil {}
    }

    private func performGo() {
        if player.useStairs() {
            world.update()
        }
    }

    private func performWield() {
        let state = ItemMenu(gui: gui, title: "Wield what?", items: player.equipment, allowNothingAsOption: true)
        if let selectedItem = state.waitForResult() {
            player.wieldItem(selectedItem)
            world.update()
        }
    }

    private func performUse() {
        let usableItems = player.equipment.filter { $0.item.isUsable }
        let state = ItemMenu(gui: gui, title: "Use what?", items: usableItems)
        if let selectedItem = state.waitForResult() {
            selectedItem!.use(world: world, gui: gui, user: player)
            world.update()
        }
    }

    private func performEat() {
        let edibleItems = player.equipment.filter { $0.item.isEdible }
        if edibleItems.isEmpty {
            player.addMessage("You have nothing to eat.")
            return
        }

        let state = ItemMenu(gui: gui, title: "Eat what?", items: edibleItems)
        if let selectedItem = state.waitForResult() {
            player.eat(selectedItem!)
            if let leftover = selectedItem!.leftover {
                player.tileUnder.addItem(leftover)
            }
            world.update()
        }
    }

    private func performDrop() {
        let state = ItemMenu(gui: gui, title: "Drop what?", items: player.equipment)
        if let selectedItem = state.waitForResult() {
            player.dropItem(selectedItem!)
            world.update()
        }
    }

    private func performClose() {
        if !player.canOpenAndClose {
            player.addMessage("You cannot close anything.")
            return
        }

        let state = DirectionQuestion(gui: gui, title: "Close what?")
        if let direction = state.waitForResult() {
            player.tryToClose(direction: direction)
            world.update()
        }
    }

    private func performAttack() {
        let state = DirectionQuestion(gui: gui, title: "Attack in which direction?")
        if let direction = state.waitForResult() {
            player.hit(direction: direction, style: player.attackStyles[0])
            world.update()
        }
    }

    private func performKick() {
        let state = DirectionQuestion(gui: gui, title: "Kick in which direction?")
        if let direction = state.waitForResult() {
            player.hit(direction: direction, style: .kick)
            world.update()
        }
    }

    private func performShowHelp() {
        app.pushState(HelpView(gui: gui))
    }

    private func performSpawnWall() {
        #if !release
            if player.tileUnder.structure != nil {
                player.tileUnder.structure = nil
            } else {
                player.tileUnder.structure = Structure(id: "brickWall")
            }
            world.update()
        #endif
    }

    private func performSpawnDoor() {
        #if !release
            if player.tileUnder.structure != nil {
                player.tileUnder.structure = nil
            } else {
                player.tileUnder.structure = Structure(id: "door")
            }
            world.update()
        #endif
    }
}
