import CSDL2

class MainMenu: State {

    private let menu: Menu<MenuItem>
    private var game: Game?

    private enum MenuItem: String, CustomStringConvertible {
        case newGame = "New game"
        case preferences = "Preferences"
        case quit = "Quit"

        var description: String { return rawValue }
    }

    init(font: Font) {
        menu = Menu(items: [.newGame, .preferences, .quit])
    }

    func render() {
        var position = Vector2(app.window.resolution.x / 2, app.window.resolution.y / 3)
        let spacing = app.window.resolution.y / 3 / menu.items.count

        for item in menu.items {
            let color = item == menu.selection ? textColorHighlight : textColor
            let text = item == .newGame && game != nil ? "Continue game" : item.rawValue
            font.renderText(text, at: position, color: color, align: .center)
            position.y += spacing
        }
    }

    func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:
                menu.selectPrevious()
            case SDLK_DOWN:
                menu.selectNext()
            case SDLK_RETURN:
                switch menu.selection! {
                    case .newGame:
                        if game == nil {
                            game = Game()
                        }
                        app.pushState(game!)
                    case .preferences:
                        app.pushState(PreferencesMenu())
                    case .quit:
                        app.stop()
                }
            case SDLK_ESCAPE:
                app.stop()
            default:
                break
        }
    }
}
