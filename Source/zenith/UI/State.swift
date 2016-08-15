import CSDL2

public class State {

    /// Called when the state should be rendered. The default
    /// implementation does nothing.
    public func render() {}

    /// Called when the state logic should be updated. The default
    /// implementation does nothing.
    public func update() {}

    /// Called immediately when a key is pressed while the state is active.
    public func keyWasPressed(key: SDL_Keycode) {}

    /// Called immediately when a key is released while the state is active.
    public func keyWasReleased(key: SDL_Keycode) {}

    /// Determines whether the state below this state should be drawn before
    /// drawing this state. The default is `false`.
    public var shouldRenderStateBelow: Bool { return false }
}
