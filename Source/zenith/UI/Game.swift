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
        let state = TimeQuestion(gui: gui, title: "Rest how long?") {
            if let timeToRest = $0 {
                self.player.currentAction = .resting
                for _ in 0..<timeToRest.ticks {
                    self.world.update(playerIsResting: true)
                    if self.player.currentAction != .resting {
                        break
                    }
                }
                self.player.currentAction = nil
            }
        }
        app.pushState(state)
    }

    private func performShowInventory() {
        let state = ItemMenu(gui: gui, title: "Inventory", items: player.equipment) {
            if $0 == nil {
                app.popState()
            }
        }
        app.pushState(state)
    }

    private func performGo() {
        if player.useStairs() {
            world.update()
        }
    }

    private func performWield() {
        let state = ItemMenu(gui: gui, title: "Wield what?", items: player.equipment, allowNothingAsOption: true) {
            app.popState()
            if let selectedItem = $0 {
                self.player.wieldItem(selectedItem)
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performUse() {
        let usableItems = player.equipment.filter { $0.item.isUsable }
        let state = ItemMenu(gui: gui, title: "Use what?", items: usableItems) {
            app.popState()
            if let selectedItem = $0 {
                selectedItem!.use(world: self.world, gui: self.gui, user: self.player)
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performEat() {
        let edibleItems = player.equipment.filter { $0.item.isEdible }
        if edibleItems.isEmpty {
            player.addMessage("You have nothing to eat.")
            return
        }

        let state = ItemMenu(gui: gui, title: "Eat what?", items: edibleItems) {
            app.popState()
            if let selectedItem = $0 {
                self.player.eat(selectedItem!)
                if let leftover = selectedItem!.leftover {
                    self.player.tileUnder.addItem(leftover)
                }
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performDrop() {
        let state = ItemMenu(gui: gui, title: "Drop what?", items: player.equipment) {
            app.popState()
            if let selectedItem = $0 {
                self.player.dropItem(selectedItem!)
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performClose() {
        let state = DirectionQuestion(gui: gui, title: "Close what?") {
            if let direction = $0 {
                self.player.tryToClose(direction: direction)
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performAttack() {
        let state = DirectionQuestion(gui: gui, title: "Attack in which direction?") {
            if let direction = $0 {
                self.player.hit(direction: direction, style: .hit)
                self.world.update()
            }
        }
        app.pushState(state)
    }

    private func performKick() {
        let state = DirectionQuestion(gui: gui, title: "Kick in which direction?") {
            if let direction = $0 {
                self.player.hit(direction: direction, style: .kick)
                self.world.update()
            }
        }
        app.pushState(state)
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
