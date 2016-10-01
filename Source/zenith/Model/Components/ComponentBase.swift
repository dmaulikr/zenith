protocol StructureComponent: Component {

    var blocksSight: Bool { get }
    var preventsMovement: Bool { get }

    func reactToMovementAttempt(of mover: Creature)
}

protocol ItemComponent: Component {

    func use(world: World, gui: GameGUI, user: Creature)
}
