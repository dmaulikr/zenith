import CSDL2
import Foundation

class World {

    var currentTime: Time
    var sunlight = Color(hue: 0, saturation: 0, lightness: 0)
    private var areas = [Vector3i: Area]()
    private let areaGenerationDistance = 1
    private let areaUpdateDistance = 1

    init(startTime: Time) {
        currentTime = startTime
    }

    func generate() {
        for x in -1...1 {
            for y in -1...1 {
                generateArea(position: Vector3(x, y, 0))
            }
        }

        updateAdjacentAreas()
    }

    deinit {
        Creature.allCreatures.removeAll()
    }

    var creatureUpdateStartIndex: Int = 0

    func update(player: Creature) throws {
        generateAreas(player: player)

        // FIXME: Should only update creatures within areaUpdateDistance.
        let range = Creature.allCreatures[creatureUpdateStartIndex..<Creature.allCreatures.endIndex]
        for creature in range {
            try creature.update()
            creatureUpdateStartIndex += 1
        }
        creatureUpdateStartIndex = 0

        updateAdjacentAreas(relativeTo: player.area.position)

        currentTime = Time(ticks: currentTime.ticks + 1)
    }

    private func updateSunlight() {
        // Calculate the amount of light based on the time of day. This uses a sine wave.
        let frequency = 1.0 / Double(Time.ticksPerDay)
        let phase = Double.pi / 2 * 3
        let brightness = (sin(2 * Double.pi * frequency * Double(currentTime.ticks) + phase) + 1) / 2
        sunlight = Color(hue: 0.125, saturation: 0.1, lightness: 0.2 + brightness * 0.35)
    }

    func render(destination: Rect<Int>, player: Creature) {
        let viewport = targetViewport
        var oldClipRect = SDL_Rect()
        SDL_GetClipRect(targetSurface, &oldClipRect)
        var newClipRect = destination.asSDLRect()
        SDL_SetClipRect(targetSurface, &newClipRect)

        let tileDrawDistance = destination.size / tileSize / 2
        var sdlRect = SDL_Rect(x: 0, y: 0, w: Int32(tileSize), h: Int32(tileSize))

        for relativeTileX in -tileDrawDistance.x...tileDrawDistance.x {
            for relativeTileY in -tileDrawDistance.y...tileDrawDistance.y {
                if let tileToDraw = player.tileUnder.adjacentTile(Vector2(relativeTileX, relativeTileY)) {
                    if !player.canSee(tileToDraw) { continue }
                    sdlRect.x = Int32(destination.left + (tileDrawDistance.x + relativeTileX) * tileSize)
                    sdlRect.y = Int32(destination.top  + (tileDrawDistance.y + relativeTileY) * tileSize)
                    targetViewport = sdlRect
                    tileToDraw.render()
                }
            }
        }

        SDL_SetClipRect(targetSurface, &oldClipRect)
        targetViewport = viewport
    }

    func area(at position: Vector3i) -> Area? {
        return areas[position] ?? tryToDeserializeArea(at: position)
    }

    private func generateAreas(player: Creature) {
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
        areas[position]?.generate()
    }

    func saveUnsavedAreas(player: Creature) {
        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                saveArea(at: player.area.position + Vector3(dx, dy, 0))
            }
        }
        saveArea(at: player.area.position + Vector3(0, 0, -1))
        saveArea(at: player.area.position + Vector3(0, 0,  1))
    }

    func saveNonAdjacentAreas(player: Creature) {
        for dx in -areaGenerationDistance - 1...areaGenerationDistance + 1 {
            for dy in -areaGenerationDistance - 1...areaGenerationDistance + 1 {
                if -areaGenerationDistance...areaGenerationDistance ~= dx { continue }
                if -areaGenerationDistance...areaGenerationDistance ~= dy { continue }
                saveArea(at: player.area.position + Vector3(dx, dy, 0))
            }
        }
        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                if dx == 0 || dy == 0 { continue }
                saveArea(at: player.area.position + Vector3(dx, dy, -1))
                saveArea(at: player.area.position + Vector3(dx, dy,  1))
            }
        }
    }

    func saveArea(at position: Vector3i) {
        if let area = areas[position] {
            let fileName = Area.saveFileName(forPosition: position)
            try? FileManager.default.createDirectory(atPath: Assets.savedGamePath,
                                                     withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: Assets.savedGamePath + fileName, contents: nil)
            let file = FileHandle(forWritingAtPath: Assets.savedGamePath + fileName)!
            area.serialize(to: file)
        }
    }

    func deserializeAreas(from directory: String) {
        areas = [:]
        for fileName in try! FileManager.default.contentsOfDirectory(atPath: directory) {
            if fileName == "world.dat" { continue }
            let components = fileName.components(separatedBy: ".")
            assert(components[0] == "area" && components[4] == "dat")
            let position = Vector3(Int(components[1])!, Int(components[2])!, Int(components[3])!)
            _ = tryToDeserializeArea(at: position)!
        }
    }

    func tryToDeserializeArea(at position: Vector3i) -> Area? {
        let fileName = Area.saveFileName(forPosition: position)
        guard let file = FileHandle(forReadingAtPath: Assets.savedGamePath + fileName) else {
            return nil
        }
        var area = Area(world: self, position: position)
        file.read(&area)
        areas[position] = area
        return area
    }

    func updateAdjacentAreas(relativeTo origin: Vector3i = Vector3(0, 0, 0)) {
        updateSunlight()

        for dx in -areaUpdateDistance...areaUpdateDistance {
            for dy in -areaUpdateDistance...areaUpdateDistance {
                guard let area = area(at: origin + Vector3(dx, dy, 0)) else {
                    continue
                }
                for tile in area.tiles {
                    tile.lightColor = area.globalLight
                }
            }
        }
        for dx in -areaUpdateDistance...areaUpdateDistance {
            for dy in -areaUpdateDistance...areaUpdateDistance {
                area(at: origin + Vector3(dx, dy, 0))?.update()
            }
        }
        area(at: origin + Vector3(0, 0, -1))?.update()
        area(at: origin + Vector3(0, 0,  1))?.update()
    }
}

struct Time: CustomStringConvertible {

    var hours: Int
    var minutes: Int
    var seconds: Int

    init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

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
        return Time(ticks: Int.random(0..<Time.ticksPerDay)!)
    }

    static let ticksPerDay = 60 * 60 * 24 / Time.secondsPerTick
    static let secondsPerTick = 2
}
