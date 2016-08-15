import CSDL2

class MainMenu: State {

    private let menu: Menu<MenuItem>

    private enum MenuItem: String, CustomStringConvertible {
        case newGame = "New game"
        case preferences = "Preferences"
        case quit = "Quit"

        var description: String { return rawValue }
    }

    init(font: Font) {
        menu = Menu(items: [.newGame, .preferences, .quit])

        // Position menu items
        var position = Vector2(app.window.size.x / 2, app.window.size.y / 3)
        let spacing = app.window.size.y / 3 / menu.items.count

        for label in menu.labels {
            label.alignment = .center
            label.position = position
            position.y += spacing
        }
    }

    override func render() {
        menu.render()
    }

    override func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:
                menu.selectPrevious()
            case SDLK_DOWN:
                menu.selectNext()
            case SDLK_RETURN:
                switch menu.selection {
                    case .newGame:     app.pushState(Game())
                    case .preferences: app.pushState(PreferencesMenu())
                    case .quit:        app.stop()
                }
            case SDLK_ESCAPE:
                app.stop()
            default:
                break
        }
    }
}
