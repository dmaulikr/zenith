import Foundation

public protocol Serializable {

    func serialize(to file: FileHandle)

    mutating func deserialize(from file: FileHandle)
}

public extension FileHandle {

    public func write<T: Serializable>(_ array: [T]) {
        write(array.count)
        for element in array {
            write(element)
        }
    }

    public func read<T: Serializable>(_ array: inout [T], elementInitializer: () -> T) {
        var count = 0
        read(&count)
        array = [T]()
        array.reserveCapacity(count)
        for _ in 0..<count {
            var element = elementInitializer()
            read(&element)
            array.append(element)
        }
    }

    public func write<T: Serializable>(_ serializable: T) {
        serializable.serialize(to: self)
    }

    public func write<T: Serializable>(_ optional: T?) {
        write(optional != nil)
        if let wrapped = optional {
            write(wrapped)
        }
    }

    public func write(polymorphicSerializable: Serializable) {
        write(String(describing: type(of: polymorphicSerializable)))
        polymorphicSerializable.serialize(to: self)
    }

    public func read<T: Serializable>(_ serializable: inout T) {
        serializable.deserialize(from: self)
    }

    public func read<T: Serializable>(elementInitializer: () -> T) -> [T] {
        var count = 0
        read(&count)
        var array = [T]()
        array.reserveCapacity(count)
        for _ in 0..<count {
            var element = elementInitializer()
            read(&element)
            array.append(element)
        }
        return array
    }

    public func read<T: Serializable>(_ optional: inout T?, elementInitializer: () -> T) {
        var notNil: Bool = false
        read(&notNil)
        if notNil {
            var wrappedValue = elementInitializer()
            read(&wrappedValue)
            optional = wrappedValue
        } else {
            optional = nil
        }
    }

    public func write<Key: Serializable, Value: Serializable>(_ dictionary: [Key: Value]) {
        write(dictionary.count)
        for (key, value) in dictionary {
            write(key)
            write(value)
        }
    }

    public func read<Key, Value>(_ dictionary: inout [Key: Value], keyInitializer: () -> Key, valueInitializer: () -> Value)
        where Key: Serializable, Value: Serializable {
        var count = 0
        read(&count)
        dictionary = [:]
        for _ in 0..<count {
            var key = keyInitializer()
            read(&key)
            var value = valueInitializer()
            read(&value)
            dictionary[key] = value
        }
    }
}

extension String: Serializable {

    public func serialize(to file: FileHandle) {
        file.write(utf8.count)
        file.write(data(using: .utf8)!)
    }

    public mutating func deserialize(from file: FileHandle) {
        var utf8Count: String.UTF8View.IndexDistance = 0
        file.read(&utf8Count)
        let data = file.readData(ofLength: utf8Count)
        self = String(data: data, encoding: .utf8)!
    }
}

extension Bool: Serializable {

    public func serialize(to file: FileHandle) {
        var byte = UInt8(self ? 1 : 0)
        file.write(Data(bytesNoCopy: &byte, count: 1, deallocator: .none))
    }

    public mutating func deserialize(from file: FileHandle) {
        let data = file.readData(ofLength: 1)
        assert(data[0] < 2)
        self = data[0] == 1
    }
}
