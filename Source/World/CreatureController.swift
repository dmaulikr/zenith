import CSDL2

public protocol CreatureController {

    func control(_ controlledCreature: Creature) throws

    func decideDirection() -> Direction4?
}

public enum CreatureUpdateInterruption: Error {
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

    func decideDirection() -> Direction4? {
        return Direction4.random
    }
}
