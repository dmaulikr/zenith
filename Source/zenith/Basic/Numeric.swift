public protocol Numeric: Equatable, Comparable {
    init(_: Int)
    init(_: Int32)
    init(_: Double)
    init(_: Float)
    func +(_: Self, _: Self) -> Self
    func -(_: Self, _: Self) -> Self
    func *(_: Self, _: Self) -> Self
    func /(_: Self, _: Self) -> Self
    func %(_: Self, _: Self) -> Self
    prefix func +(_: Self) -> Self
    prefix func -(_: Self) -> Self
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
