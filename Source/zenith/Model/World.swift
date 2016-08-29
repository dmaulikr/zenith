import CSDL2

class World {

    private(set) var tick: Int
    private let startTime = Time.random
    var sunlight = Color(hue: 0, saturation: 0, lightness: 0)
    private var areas: Dictionary<Vector3i, Area>
    var player: Creature!
    private let areaGenerationDistance = 1
    private let areaUpdateDistance = 1
    private let areaDrawDistance = 1
    private let lineOfSightUpdateDistance: Vector2i

    init(worldViewSize: Vector2i) {
        tick = 0
        lineOfSightUpdateDistance = Vector2(Int(ceil(Double(worldViewSize.x) / 2)),
                                            Int(ceil(Double(worldViewSize.y) / 2)))
        areas = Dictionary()
        for x in -1...1 {
            for y in -1...1 {
                generateArea(position: Vector3(x, y, 0))
            }
        }
    }

    deinit {
        Creature.allCreatures.removeAll()
    }

    func update(playerIsResting: Bool = false) {
        tick += 1
        updateSunlight()
        generateAreas()

        // FIXME: Should only update creatures within areaUpdateDistance.
        for c in Creature.allCreatures { c.update() }

        // TODO: Remove the following duplication.
        for dx in -areaUpdateDistance...areaUpdateDistance {
            for dy in -areaUpdateDistance...areaUpdateDistance {
                guard let area = area(at: player.area.position + Vector3(dx, dy, 0)) else {
                    continue
                }
                for tile in area.tiles {
                    tile.lightColor = area.globalLight
                }
            }
        }
        for dx in -areaUpdateDistance...areaUpdateDistance {
            for dy in -areaUpdateDistance...areaUpdateDistance {
                area(at: player.area.position + Vector3(dx, dy, 0))?.update()
            }
        }
        player.area.areaBelow?.update()
        player.area.areaAbove?.update()

        if !playerIsResting {
            for dx in -lineOfSightUpdateDistance.x...lineOfSightUpdateDistance.x {
                for dy in -lineOfSightUpdateDistance.y...lineOfSightUpdateDistance.y {
                    let vector = Vector2(dx, dy)
                    player.tileUnder.adjacentTile(vector)?.updateFogOfWar(lineOfSight: vector)
                }
            }
        }
    }

    private func updateSunlight() {
        // Calculate the amount of light based on the time of day. This uses a sine wave.
        let frequency = 1.0 / Double(Time.ticksPerDay)
        let phase = Double.pi / 2 * 3
        let brightness = (sin(2 * Double.pi * frequency * Double(currentTime.ticks) + phase) + 1) / 2
        sunlight = Color(hue: 0.125, saturation: 0.1, lightness: brightness * 0.55)
    }

    func render(destination: Rect<Int>) {
        let viewport = targetViewport
        var oldClipRect = SDL_Rect()
        SDL_GetClipRect(targetSurface, &oldClipRect)
        var newClipRect = destination.asSDLRect()
        SDL_SetClipRect(targetSurface, &newClipRect)

        for dx in -areaDrawDistance...areaDrawDistance {
            for dy in -areaDrawDistance...areaDrawDistance {
                guard let area = area(at: player.area.position + Vector3(dx, dy, 0)) else { continue }
                let areaRelativePosition = Vector2(player.area.position - area.position) * Area.size
                let playerRelativePosition = areaRelativePosition + player.tileUnder.position
                let playerMiddlePixelPosition = playerRelativePosition * tileSize + tileSizeVector / 2
                var sdlRect = destination.asSDLRect()
                sdlRect.x -= playerMiddlePixelPosition.x - destination.size.x / 2
                sdlRect.y -= playerMiddlePixelPosition.y - destination.size.y / 2
                sdlRect.w = Int32(Area.size * tileSize)
                sdlRect.h = Int32(Area.size * tileSize)
                targetViewport = sdlRect
                area.render()
            }
        }

        SDL_SetClipRect(targetSurface, &oldClipRect)
        targetViewport = viewport
    }

    var currentTime: Time {
        return Time(ticks: startTime.ticks + tick)
    }

    func area(at position: Vector3i) -> Area? {
        return areas[position]
    }

    private func generateAreas() {
        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                var position = player.area.position + Vector3(dx, dy, 0)
                if areas[position] == nil { generateArea(position: position) }
                position.z = -1
                if areas[position] == nil { generateArea(position: position) }
            }
        }
    }

    private func generateArea(position: Vector3i) {
        areas[position] = Area(world: self, position: position)
    }
}

struct Time: CustomStringConvertible {

    var hours: Int
    var minutes: Int
    var seconds: Int

    init(ticks: Int) {
        hours   = ticks * Time.secondsPerTick / 3600 % 24
        minutes = ticks * Time.secondsPerTick % 3600 / 60
        seconds = ticks * Time.secondsPerTick % 60
    }

    var description: String {
        return String(format: "%02d:%02d", hours, minutes)
    }

    var ticks: Int {
        return (hours * 60 * 60 + minutes * 60 + seconds) / Time.secondsPerTick
    }

    static var random: Time {
        return Time(ticks: Int.random(0..<Time.ticksPerDay))
    }

    static let ticksPerDay = 60 * 60 * 24 / Time.secondsPerTick
    static let secondsPerTick = 2
}
