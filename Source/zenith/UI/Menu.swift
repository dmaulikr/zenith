class Menu<T: CustomStringConvertible> {

    let items: Array<T>
    private var selectionIndex: Int
    private(set) var labels: Array<Label>
    private let labelColor: Color = textColor
    private let selectionColor: Color = textColorHighlight

    var selection: T {
        return items[selectionIndex]
    }

    init(items: Array<T>) {
        self.items = items
        selectionIndex = 0
        labels = Array()

        for (index, item) in items.enumerated() {
            let label = Label(font: font, text: item.description)
            label.color = index == selectionIndex ? selectionColor : labelColor
            label.position = Vector2(0, index * font.glyphSize.y)
            labels.append(label)
        }
    }

    func selectNext() {
        if selectionIndex == items.count - 1 { return }
        labels[selectionIndex].color = labelColor
        selectionIndex += 1
        labels[selectionIndex].color = selectionColor
    }

    func selectPrevious() {
        if selectionIndex == 0 { return }
        labels[selectionIndex].color = labelColor
        selectionIndex -= 1
        labels[selectionIndex].color = selectionColor
    }

    func render() {
        for l in labels { l.render() }
    }
}

/*
class SpriteMenu<T: CustomStringConvertible>: Menu<T> {

    private let sprites: Array<Sprite>

    override init(items: Array<T>) {
        sprites = Array()
        super.init(items: items)
        for (item, label) in zip(items, labels) {
            label.position.x += 16
            sprites.append(item.sprite)
        }
    }

    override func render() {
        for sprite in sprites { sprite.render() }
        super.render()
    }
}
*/
