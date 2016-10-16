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
        if npc.isResting { return }

        var didAttack = false

        for direction in Direction4.allDirections {
            if let otherCreature = npc.tileUnder.adjacentTile(direction.vector)?.creature {
                if npc.relationship(to: otherCreature) == .hostile {
                    npc.hit(direction: direction)
                    didAttack = true
                    break
                }
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
