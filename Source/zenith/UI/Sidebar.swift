class Sidebar {

    private let gui: GameGUI
    private let player: Creature
    private unowned let world: World

    init(gui: GameGUI, world: World) {
        self.gui = gui
        self.player = world.player
        self.world = world
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

        drawStat(text: "HP", color: red,
                 currentValue: Int(player.health.rounded(.up)),
                 maxValue: Int(player.maxHealth.rounded(.up)))
        drawStat(text: "AP", color: green,
                 currentValue: Int(player.energy.rounded(.up)),
                 maxValue: Int(player.maxEnergy.rounded(.up)))
        drawStat(text: "MP", color: blue,
                 currentValue: Int(player.mana.rounded(.up)),
                 maxValue: Int(player.maxMana.rounded(.up)))

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

        position.y += lineHeight

        font.renderText("Time \(world.currentTime)", at: position, color: textColorHighlight)
    }
}
