class Dig: ItemComponent {

    func use(world: World, gui: GraphicalUserInterface, user: Creature) {
        let state = DirectionChooser(gui: gui, title: "Dig in which direction?") {
            if let selectedDirection = $0 {
                self.dig(direction: selectedDirection, digger: user, world: world)
            }
        }
        app.pushState(state)
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
        world.update()
    }
}
