import Basic

public struct Label {

    /// The current position in the coordinate system. The default is `(0, 0)`.
    public var position: Vector2i = Vector2(0, 0)

    /// The font used to render this label's text.
    public let font: Font

    /// The text to show when rendering this label.
    public var text: String

    public var color: Color = Color.white

    public var alignment: Alignment = .left

    public init(font: Font, text: String = "") {
        self.font = font
        self.text = text
    }

    public func render() {
        font.renderText(text, at: position, color: color, align: alignment)
    }
}
