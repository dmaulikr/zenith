import CSDL2
import Basic
import Graphics
import World

class HelpView: State {

    private let gui: GameGUI
    private let commands: [(key: String, info: String)]
    private let debugCommands: [(key: String, info: String)]

    init(gui: GameGUI) {
        self.gui = gui

        commands = [
            (key: "a", info: "attack"),
            (key: "c", info: "close"),
            (key: "d", info: "drop"),
            (key: "e", info: "eat"),
            (key: "g", info: "go"),
            (key: "h", info: "help"),
            (key: "i", info: "inventory"),
            (key: "k", info: "kick"),
            (key: "r", info: "rest"),
            (key: "u", info: "use"),
            (key: ",", info: "pick up"),
            (key: ".", info: "wait"),
        ]

        #if !release
        debugCommands = [
            (key: "1", info: "spawn wall"),
            (key: "2", info: "spawn door"),
            (key: "3", info: "see everything"),
        ]
        #endif
    }

    func update() {
        switch Int(app.waitForKeyPress()) {
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

    private func renderCommands(commands: [(key: String, info: String)],
                                heading: String, position: Vector2i) {
        var label = Label(font: font, text: heading)
        label.color = textColorHighlight
        label.position = position
        label.render()
        label.color = textColor

        let yOffset = lineHeight * 2 + (tileSize - font.height) / 2
        var keyPosition = position + Vector2(0, yOffset)
        var infoPosition = keyPosition + Vector2(font.textWidth("   "), 0)

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
