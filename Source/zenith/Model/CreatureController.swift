import CSDL2

protocol CreatureController {

    func control(_ controlledCreature: Creature) throws
}

struct PlayerController: CreatureController {

    private unowned let game: Game
    static var initialized = false

    init(game: Game) {
        self.game = game
        assert(!PlayerController.initialized)
        PlayerController.initialized = true
    }

    func control(_ player: Creature) throws {
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
}

enum CreatureUpdateInterruption: Error {
    case quitToMainMenu
}

struct AIController: CreatureController {

    func control(_ npc: Creature) {
        var didAttack = false

        for direction in Direction4.allDirections {
            if let enemy = npc.tileUnder.adjacentTile(direction.vector)?.creature, enemy.type != npc.type {
                let attackStyle = npc.wieldedItem != nil ? .hit : npc.attackStyles.randomElement()!
                npc.hit(direction: direction, style: attackStyle)
                didAttack = true
                break
            }
        }

        if !didAttack {
            npc.tryToMove(Direction4.random)
        }
    }
}
