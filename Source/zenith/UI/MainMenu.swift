import CSDL2

class MainMenu: State {

    private var menu: Menu<MenuItem>
    private var game: Game?

    private enum MenuItem: String, CustomStringConvertible {
        case newGame = "New game"
        case preferences = "Preferences"
        case quit = "Quit"

        var description: String { return rawValue }
    }

    init(font: Font) {
        menu = Menu(items: [.newGame, .preferences, .quit])
        game = Game(mainMenu: self, loadSavedGame: true)
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

    func update() {
        switch Int(app.waitForKeyPress()) {
            case SDLK_UP:
                menu.selectPrevious()
            case SDLK_DOWN:
                menu.selectNext()
            case SDLK_RETURN:
                switch menu.selection! {
                    case .newGame:
                        if game == nil {
                            game = Game(mainMenu: self)
                        }
                        app.pushState(game!)
                    case .preferences:
                        app.pushState(PreferencesMenu())
                    case .quit:
                        saveAndQuit()
                }
            case SDLK_ESCAPE:
                saveAndQuit()
            default:
                break
        }
    }

    func saveAndQuit() {
        if let game = game {
            game.saveToFile()
        }
        app.stop()
    }

    func deleteGame() {
        game = nil
    }
}
