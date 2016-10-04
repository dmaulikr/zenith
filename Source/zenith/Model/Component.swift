import Foundation

/// Represents one aspect of the `Entity` it is attached to, by specifying behavior
/// and/or graphical representation. Every `Component` is attached to an `Entity`.
public protocol Component: Serializable {

    /// Called when the component should render itself.
    func render()

    /// Called when the component should update its internal logic.
    func update()
}

// Provide empty default implementations.
public extension Component {

    func render() {}

    func update() {}
}
