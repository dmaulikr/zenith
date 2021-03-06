import Basic

public enum Direction4 {
    case north
    case east
    case south
    case west

    public var vector: Vector2i {
        switch self {
            case .north: return Vector2( 0, -1)
            case .east:  return Vector2( 1,  0)
            case .south: return Vector2( 0,  1)
            case .west:  return Vector2(-1,  0)
        }
    }

    static var allDirections: [Direction4] = [.north, .east, .south, .west]

    static var random: Direction4 {
        return allDirections.randomElement!
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

    public var vector: Vector2i {
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

    static var allDirections: [Direction8] = [.north, .northEast, .east, .southEast,
                                              .south, .southWest, .west, .northWest]

    static var random: Direction8 {
        return allDirections.randomElement!
    }
}
