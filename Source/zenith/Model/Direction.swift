enum Direction4 {
    case north
    case east
    case south
    case west

    var vector: Vector2i {
        switch self {
            case .north: return Vector2( 0, -1)
            case .east:  return Vector2( 1,  0)
            case .south: return Vector2( 0,  1)
            case .west:  return Vector2(-1,  0)
        }
    }

    static var random: Direction4 {
        switch Int.random(0..<4) {
            case 0: return .north
            case 1: return .east
            case 2: return .south
            case 3: return .west
            default:
                assertionFailure("unreachable")
                fatalError()
        }
    }
}

enum Direction8 {
    case north
    case northEast
    case east
    case southEast
    case south
    case southWest
    case west
    case northWest

    var vector: Vector2i {
        switch self {
            case .north:     return Vector2( 0, -1)
            case .northEast: return Vector2( 1, -1)
            case .east:      return Vector2( 1,  0)
            case .southEast: return Vector2( 1,  1)
            case .south:     return Vector2( 0,  1)
            case .southWest: return Vector2(-1,  1)
            case .west:      return Vector2(-1,  0)
            case .northWest: return Vector2(-1, -1)
        }
    }

    static var random: Direction8 {
        switch Int.random(0..<8) {
            case 0: return .north
            case 1: return .northEast
            case 2: return .east
            case 3: return .southEast
            case 4: return .south
            case 5: return .southWest
            case 6: return .west
            case 7: return .northWest
            default:
                assertionFailure("unreachable")
                fatalError()
        }
    }
}
