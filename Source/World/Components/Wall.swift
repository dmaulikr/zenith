import Foundation

struct Wall: StructureComponent {

    var blocksSight: Bool = true
    var preventsMovement: Bool = true

    init() {}

    func reactToMovementAttempt(of mover: Creature) {
        mover.addMessage("The wall blocks your way.")
    }

    func serialize(to stream: OutputStream) {}

    func deserialize(from stream: InputStream) {}
}
