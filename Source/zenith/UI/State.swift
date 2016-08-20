import CSDL2

public protocol State {

    /// Called when the state should be rendered. The default
    /// implementation does nothing.
    func render()

    /// Called when the state logic should be updated. The default
    /// implementation does nothing.
    func update()

    /// Called immediately when a key is pressed while the state is active.
    func keyWasPressed(key: SDL_Keycode)

    /// Called immediately when a key is released while the state is active.
    func keyWasReleased(key: SDL_Keycode)

    /// Determines whether the state below this state should be drawn before
    /// drawing this state. The default is `false`.
    var shouldRenderStateBelow: Bool { get }
}

// Provide empty default implementations.
public extension State {
    func render() {}
    func update() {}
    func keyWasPressed(key: SDL_Keycode) {}
    func keyWasReleased(key: SDL_Keycode) {}
    var shouldRenderStateBelow: Bool { return false }
}
