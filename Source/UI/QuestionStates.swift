import CSDL2
import Basic
import Graphics
import World

class DirectionQuestion: State {

    private let gui: GameGUI
    private var label: Label
    private var result: Direction4?

    init(gui: GameGUI, title: String) {
        self.gui = gui
        label = Label(font: font, text: title)
        label.position = gui.worldViewRect.topLeft + spacingVector
    }

    func update() {
        switch Int(app.waitForKeyPress()) {
            case SDLK_UP:    result = .north
            case SDLK_RIGHT: result = .east
            case SDLK_DOWN:  result = .south
            case SDLK_LEFT:  result = .west
            case SDLK_ESCAPE: break
            default: return
        }
        app.popState()
    }

    func waitForResult() -> Direction4? {
        app.pushState(self)
        app.runTemporaryState()
        return result
    }

    func render() {
        let rect = Rect(position: gui.worldViewRect.topLeft,
                        size: Vector2(label.text.characters.count * font.glyphSize.x + 2 * spacing,
                                      lineHeight + 2 * spacing))
        drawFilledRectangle(rect, color: Color.black)
        label.render()
    }

    var shouldRenderStateBelow: Bool { return true }
}

class TimeQuestion: State {

    private let gui: GameGUI
    private var questionLabel: Label
    private var timeInputLabel: Label
    private var result: Time! {
        didSet {
            timeInputLabel.text = "\(result.hours) hours"
        }
    }
    private static var initialValue = Time(ticks: 0)

    init(gui: GameGUI, title: String) {
        self.gui = gui
        questionLabel = Label(font: font, text: title)
        questionLabel.position = gui.worldViewRect.topLeft + spacingVector
        result = TimeQuestion.initialValue
        timeInputLabel = Label(font: font, text: "\(result.hours) hours")
        timeInputLabel.position = gui.worldViewRect.topLeft + spacingVector
        timeInputLabel.position.x += (questionLabel.text.characters.count + 1) * font.glyphSize.x
    }

    func update() {
        switch Int(app.waitForKeyPress()) {
            case SDLK_UP:
                result.hours += 1
            case SDLK_DOWN:
                if result.hours > 0 {
                    result.hours -= 1
                }
            case SDLK_ESCAPE:
                TimeQuestion.initialValue = result
                app.popState()
                result = nil
            case SDLK_RETURN:
                TimeQuestion.initialValue = result
                app.popState()
            default:
                return
        }
    }

    func waitForResult() -> Time? {
        app.pushState(self)
        app.runTemporaryState()
        return result
    }

    func render() {
        let width = (questionLabel.text.characters.count + 1 + timeInputLabel.text.characters.count)
                    * font.glyphSize.x + 2 * spacing
        let rect = Rect(position: gui.worldViewRect.topLeft,
                        size: Vector2(width, lineHeight + 2 * spacing))
        drawFilledRectangle(rect, color: Color.black)
        questionLabel.render()
        timeInputLabel.render()
    }

    var shouldRenderStateBelow: Bool { return true }
}
