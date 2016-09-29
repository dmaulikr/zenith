class Menu<T: CustomStringConvertible> {

    let items: [T]
    private var selectionIndex: Int
    private(set) var labels: [Label]
    private let labelColor: Color = textColor
    private let selectionColor: Color = textColorHighlight

    var selection: T? {
        return items.isEmpty ? nil : items[selectionIndex]
    }

    init(items: [T]) {
        self.items = items
        selectionIndex = 0
        labels = []

        for (index, item) in items.enumerated() {
            let label = Label(font: font, text: item.description)
            label.color = index == selectionIndex ? selectionColor : labelColor
            label.position = Vector2(0, index * font.glyphSize.y)
            labels.append(label)
        }
    }

    func selectNext() {
        if items.isEmpty { return }
        if selectionIndex == items.count - 1 { return }
        labels[selectionIndex].color = labelColor
        selectionIndex += 1
        labels[selectionIndex].color = selectionColor
    }

    func selectPrevious() {
        if items.isEmpty { return }
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

    private let sprites: [Sprite]

    override init(items: [T]) {
        sprites = []
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
