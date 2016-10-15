import Foundation
import Basic

protocol Closeable {

    func close(closer: Creature)
}

class Door: StructureComponent, Closeable {

    private weak var structure: Structure!
    private var openSpritePositionOffset: Vector2i
    private var state: State
    var preventsMovement: Bool { return state == .closed }

    enum State {
        case closed
        case open
    }

    init(structure: Structure, openSpritePositionOffset: Vector2i) {
        self.structure = structure
        self.openSpritePositionOffset = openSpritePositionOffset * tileSize
        state = .closed
    }

    func reactToMovementAttempt(of mover: Creature) {
        if state == .closed {
            if mover.canOpenAndClose {
                open(opener: mover)
                mover.addMessage("You open \(structure.name(.definite)).")
            } else {
                mover.addMessage("You cannot open doors.")
            }
        }
    }

    var blocksSight: Bool {
        return state == .closed
    }

    func open(opener: Creature) {
        state = .open
        structure.sprite.bitmapRegion.position += openSpritePositionOffset
        structure.tile.invalidateRenderCache()
    }

    func close(closer: Creature) {
        if state == .closed {
            closer.addMessage("\(structure.name(.definite, .capitalize)) is already closed.")
            return
        }
        state = .closed
        structure.sprite.bitmapRegion.position -= openSpritePositionOffset
        structure.tile.invalidateRenderCache()
        closer.addMessage("You close \(structure.name(.definite)).")
    }

    func beHit(by hitter: Creature, style: AttackStyle) {
        open(opener: hitter)
        hitter.addMessage("You \(style.verb) \(structure.name(.definite)) open.")
    }

    func serialize(to file: FileHandle) {
        file.write(openSpritePositionOffset)
        file.write(state == .closed)
    }

    func deserialize(from file: FileHandle) {
        file.read(&openSpritePositionOffset)
        var closed = false
        file.read(&closed)
        state = closed ? .closed : .open
        if !closed {
            structure.sprite.bitmapRegion.position += openSpritePositionOffset
        }
    }
}