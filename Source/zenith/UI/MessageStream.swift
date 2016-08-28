class MessageStream: TextOutputStream {

    private var messages = Array<Message>()
    private unowned let world: World

    init(world: World) {
        self.world = world
    }

    func render(region: Rect<Int>) {
        var position = region.bottomLeft
        let lines = region.size.y / lineHeight
        let padding = (region.size.y - lines * lineHeight) / 2
        position.y -= padding + lineHeight
        var count = 0

        for message in messages.reversed() {
            let line = "- \(message.text)\(message.countString)"
            let label = Label(font: font, text: line)
            label.position = position
            label.color = message.isNew ? textColorHighlight : textColor
            label.render()
            count += 1
            position.y -= lineHeight
            if count == lines { break }
        }
    }

    func write(_ message: String) {
        if messages.last?.tick == world.tick {
            messages.last!.text += " \(message)"
        } else if messages.last?.text == message {
            messages.last!.addRepetition()
        } else {
            messages.append(Message(text: message, tick: world.tick))
        }
    }

    func makeMessagesOld() {
        for message in messages.reversed() {
            if !message.isNew { break }
            message.makeOld()
        }
    }
}

private class Message {

    var text: String
    private(set) var isNew: Bool
    var repetitionCount: Int
    let tick: Int

    init(text: String, tick: Int) {
        self.text = text
        isNew = true
        repetitionCount = 1
        self.tick = tick
    }

    func makeOld() {
        isNew = false
    }

    var countString: String {
        return repetitionCount > 1 ? " (x\(repetitionCount))" : ""
    }

    func addRepetition() {
        repetitionCount += 1
        isNew = true
    }
}
