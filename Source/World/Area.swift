import Foundation
import Basic
import Graphics

public class Area: Serializable {

    unowned let world: World
    public let position: Vector3i
    private(set) var tiles: [Tile]
    private(set) var creatures: [Creature]
    var populationDensity: Double!

    public static let size = 16
    public static let sizeVector = Vector2(size, size)
    static let populationDensityRange = 0.1...0.99

    init(world: World, position: Vector3i) {
        self.world = world
        self.position = position
        tiles = []
        tiles.reserveCapacity(Area.size * Area.size)
        creatures = []
    }

    func generate() {
        populationDensity = calculatePopulationDensity()

        for x in 0..<Area.size {
            for y in 0..<Area.size {
                tiles.append(Tile(area: self, position: Vector2(x, y)))
                tiles.last!.generate()
            }
        }

        if position.z == 0 {
            Builder.spawnBuildings(to: self, withDensity: populationDensity)
        }
        connectStairs()
        if position.z < 0 {
            Builder.generateCellars(to: self)
        }
    }

    func update() {
        for tile in tiles { tile.update() }
    }

    public func tile(at position: Vector2i) -> Tile {
        return tiles[index(position)]
    }

    func adjacentArea(direction: Vector2i) -> Area? {
        return world.area(at: position + Vector3(direction))
    }

    var adjacent4Areas: [Area?] {
        return Direction4.allDirections.map { adjacentArea(direction: $0.vector) }
    }

    var adjacent8Areas: [Area?] {
        return Direction8.allDirections.map { adjacentArea(direction: $0.vector) }
    }

    var areaBelow: Area? {
        return world.area(at: position + Vector3(0, 0, -1))
    }

    var areaAbove: Area? {
        return world.area(at: position + Vector3(0, 0, 1))
    }

    var randomTile: Tile {
        return tiles.randomElement()!
    }

    var globalLight: Color {
        return position.z >= 0 ? world.sunlight : Color(hue: 0.125, saturation: 0, lightness: 0.2)
    }

    func registerCreature(_ creature: Creature) {
        assert(!creatures.contains { $0 === creature })
        creatures.append(creature)
    }

    func unregisterCreature(_ creature: Creature) {
        creatures.remove(at: creatures.index { $0 === creature }!)
    }

    private func connectStairs() {
        if let areaAbove = areaAbove {
            for tile in areaAbove.tiles {
                if tile.structure?.type == "stairsDown" {
                    self.tile(at: tile.position).structure = Structure(type: "stairsUp")
                }
            }
        }
        if let areaBelow = areaBelow {
            for tile in areaBelow.tiles {
                if tile.structure?.type == "stairsUp" {
                    self.tile(at: tile.position).structure = Structure(type: "stairsDown")
                }
            }
        }
    }

    private func calculatePopulationDensity() -> Double {
        let neighborAreas = adjacent4Areas.filter{ $0 != nil }
        if neighborAreas.isEmpty {
            return Double.random(Area.populationDensityRange)
        } else {
            let populationDensities = neighborAreas.map { $0!.populationDensity! }
            let sum = populationDensities.reduce(0) { $0 + $1 }
            let average = sum / Double(neighborAreas.count)
            return (average + Double.random(-0.5...0.5)).clamped(to: Area.populationDensityRange)
        }
    }

    private func index(_ position: Vector2i) -> Int {
        assert(position.x >= 0 && position.x < Area.size)
        assert(position.y >= 0 && position.y < Area.size)
        return position.y + position.x * Area.size
    }

    public func serialize(to file: FileHandle) {
        for tile in tiles {
            file.write(tile)
        }
        file.write(populationDensity!)
    }

    public func deserialize(from file: FileHandle) {
        assert(tiles.isEmpty)

        for x in 0..<Area.size {
            for y in 0..<Area.size {
                var tile = Tile(area: self, position: Vector2(x, y))
                file.read(&tile)
                tiles.append(tile)
            }
        }
        var populationDensity = 0.0
        file.read(&populationDensity)
        self.populationDensity = populationDensity
    }

    static func saveFileName(forPosition position: Vector3i) -> String {
        return "area.\(position.x).\(position.y).\(position.z).dat"
    }
}
