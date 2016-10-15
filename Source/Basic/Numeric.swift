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

    typealias Serialized = Int64

    public mutating func deserialize(from file: FileHandle) {
        let data = file.readData(ofLength: MemoryLayout<Serialized>.size)
        let deserialized: Serialized = data.withUnsafeBytes {
            (bytePointer: UnsafePointer<UInt8>) -> Serialized in
            bytePointer.withMemoryRebound(to: Serialized.self, capacity: 1) {
                return $0.pointee
            }
        }
        self = Int(Serialized(littleEndian: deserialized))
    }

    public func serialize(to file: FileHandle) {
        var toBeSerialized = Serialized(self).littleEndian
        file.write(Data(bytesNoCopy: &toBeSerialized,
                        count: MemoryLayout<Serialized>.size,
                        deallocator: .none))
    }
}

extension Int32: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }

    typealias Serialized = Int32

    public mutating func deserialize(from file: FileHandle) {
        let data = file.readData(ofLength: MemoryLayout<Serialized>.size)
        let deserialized: Serialized = data.withUnsafeBytes {
            (bytePointer: UnsafePointer<UInt8>) -> Serialized in
            bytePointer.withMemoryRebound(to: Serialized.self, capacity: 1) {
                return $0.pointee
            }
        }
        self = Int32(Serialized(littleEndian: deserialized))
    }

    public func serialize(to file: FileHandle) {
        var toBeSerialized = Serialized(self).littleEndian
        file.write(Data(bytesNoCopy: &toBeSerialized,
                        count: MemoryLayout<Serialized>.size,
                        deallocator: .none))
    }
}

extension Double: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }

    typealias Serialized = Float64

    public mutating func deserialize(from file: FileHandle) {
        let data = file.readData(ofLength: MemoryLayout<Serialized>.size)
        let deserialized: Serialized = data.withUnsafeBytes {
            (bytePointer: UnsafePointer<UInt8>) -> Serialized in
            bytePointer.withMemoryRebound(to: Serialized.self, capacity: 1) {
                return $0.pointee
            }
        }
        self = Double(deserialized)
    }

    public func serialize(to file: FileHandle) {
        var toBeSerialized = Serialized(self)
        file.write(Data(bytesNoCopy: &toBeSerialized,
                        count: MemoryLayout<Serialized>.size,
                        deallocator: .none))
    }
}

extension Float: Numeric {
    public func cast<T: Numeric>() -> T { return T(self) }

    typealias Serialized = Float32

    public mutating func deserialize(from file: FileHandle) {
        let data = file.readData(ofLength: MemoryLayout<Serialized>.size)
        let deserialized: Serialized = data.withUnsafeBytes {
            (bytePointer: UnsafePointer<UInt8>) -> Serialized in
            bytePointer.withMemoryRebound(to: Serialized.self, capacity: 1) {
                return $0.pointee
            }
        }
        self = Float(deserialized)
    }

    public func serialize(to file: FileHandle) {
        var toBeSerialized = Serialized(self)
        file.write(Data(bytesNoCopy: &toBeSerialized,
                        count: MemoryLayout<Serialized>.size,
                        deallocator: .none))
    }
}
