import Foundation

public struct Vector3<T: Numeric> {

    public var x: T
    public var y: T
    public var z: T

    public init(_ x: T, _ y: T, _ z: T) {
        self.x = x
        self.y = y
        self.z = z
    }

    public init<U: Numeric>(_ other: Vector3<U>) {
        self.x = other.x.cast()
        self.y = other.y.cast()
        self.z = other.z.cast()
    }

    public init(_ other: Vector2<T>) {
        self.x = other.x
        self.y = other.y
        self.z = T(0)
    }

    public var length: Double {
        return sqrt(lengthSquared.cast())
    }

    public var lengthSquared: T {
        return x * x + y * y + z * z
    }
}

public typealias Vector3i = Vector3<Int>
public typealias Vector3d = Vector3<Double>
public typealias Vector3f = Vector3<Float>

@_specialize(Int)
public func +<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(left.x + right.x, left.y + right.y, left.z + right.z)
}

public func +=<T: Numeric>(left: inout Vector3<T>, right: Vector3<T>) {
    left = left + right
}

@_specialize(Int)
public func -<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(left.x - right.x, left.y - right.y, left.z - right.z)
}

public func -=<T: Numeric>(left: inout Vector3<T>, right: Vector3<T>) {
    left = left - right
}

@_specialize(Int)
public func *<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(left.x * right.x, left.y * right.y, left.z * right.z)
}

public func *=<T: Numeric>(left: inout Vector3<T>, right: Vector3<T>) {
    left = left * right
}

@_specialize(Int)
public func /<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(left.x / right.x, left.y / right.y, left.z / right.z)
}

public func /=<T: Numeric>(left: inout Vector3<T>, right: Vector3<T>) {
    left = left / right
}

@_specialize(Int)
public func %<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(left.x % right.x, left.y % right.y, left.z % right.z)
}

public func %=<T: Numeric>(left: inout Vector3<T>, right: Vector3<T>) {
    left = left % right
}

@_specialize(Int)
public func *<T: Numeric>(left: Vector3<T>, right: T) -> Vector3<T> {
    return Vector3<T>(left.x * right, left.y * right, left.z * right)
}

public func *=<T: Numeric>(left: inout Vector3<T>, right: T) {
    left = left * right
}

@_specialize(Int)
public func /<T: Numeric>(left: Vector3<T>, right: T) -> Vector3<T> {
    return Vector3<T>(left.x / right, left.y / right, left.z / right)
}

public func /=<T: Numeric>(left: inout Vector3<T>, right: T) {
    left = left / right
}

@_specialize(Int)
public func %<T: Numeric>(left: Vector3<T>, right: T) -> Vector3<T> {
    return Vector3<T>(left.x % right, left.y % right, left.z % right)
}

public func %=<T: Numeric>(left: inout Vector3<T>, right: T) {
    left = left % right
}

@_specialize(Int)
public prefix func +<T: Numeric>(vector: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(+vector.x, +vector.y, +vector.z)
}

@_specialize(Int)
public prefix func -<T: Numeric>(vector: Vector3<T>) -> Vector3<T> {
    return Vector3<T>(-vector.x, -vector.y, -vector.z)
}

@_specialize(Int)
public func ==<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Bool {
    return left.x == right.x && left.y == right.y && left.z == right.z
}

@_specialize(Int)
public func !=<T: Numeric>(left: Vector3<T>, right: Vector3<T>) -> Bool {
    return !(left == right)
}

extension Vector3: Hashable {
    public var hashValue: Int {
        return (x * T(73856093)).cast()
             ^ (y * T(19349663)).cast()
             ^ (z * T(83492791)).cast()
    }
}

extension Vector3: Serializable {
    public func serialize(to stream: OutputStream) {
        stream <<< x <<< y <<< z
    }

    public mutating func deserialize(from stream: InputStream) {
        stream >>> x >>> y >>> z
    }
}
