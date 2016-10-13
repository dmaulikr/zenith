let textColor = Color(hue: 0.6, saturation: 0.1, lightness: 0.5)
let textColorHighlight = Color(hue: 0.1, saturation: 0.1, lightness: 0.8)

let darkGray = Color(hue: 0.6, saturation: 0.1, lightness: 0.2)
let red = Color(hue: 0.95, saturation: 0.9, lightness: 0.45)
let green = Color(hue: 0.3, saturation: 0.9, lightness: 0.4)
let blue = Color(hue: 0.65, saturation: 0.9, lightness: 0.65)

let tileSize = 20
let tileSizeVector = Vector2(tileSize, tileSize)
let tileRectangle = Rect(position: Vector2(0, 0), size: tileSizeVector)

let lineHeight = 10
let spacing = 10
let spacingVector = Vector2(spacing, spacing)

struct GameGUI {

    let sidebarRect: Rect<Int>
    let zoomViewRect: Rect<Int>
    let worldViewRect: Rect<Int>
    let messageViewRect: Rect<Int>

    init(resolution: Vector2i) {
        // Round sidebar width up to a multiple of tile size (for zoom view scaling).
        let sidebarWidth = (80 + tileSize - 1) / tileSize * tileSize
        let sidebarLeft = resolution.x - spacing - sidebarWidth
        let sidebarTop = spacing
        let zoomViewWidth = sidebarWidth
        let zoomViewHeight = zoomViewWidth
        let zoomViewLeft = sidebarLeft
        let zoomViewTop = resolution.y - spacing - zoomViewHeight
        let sidebarHeight = zoomViewTop - spacing - sidebarTop
        let worldViewLeft = 0
        let worldViewTop = 0
        let worldViewWidth = sidebarLeft - spacing
        let worldViewHeight = sidebarTop + sidebarHeight
        let messageViewLeft = spacing
        let messageViewTop = zoomViewTop
        let messageViewWidth = worldViewWidth - 2 * spacing
        let messageViewHeight = zoomViewHeight

        sidebarRect = Rect(position: Vector2(sidebarLeft, sidebarTop),
                           size: Vector2(sidebarWidth, sidebarHeight))
        zoomViewRect = Rect(position: Vector2(zoomViewLeft, zoomViewTop),
                            size: Vector2(zoomViewWidth, zoomViewHeight))
        worldViewRect = Rect(position: Vector2(worldViewLeft, worldViewTop),
                             size: Vector2(worldViewWidth, worldViewHeight))
        messageViewRect = Rect(position: Vector2(messageViewLeft, messageViewTop),
                               size: Vector2(messageViewWidth, messageViewHeight))
    }
}

struct Sidebar {

    private let gui: GameGUI
    private var player: Creature { return game.player }
    private unowned let game: Game

    init(gui: GameGUI, game: Game) {
        self.gui = gui
        self.game = game
    }

    func render(region: Rect<Int>) {
        var position = region.topLeft

        func drawStat(text: String, color: Color, currentValue: Int, maxValue: Int) {
            var label = Label(font: font, text: text + " \(currentValue)/\(maxValue)")
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
            var label = Label(font: font, text: text + " \(value)")
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

        font.renderText("Time \(game.world.currentTime)", at: position, color: textColorHighlight)
    }
}
