import CSDL2
import Foundation
import Basic
import Graphics

public class World {

    public var currentTime: Time
    var sunlight = Color(hue: 0, saturation: 0, lightness: 0)
    private var areas = [Vector3i: Area]()
    private let areaGenerationDistance = 1
    private let areaUpdateDistance = 1

    public init(startTime: Time) {
        currentTime = startTime
    }

    public func generate() {
        for x in -1...1 {
            for y in -1...1 {
                generateArea(position: Vector3(x, y, 0))
            }
        }

        updateAdjacentAreas()
    }

    var creatureUpdateStartIndex: Int = 0

    public func update(player: Creature) throws {
        generateAreas(player: player)

        var creaturesToUpdate = [Creature]()

        for dx in -areaUpdateDistance...areaUpdateDistance {
            for dy in -areaUpdateDistance...areaUpdateDistance {
                if let area = area(at: player.area.position + Vector3(dx, dy, 0)) {
                    creaturesToUpdate.append(contentsOf: area.creatures)
                }
            }
        }

        let range = creaturesToUpdate[creatureUpdateStartIndex..<creaturesToUpdate.endIndex]
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

    public func render(destination: Rect<Int>, player: Creature, seeEverything: Bool) {
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
                    if !player.canSee(tileToDraw) && !seeEverything { continue }
                    sdlRect.x = Int32(destination.left + (tileDrawDistance.x + relativeTileX) * tileSize)
                    sdlRect.y = Int32(destination.top  + (tileDrawDistance.y + relativeTileY) * tileSize)
                    targetViewport = sdlRect
                    tileToDraw.render(withLight: !seeEverything)
                }
            }
        }

        SDL_SetClipRect(targetSurface, &oldClipRect)
        targetViewport = viewport
    }

    public func area(at position: Vector3i) -> Area? {
        return areas[position] ?? tryToDeserializeArea(at: position)
    }

    private func generateAreas(player: Creature) {
        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                var position = player.area.position + Vector3(dx, dy, 0)
                if area(at: position) == nil { generateArea(position: position) }
                position.z = -1
                if area(at: position) == nil { generateArea(position: position) }
            }
        }
    }

    private func generateArea(position: Vector3i) {
        assert(area(at: position) == nil)
        areas[position] = Area(world: self, position: position)
        areas[position]!.generate()
    }

    public func saveAdjacentAreas(player: Creature, keepInMemory: Bool) {
        let playerAreaPosition = player.area.position

        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                saveAreaToFile(at: playerAreaPosition + Vector3(dx, dy, 0), keepInMemory: keepInMemory)
            }
        }
        saveAreaToFile(at: playerAreaPosition + Vector3(0, 0, -1), keepInMemory: keepInMemory)
        saveAreaToFile(at: playerAreaPosition + Vector3(0, 0,  1), keepInMemory: keepInMemory)
    }

    public func saveNonAdjacentAreas(player: Creature, keepInMemory: Bool) {
        for dx in -areaGenerationDistance - 1...areaGenerationDistance + 1 {
            for dy in -areaGenerationDistance - 1...areaGenerationDistance + 1 {
                if -areaGenerationDistance...areaGenerationDistance ~= dx { continue }
                if -areaGenerationDistance...areaGenerationDistance ~= dy { continue }
                saveAreaToFile(at: player.area.position + Vector3(dx, dy, 0), keepInMemory: keepInMemory)
            }
        }
        for dx in -areaGenerationDistance...areaGenerationDistance {
            for dy in -areaGenerationDistance...areaGenerationDistance {
                if dx == 0 || dy == 0 { continue }
                saveAreaToFile(at: player.area.position + Vector3(dx, dy, -1), keepInMemory: keepInMemory)
                saveAreaToFile(at: player.area.position + Vector3(dx, dy,  1), keepInMemory: keepInMemory)
            }
        }
    }

    /// Saves the area at the given position to disk and optionally removes it from memory.
    func saveAreaToFile(at position: Vector3i, keepInMemory: Bool) {
        if let area = areas[position] {
            let fileName = Area.saveFileName(forPosition: position)
            try? FileManager.default.createDirectory(atPath: Assets.savedGamePath,
                                                     withIntermediateDirectories: false)
            FileManager.default.createFile(atPath: Assets.savedGamePath + fileName, contents: nil)
            let fileStream = OutputStream(toFileAtPath: Assets.savedGamePath + fileName, append: false)!
            fileStream.open()
            area.serialize(to: fileStream)
            if !keepInMemory { areas[position] = nil }
        }
    }

    func tryToDeserializeArea(at position: Vector3i) -> Area? {
        let fileName = Area.saveFileName(forPosition: position)
        guard let fileStream = InputStream(fileAtPath: Assets.savedGamePath + fileName) else { return nil }
        fileStream.open()
        guard fileStream.hasBytesAvailable else { return nil }
        let area = Area(world: self, position: position)
        area.deserialize(from: fileStream)
        areas[position] = area
        return area
    }

    public func updateAdjacentAreas(relativeTo origin: Vector3i = Vector3(0, 0, 0)) {
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

public struct Time: CustomStringConvertible {

    public var hours: Int
    public var minutes: Int
    public var seconds: Int

    public init(hours: Int = 0, minutes: Int = 0, seconds: Int = 0) {
        self.hours = hours
        self.minutes = minutes
        self.seconds = seconds
    }

    public init(ticks: Int) {
        hours   = ticks * Time.secondsPerTick / 3600 % 24
        minutes = ticks * Time.secondsPerTick % 3600 / 60
        seconds = ticks * Time.secondsPerTick % 60
    }

    public var description: String {
        return String(format: "%02d:%02d", hours, minutes)
    }

    public var ticks: Int {
        return (hours * 60 * 60 + minutes * 60 + seconds) / Time.secondsPerTick
    }

    static var random: Time {
        return Time(ticks: Int.random(0..<Time.ticksPerDay)!)
    }

    static let ticksPerDay = 60 * 60 * 24 / Time.secondsPerTick
    static let secondsPerTick = 2
}
