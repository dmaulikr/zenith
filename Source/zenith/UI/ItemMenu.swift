import CSDL2

struct OptionalItemWrapper: CustomStringConvertible {
    let item: Item?
    var description: String {
        return item?.description ?? "nothing"
    }
}

class ItemMenu: State {

    private let items: [(item: Item, amount: Int)]
    private let menu: Menu<OptionalItemWrapper>
    private let allowNothingAsOption: Bool
    private let gui: GameGUI
    private let title: String
    private let resultHandler: (Item??) -> Void

    init(gui: GameGUI, title: String, items: [(item: Item, amount: Int)],
         allowNothingAsOption: Bool = false, resultHandler: @escaping (Item??) -> Void) {
        self.items = items

        var menuItems = items.map { OptionalItemWrapper(item: $0.0) }
        if allowNothingAsOption {
            menuItems.insert(OptionalItemWrapper(item: nil), at: 0)
        }
        menu = Menu(items: menuItems)

        self.allowNothingAsOption = allowNothingAsOption
        self.gui = gui
        self.title = title
        self.resultHandler = resultHandler
    }

    func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:
                menu.selectPrevious()
            case SDLK_DOWN:
                menu.selectNext()
            case SDLK_ESCAPE:
                resultHandler(nil)
            case SDLK_RETURN:
                resultHandler(menu.selection?.item)
            default:
                break
        }
    }

    func render() {
        drawFilledRectangle(gui.worldViewRect, color: Color.black)

        var position = gui.worldViewRect.topLeft + spacingVector
        font.renderText(title, at: position, color: textColor)
        position.y += lineHeight * 2

        var spritePosition = position
        var textPosition = position
        textPosition += Vector2(tileSize + spacing, (tileSize - font.glyphSize.y) / 2)

        if allowNothingAsOption {
            let color = menu.selection!.item == nil ? textColorHighlight : textColor
            font.renderText("nothing", at: textPosition, color: color)
            spritePosition.y += tileSize
            textPosition.y += tileSize
        }

        for (item, amount) in items {
            item.sprite.render(at: spritePosition)
            let line = (amount > 1 ? "\(amount)x " : "") + item.name()
            let color = menu.selection!.item === item ? textColorHighlight : textColor
            font.renderText(line, at: textPosition, color: color)
            spritePosition.y += tileSize
            textPosition.y += tileSize
        }
    }

    var shouldRenderStateBelow: Bool { return true }
}
