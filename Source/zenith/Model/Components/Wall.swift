import Foundation

class Wall: StructureComponent {

    var blocksSight: Bool = true
    var preventsMovement: Bool = true

    init() {}

    func reactToMovementAttempt(of mover: Creature) {
        mover.addMessage("The wall blocks your way.")
    }

    func serialize(to file: FileHandle) {}

    func deserialize(from file: FileHandle) {}
}
