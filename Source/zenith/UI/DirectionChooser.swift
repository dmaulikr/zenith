import CSDL2

class DirectionChooser: State {

    private let gui: GraphicalUserInterface
    private let label: Label
    private let resultHandler: (Direction4?) -> Void
    private var result: Direction4?

    init(gui: GraphicalUserInterface, title: String, resultHandler: @escaping (Direction4?) -> Void) {
        self.gui = gui
        label = Label(font: font, text: title)
        label.position = gui.worldViewRect.topLeft + spacingVector
        self.resultHandler = resultHandler
    }

    override func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:    result = .north
            case SDLK_RIGHT: result = .east
            case SDLK_DOWN:  result = .south
            case SDLK_LEFT:  result = .west
            case SDLK_ESCAPE: break
            default: return
        }
        app.popState()
        resultHandler(result)
    }

    override func render() {
        let rect = Rect(position: gui.worldViewRect.topLeft,
                        size: Vector2(label.text.characters.count * font.glyphSize.x + 2 * spacing,
                                      lineHeight + 2 * spacing))
        drawRectangle(rect, color: Color.black, filled: true)
        label.render()
    }

    override var shouldRenderStateBelow: Bool { return true }
}
