import CSDL2

struct OptionalItemWrapper: CustomStringConvertible {
    let item: Item?
    var description: String {
        return item?.description ?? "nothing"
    }
}

class ItemMenu: Question<Item?>, State {

    private let items: Array<(Item, Int)>
    private let menu: Menu<OptionalItemWrapper>
    private let allowNothingAsOption: Bool

    init(gui: GraphicalUserInterface, title: String, items: Array<(Item, Int)>,
         allowNothingAsOption: Bool = false, resultHandler: @escaping (Item??) -> Void) {
        self.items = items

        var menuItems = items.map { OptionalItemWrapper(item: $0.0) }
        if allowNothingAsOption {
            menuItems.insert(OptionalItemWrapper(item: nil), at: 0)
        }
        menu = Menu(items: menuItems)

        self.allowNothingAsOption = allowNothingAsOption
        super.init(gui: gui, title: title, resultHandler: resultHandler)
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
        drawRectangle(gui.worldViewRect, color: Color.black, filled: true)

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
