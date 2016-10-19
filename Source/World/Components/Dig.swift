import Foundation

struct Dig: ItemComponent {

    init() {}

    func use(world: World, user: Creature) {
        if let selectedDirection = user.controller.decideDirection() {
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

    func serialize(to stream: OutputStream) {}

    func deserialize(from stream: InputStream) {}
}
