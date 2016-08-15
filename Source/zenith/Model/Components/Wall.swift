class Wall: StructureComponent {

    var blocksSight: Bool = true
    var preventsMovement: Bool = true

    func reactToMovementAttempt(of mover: Creature) {
        mover.addMessage("The wall blocks your way.")
    }
}
