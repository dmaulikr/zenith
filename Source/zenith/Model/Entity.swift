/// A general-purpose base object that is made up of `Component`s. Components
/// can be added and modified at run-time, providing a flexible system
/// for defining behavior dynamically and enabling convenient code reuse.
class Entity {

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
    func update() {
        for component in components { component.update() }
    }
}
