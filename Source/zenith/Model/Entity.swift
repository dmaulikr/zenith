import Foundation

/// A general-purpose base object that is made up of `Component`s. Components
/// can be added and modified at run-time, providing a flexible system
/// for defining behavior dynamically and enabling convenient code reuse.
class Entity: Serializable {

    private(set) var components: [Component]

    init() {
        components = []
    }

    /// Adds the given component to this entity.
    func addComponent(_ newComponent: Component) {
        components.append(newComponent)
    }

    /// - Returns: The first component successfully cast to the given type,
    ///   or `nil` if no such component was found.
    func getComponent<T: Component>() -> T! {
        for component in components {
            if let result = component as? T {
                return result
            }
        }
        return nil
    }

    /// Renders each component in this entity.
    func render() {
        for component in components { component.render() }
    }

    /// Updates each component in this entity.
    func update() throws {
        for component in components { component.update() }
    }

    func serialize(to file: FileHandle) {
        file.write(components.count)
        for element in components {
            file.write(String(describing: type(of: element)))
            file.write(polymorphicSerializable: element)
        }
    }

    func deserialize(from file: FileHandle) {
        var componentCount = 0
        file.read(&componentCount)
        components = []
        components.reserveCapacity(componentCount)
        for _ in 0..<componentCount {
            var componentClassName = ""
            file.read(&componentClassName)
            let _ = NSClassFromString(componentClassName)!
            // TODO...
        }
    }
}
