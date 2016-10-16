import Basic
import Graphics

struct Menu<T: CustomStringConvertible> {

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
            var label = Label(font: font, text: item.description)
            label.color = index == selectionIndex ? selectionColor : labelColor
            label.position = Vector2(0, index * font.height)
            labels.append(label)
        }
    }

    mutating func selectNext() {
        if items.isEmpty { return }
        if selectionIndex == items.count - 1 { return }
        labels[selectionIndex].color = labelColor
        selectionIndex += 1
        labels[selectionIndex].color = selectionColor
    }

    mutating func selectPrevious() {
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
