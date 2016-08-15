import CSDL2

class ItemMenu: Question<Item> {

    private let items: Array<(Item, Int)>
    private let menu: Menu<Item>

    init(gui: GraphicalUserInterface, title: String, items: Array<(Item, Int)>,
         resultHandler: (Item?) -> Void) {
        self.items = items
        menu = Menu(items: items.map { $0.0 })
        super.init(gui: gui, title: title, resultHandler: resultHandler)
    }

    override func keyWasPressed(key: SDL_Keycode) {
        switch Int(key) {
            case SDLK_UP:
                menu.selectPrevious()
            case SDLK_DOWN:
                menu.selectNext()
            case SDLK_ESCAPE:
                resultHandler(nil)
            case SDLK_RETURN:
                resultHandler(menu.selection)
            default:
                break
        }
    }

    override func render() {
        drawRectangle(gui.worldViewRect, color: Color.black, filled: true)

        var position = gui.worldViewRect.topLeft + spacingVector
        font.renderText(title, at: position, color: textColor)
        position.y += lineHeight * 2

        var spritePosition = position
        var textPosition = position
        textPosition += Vector2(tileSize + spacing, (tileSize - font.glyphSize.y) / 2)

        for (item, amount) in items {
            item.sprite.render(at: spritePosition)
            let line = (amount > 1 ? "\(amount)x " : "") + item.name()
            let color = menu.selection === item ? textColorHighlight : textColor
            font.renderText(line, at: textPosition, color: color)
            spritePosition.y += tileSize
            textPosition.y += tileSize
        }
    }

    override var shouldRenderStateBelow: Bool { return true }
}
