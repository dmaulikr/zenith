import Foundation

class Dig: ItemComponent {

    init() {}

    func use(world: World, gui: GameGUI, user: Creature) {
        let state = DirectionQuestion(gui: gui, title: "Dig in which direction?")
        if let selectedDirection = state.waitForResult() {
            self.dig(direction: selectedDirection, digger: user, world: world)
        }
    }

    private func dig(direction: Direction4, digger: Creature, world: World) {
        guard let tileToDig = digger.tileUnder.adjacentTile(direction.vector) else {
            return
        }
        if let structureToDig = tileToDig.structure {
            tileToDig.structure = nil
            digger.addMessage("You dig \(structureToDig.name(.definite)).")
        } else {
            digger.addMessage("You dig the air.")
        }
    }

    func serialize(to file: FileHandle) {}

    func deserialize(from file: FileHandle) {}
}
