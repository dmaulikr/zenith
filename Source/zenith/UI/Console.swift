import CSDL2

struct Console: State {

    private var commandHistory: [String]
    private var commandLine: String
    private let gui: GameGUI

    init(gui: GameGUI) {
        commandHistory = ["lol", "xd", "wtf"]
        commandLine = ""
        self.gui = gui
    }

    mutating func update() {
        switch Int(app.waitForKeyPress()) {
            case SDLK_ESCAPE:
                fallthrough
            case SDLK_BACKQUOTE:
                app.popState()
            case SDLK_RETURN:
                runCommand(commandLine)
                commandLine = ""
            default:
                break
        }
    }

    private mutating func runCommand(_ command: String) {
        commandHistory.append(command)
    }

    func render() { //region: Rect<Int>
//        let rect = Rect(position: gui.worldViewRect.topLeft,
//                        size: Vector2(label.text.characters.count * font.glyphSize.x + 2 * spacing,
//                                      lineHeight + 2 * spacing))
//        drawFilledRectangle(rect, color: Color.black)

        var position = gui.worldViewRect.bottomLeft + Vector2(spacing, -spacing)
        let lines = 10

//        var position = region.bottomLeft
//        let lines = region.size.y / lineHeight
//        let padding = (region.size.y - lines * lineHeight) / 2
        position.y -= lineHeight
        var count = 0

        for line in commandHistory.reversed() {
            var label = Label(font: font, text: line)
            label.position = position
            label.color = textColor
            label.render()
            count += 1
            position.y -= lineHeight
            if count == lines { break }
        }
//        line.isNew ? textColorHighlight : 
    }

    var shouldRenderStateBelow: Bool {
        return true
    }
}
