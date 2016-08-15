class Sidebar {

    private let gui: GraphicalUserInterface
    private let player: Creature

    init(gui: GraphicalUserInterface, player: Creature) {
        self.gui = gui
        self.player = player
    }

    func render(region: Rect<Int>) {
        var position = region.topLeft

        func drawStat(text: String, color: Color, currentValue: Int, maxValue: Int) {
            let label = Label(font: font, text: text + " \(currentValue)/\(maxValue)")
            label.position = position
            label.color = color
            label.render()
            position.y += lineHeight
        }

        drawStat(text: "HP", color: red,   currentValue: player.health, maxValue: player.maxHealth)
        drawStat(text: "AP", color: green, currentValue: player.energy, maxValue: player.maxEnergy)
        drawStat(text: "MP", color: blue,  currentValue: player.mana,   maxValue: player.maxMana)

        position.y += lineHeight

        func drawAttribute(text: String, value: Int) {
            let label = Label(font: font, text: text + " \(value)")
            label.position = position
            label.color = textColorHighlight
            label.render()
            position.y += lineHeight
        }

        drawAttribute(text: "Str", value: player.strength)
        drawAttribute(text: "Dex", value: player.dexterity)
        drawAttribute(text: "Agi", value: player.agility)
        drawAttribute(text: "End", value: player.endurance)
        drawAttribute(text: "Per", value: player.perception)
        drawAttribute(text: "Int", value: player.intelligence)
        drawAttribute(text: "Psy", value: player.psyche)
        drawAttribute(text: "Cha", value: player.charisma)
    }
}
