import CSDL2

class PreferencesMenu: State {

    private let preferences: Dictionary<MenuItem, () -> String>
    private let resolutions: Array<Vector2i>
    private var currentResolutionIndex: Int
    private let menu: Menu<MenuItem>

    private enum MenuItem: String, CustomStringConvertible {
        case back = "Back"
        case resolution = "Resolution"
        case scale = "Scale"

        var description: String { return rawValue }
    }

    init() {
        preferences = [
            .resolution: { "\(app.window.size.x)x\(app.window.size.y)" },
            .scale: { "\(app.window.scale)x" },
        ]
        resolutions = [Vector2(512, 384), Vector2(640, 480),
                       Vector2(800, 600), Vector2(1024, 768)]
        currentResolutionIndex = 0
        menu = Menu(items: [.back, .resolution, .scale])
    }

    func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:   menu.selectPrevious()
            case SDLK_DOWN: menu.selectNext()
            case SDLK_RETURN:
                switch menu.selection {
                    case .back:
                        app.popState()
                    case .resolution:
                        currentResolutionIndex += 1
                        currentResolutionIndex %= resolutions.count
                        app.window.size = resolutions[currentResolutionIndex]
                    case .scale:
                        app.window.scale = app.window.scale % 2 + 1
                }
            case SDLK_ESCAPE:
                app.popState()
            default:
                break
        }
    }

    func render() {
        var left = app.window.size / 4
        var right = Vector2(app.window.size.x - left.x, left.y)
        let dy = Int(Double(lineHeight) * 1.5)

        for item in menu.items {
            let color = item == menu.selection ? textColorHighlight : textColor
            font.renderText(item.rawValue, at: left, color: color)

            if let text = preferences[item]?() {
                font.renderText(text, at: right, color: color, align: .right)
            }

            left.y += dy
            right.y += dy
        }
    }
}
