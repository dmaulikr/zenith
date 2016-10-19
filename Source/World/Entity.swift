import Foundation
import Toml
import Basic
import Graphics

/// A general-purpose base object that is made up of `Component`s. Components
/// can be added and modified at run-time, providing a flexible system
/// for defining behavior dynamically and enabling convenient code reuse.
public class Entity: Serializable {

    private(set) var components: [Component]
    private let config: Toml

    init(config: Toml) {
        components = []
        self.config = config
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

    /// Updates each component in this entity.
    func update() throws {
        for component in components { component.update() }
    }

    var emitsLight: Bool {
        let lightSourceComponent: LightSource? = getComponent()
        return lightSourceComponent != nil
    }

    var lightColor: Color {
        let lightSourceComponent: LightSource = getComponent()
        return lightSourceComponent.lightColor
    }

    var lightRange: Int {
        let lightSourceComponent: LightSource = getComponent()
        return lightSourceComponent.lightRange
    }

    public func serialize(to stream: OutputStream) {
        stream <<< components.count
        components.forEach {
            stream <<< String(describing: type(of: $0))
            $0.serialize(to: stream)
        }
    }

    public func deserialize(from stream: InputStream) {
        let componentCount = stream.readInt()
        components.removeAll(keepingCapacity: true)
        components.reserveCapacity(componentCount)
        for _ in 0..<componentCount {
            var component = (self as! Object).createComponent(stream.readString(), config: config)
            component.deserialize(from: stream)
            components.append(component)
        }
    }
}
