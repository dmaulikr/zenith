import CSDL2

class HelpView: State {

    private let gui: GraphicalUserInterface
    private let commands: Array<(key: String, info: String)>
    private let debugCommands: Array<(key: String, info: String)>

    init(gui: GraphicalUserInterface) {
        self.gui = gui

        commands = [
            (key: "c", info: "close"),
            (key: "d", info: "drop"),
            (key: "e", info: "eat"),
            (key: "g", info: "go"),
            (key: "h", info: "help"),
            (key: "i", info: "inventory"),
            (key: "k", info: "kick"),
            (key: "u", info: "use"),
            (key: ",", info: "pick up"),
            (key: ".", info: "wait"),
        ]

        #if !release
        debugCommands = [
            (key: "1", info: "spawn wall"),
            (key: "2", info: "spawn door"),
        ]
        #endif
    }

    func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_ESCAPE:
                app.popState()
            default:
                break
        }
    }

    func render() {
        drawFilledRectangle(gui.worldViewRect, color: Color.black)

        var position = gui.worldViewRect.topLeft + spacingVector
        renderCommands(commands: commands, heading: "Help", position: position)

        #if !release
        position.x = gui.worldViewRect.left + gui.worldViewRect.size.x / 2
        renderCommands(commands: debugCommands, heading: "Debug commands", position: position)
        #endif
    }

    private func renderCommands(commands: Array<(key: String, info: String)>,
                                heading: String, position: Vector2i) {
        let label = Label(font: font, text: heading)
        label.color = textColorHighlight
        label.position = position
        label.render()
        label.color = textColor

        let yOffset = lineHeight * 2 + (tileSize - font.glyphSize.y) / 2
        var keyPosition = position + Vector2(0, yOffset)
        var infoPosition = keyPosition + Vector2(font.glyphSize.x * 3, 0)

        for (key, info) in commands {
            label.text = key
            label.position = keyPosition
            label.render()

            label.text = info
            label.position = infoPosition
            label.render()

            keyPosition.y += tileSize
            infoPosition.y += tileSize
        }
    }

    var shouldRenderStateBelow: Bool { return true }
}
