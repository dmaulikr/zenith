import Foundation

public struct Vector2<T: Numeric> {

    public var x: T
    public var y: T

    public init(_ x: T, _ y: T) {
        self.x = x
        self.y = y
    }

    public init<U: Numeric>(_ other: Vector2<U>) {
        self.x = other.x.cast()
        self.y = other.y.cast()
    }

    public init(_ other: Vector3<T>) {
        self.x = other.x
        self.y = other.y
    }

    public init(radians: Float) {
        self.x = T(cos(radians))
        self.y = T(sin(radians))
    }

    /// The angle of this vector relative to the x-axis, in radians.
    /// If this is a zero vector, the value is unspecified.
    public var angle: Float {
        return atan2(y.cast(), x.cast())
    }

    public var length: Double {
        return sqrt(lengthSquared.cast())
    }

    public var lengthSquared: T {
        return x * x + y * y
    }
}

public typealias Vector2i = Vector2<Int>
public typealias Vector2d = Vector2<Double>
public typealias Vector2f = Vector2<Float>

public func +<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(left.x + right.x, left.y + right.y)
}

public func +=<T: Numeric>(left: inout Vector2<T>, right: Vector2<T>) {
    left = left + right
}

public func -<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(left.x - right.x, left.y - right.y)
}

public func -=<T: Numeric>(left: inout Vector2<T>, right: Vector2<T>) {
    left = left - right
}

public func *<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(left.x * right.x, left.y * right.y)
}

public func *=<T: Numeric>(left: inout Vector2<T>, right: Vector2<T>) {
    left = left * right
}

public func /<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(left.x / right.x, left.y / right.y)
}

public func /=<T: Numeric>(left: inout Vector2<T>, right: Vector2<T>) {
    left = left / right
}

public func %<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(left.x % right.x, left.y % right.y)
}

public func %=<T: Numeric>(left: inout Vector2<T>, right: Vector2<T>) {
    left = left % right
}

public func *<T: Numeric>(left: Vector2<T>, right: T) -> Vector2<T> {
    return Vector2<T>(left.x * right, left.y * right)
}

public func *=<T: Numeric>(left: inout Vector2<T>, right: T) {
    left = left * right
}

public func /<T: Numeric>(left: Vector2<T>, right: T) -> Vector2<T> {
    return Vector2<T>(left.x / right, left.y / right)
}

public func /=<T: Numeric>(left: inout Vector2<T>, right: T) {
    left = left / right
}

public func %<T: Numeric>(left: Vector2<T>, right: T) -> Vector2<T> {
    return Vector2<T>(left.x % right, left.y % right)
}

public func %=<T: Numeric>(left: inout Vector2<T>, right: T) {
    left = left % right
}

public prefix func +<T: Numeric>(vector: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(+vector.x, +vector.y)
}

public prefix func -<T: Numeric>(vector: Vector2<T>) -> Vector2<T> {
    return Vector2<T>(-vector.x, -vector.y)
}

public func ==<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Bool {
    return left.x == right.x && left.y == right.y
}

public func !=<T: Numeric>(left: Vector2<T>, right: Vector2<T>) -> Bool {
    return !(left == right)
}

extension Vector2: Hashable {
    public var hashValue: Int {
        return (x * T(73856093)).cast()
             ^ (y * T(19349663)).cast()
    }
}

extension Vector2: Serializable {
    public func serialize(to stream: OutputStream) {
        stream <<< x <<< y
    }

    public mutating func deserialize(from stream: InputStream) {
        stream >>> x >>> y
    }
}
