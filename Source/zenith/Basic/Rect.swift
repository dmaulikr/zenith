import CSDL2

/// An axis-aligned rectangle.
public struct Rect<T: Numeric> {

    /// The position of the top-left corner.
    public var position: Vector2<T>

    public var size: Vector2<T>

    /// Creates a rectangle from a position (of the top-left corner) and size.
    public init(position: Vector2<T>, size: Vector2<T>) {
        assert(size.x >= T(0) && size.y >= T(0), "size cannot be negative")
        self.position = position
        self.size = size
    }

    /// Creates a rectangle with the specified top-left and bottom-right corners.
    public init(topLeft: Vector2<T>, bottomRight: Vector2<T>) {
        assert(bottomRight.x >= topLeft.x, "right x cannot be less than left x")
        assert(bottomRight.y >= topLeft.y, "bottom y cannot be less than top y")
        self.position = topLeft
        self.size = bottomRight - topLeft
    }

    /// Creates a rectangle with the specified center point and size.
    public init(center: Vector2<T>, size: Vector2<T>) {
        assert(size.x >= T(0) && size.y >= T(0), "size cannot be negative")
        self.position = center - size / T(2)
        self.size = size
    }

    /// The x-coordinate of the left side.
    public var left: T {
        return position.x
    }

    /// The y-coordinate of the top side.
    public var top: T {
        return position.y
    }

    /// The x-coordinate of the right side.
    public var right: T {
        return position.x + size.x
    }

    /// The y-coordinate of the bottom side.
    public var bottom: T {
        return position.y + size.y
    }

    /// The position of the top-left corner.
    public var topLeft: Vector2<T> {
        return Vector2<T>(left, top)
    }

    /// The position of the top-right corner.
    public var topRight: Vector2<T> {
        return Vector2<T>(right, top)
    }

    /// The position of the bottom-right corner.
    public var bottomRight: Vector2<T> {
        return Vector2<T>(right, bottom)
    }

    /// The position of the bottom-left corner.
    public var bottomLeft: Vector2<T> {
        return Vector2<T>(left, bottom)
    }

    /// An array containing the positions of all four corners.
    public var corners: [Vector2<T>] {
        return [topLeft, topRight, bottomRight, bottomLeft]
    }

    /// The center position of the rectangle.
    public var center: Vector2<T> {
        return position + size / T(2)
    }

    public func overlaps(_ other: Rect) -> Bool {
        return left < other.right && right > other.left
            && top < other.bottom && bottom > other.top
    }

    public func overlappingRect(with other: Rect) -> Rect {
        let x = max(left, other.left)
        let y = max(top, other.top)
        let width = min(right, other.right) - x
        let height = min(bottom, other.bottom) - y
        return Rect(position: Vector2(x, y), size: Vector2(width, height))
    }

    public func moved(by vector: Vector2<T>) -> Rect {
        return Rect(position: position + vector, size: size)
    }

    public mutating func move(by vector: Vector2<T>) {
        position += vector
    }

    public func resized(by vector: Vector2<T>) -> Rect {
        return Rect(position: position, size: size + vector)
    }

    public mutating func resize(by vector: Vector2<T>) {
        size += vector
    }

    func asSDLRect() -> SDL_Rect {
        return SDL_Rect(x: position.x.cast(),
                        y: position.y.cast(),
                        w: size.x.cast(),
                        h: size.y.cast())
    }
}
