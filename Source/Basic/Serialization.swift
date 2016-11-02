import Foundation

public protocol Serializable {
    func serialize(to stream: OutputStream)
    mutating func deserialize(from stream: InputStream)
}

infix operator <<<: StreamingPrecedence
infix operator >>>: StreamingPrecedence

precedencegroup StreamingPrecedence {
    associativity: left
}

@inline(__always)
@discardableResult
public func <<< <T: Serializable>(stream: OutputStream, value: T) -> OutputStream {
    value.serialize(to: stream)
    return stream
}

@inline(__always)
@discardableResult
public func >>> <T: Serializable>(stream: InputStream, value: inout T) -> InputStream {
    value.deserialize(from: stream)
    return stream
}

@discardableResult
public func <<< <T: Serializable>(stream: OutputStream, value: T?) -> OutputStream {
    stream <<< (value != nil)
    if let wrappedValue = value {
        stream <<< wrappedValue
    }
    return stream
}

@discardableResult
public func <<< <Key, Value>(stream: OutputStream, dictionary: [Key: Value]) -> OutputStream
    where Key: Serializable, Value: Serializable {
    stream <<< dictionary.count
    dictionary.forEach { stream <<< $0 <<< $1 }
    return stream
}

extension OutputStream {
    public final func writeDataToFile(_ filePath: String) {
        let dataInMemory = property(forKey: .dataWrittenToMemoryStreamKey)! as! NSData
        try! dataInMemory.write(to: URL(fileURLWithPath: filePath))
    }
}

extension InputStream {
    public func readString() -> String {
        var string = String()
        self >>> string
        return string
    }

    public func readBool() -> Bool {
        var bool = Bool()
        self >>> bool
        return bool
    }

    public func readInt() -> Int {
        var int = Int()
        self >>> int
        return int
    }

    public func readByte() -> UInt8 {
        var byte = UInt8()
        self >>> byte
        return byte
    }

    public func readDouble() -> Double {
        var double = Double()
        self >>> double
        return double
    }

    public func readVector2i() -> Vector2i {
        var vector = Vector2i(0, 0)
        vector.deserialize(from: self)
        return vector
    }
}

extension String: Serializable {
    public func serialize(to stream: OutputStream) {
        let count = utf8.count
        stream <<< count
        utf8CString.withUnsafeBufferPointer {
            $0.baseAddress!.withMemoryRebound(to: UInt8.self, capacity: count) {
                _ = stream.write($0, maxLength: count)
            }
        }
    }

    public mutating func deserialize(from stream: InputStream) {
        let utf8Count = stream.readInt()
        var a = ContiguousArray<UInt8>(repeating: 0, count: utf8Count)
        a.withUnsafeMutableBufferPointer {
            if stream.read($0.baseAddress!, maxLength: utf8Count) <= 0 { assertionFailure() }
            self = String(bytesNoCopy: $0.baseAddress!, length: utf8Count, encoding: .utf8, freeWhenDone: false)!
        }
    }
}

extension Bool: Serializable {
    public func serialize(to stream: OutputStream) {
        stream <<< UInt8(self ? 1 : 0)
    }

    public mutating func deserialize(from stream: InputStream) {
        var byte = UInt8()
        stream >>> byte
        assert(byte < 2)
        self = byte == 1
    }
}

extension Int: Serializable {
    public func serialize(to stream: OutputStream) {
        stream <<< Int64(self)
    }

    public mutating func deserialize(from stream: InputStream) {
        var decoded = Int64()
        stream >>> decoded
        self = Int(decoded)
    }
}

extension Int64: Serializable {
    public func serialize(to stream: OutputStream) {
        var encoded = self.littleEndian
        withUnsafePointer(to: &encoded) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int64>.size) {
                _ = stream.write($0, maxLength: MemoryLayout<Int64>.size)
            }
        }
    }

    public mutating func deserialize(from stream: InputStream) {
        withUnsafeMutablePointer(to: &self) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int64>.size) {
                _ = stream.read($0, maxLength: MemoryLayout<Int64>.size)
            }
        }
    }
}

extension Int32: Serializable {
    public func serialize(to stream: OutputStream) {
        var encoded = self.littleEndian
        withUnsafePointer(to: &encoded) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 1) {
                _ = stream.write(UnsafePointer($0), maxLength: MemoryLayout<Int32>.size)
            }
        }
    }

    public mutating func deserialize(from stream: InputStream) {
        var decoded = Int32()
        withUnsafeMutablePointer(to: &decoded) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Int32>.size) {
                _ = stream.read($0, maxLength: MemoryLayout<Int32>.size)
            }
        }
        self = Int32(littleEndian: decoded)
    }
}

extension UInt8: Serializable {
    public func serialize(to stream: OutputStream) {
        var copyOfSelf = self
        stream.write(&copyOfSelf, maxLength: MemoryLayout<UInt8>.size)
    }

    public mutating func deserialize(from stream: InputStream) {
        stream.read(&self, maxLength: MemoryLayout<UInt8>.size)
    }
}

extension Double: Serializable {
    public func serialize(to stream: OutputStream) {
        var encoded = Float64(self)
        withUnsafePointer(to: &encoded) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 1) {
                _ = stream.write(UnsafePointer($0), maxLength: MemoryLayout<Float64>.size)
            }
        }
    }

    public mutating func deserialize(from stream: InputStream) {
        withUnsafeMutablePointer(to: &self) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Float64>.size) {
                _ = stream.read($0, maxLength: MemoryLayout<Float64>.size)
            }
        }
    }
}

extension Float: Serializable {
    public func serialize(to stream: OutputStream) {
        var encoded = Float32(self)
        withUnsafePointer(to: &encoded) {
            $0.withMemoryRebound(to: UInt8.self, capacity: 1) {
                _ = stream.write(UnsafePointer($0), maxLength: MemoryLayout<Float32>.size)
            }
        }
    }

    public mutating func deserialize(from stream: InputStream) {
        withUnsafeMutablePointer(to: &self) {
            $0.withMemoryRebound(to: UInt8.self, capacity: MemoryLayout<Float64>.size) {
                _ = stream.read($0, maxLength: MemoryLayout<Float64>.size)
            }
        }
    }
}
