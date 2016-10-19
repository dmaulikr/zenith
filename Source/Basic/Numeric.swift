import Foundation

public protocol Numeric: Equatable, Comparable, Serializable {
    init(_: Int)
    init(_: Int32)
    init(_: Double)
    init(_: Float)
    static func +(_: Self, _: Self) -> Self
    static func -(_: Self, _: Self) -> Self
    static func *(_: Self, _: Self) -> Self
    static func /(_: Self, _: Self) -> Self
    static func %(_: Self, _: Self) -> Self
    prefix static func +(_: Self) -> Self
    prefix static func -(_: Self) -> Self
    func cast<T: Numeric>() -> T
}

extension Int: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }
}

extension Int32: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }
}

extension Double: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }
}

extension Float: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }
}
