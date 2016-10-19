import Foundation
import Basic

protocol Closeable {

    func close(closer: Creature)
}

class Door: StructureComponent, Closeable {

    private weak var structure: Structure!
    private var openSpritePositionOffset: Vector2i
    private(set) var state: State
    var preventsMovement: Bool { return state == .closed }

    enum State: Serializable {
        case closed
        case open

        public func serialize(to stream: OutputStream) {
            stream <<< (self == .closed)
        }

        public mutating func deserialize(from stream: InputStream) {
            self = stream.readBool() ? .closed : .open
        }
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

    func serialize(to stream: OutputStream) {
        stream <<< openSpritePositionOffset <<< state
    }

    func deserialize(from stream: InputStream) {
        stream >>> openSpritePositionOffset >>> state
        if state == .open { structure.sprite.bitmapRegion.position += openSpritePositionOffset }
    }
}
