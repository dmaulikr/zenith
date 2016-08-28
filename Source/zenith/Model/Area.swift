class Area {

    unowned let world: World
    let position: Vector3i
    private(set) var tiles: Array<Tile>
    var populationDensity: Double!

    static let size = 16
    static let sizeVector = Vector2(size, size)
    static let populationDensityRange = 0.1...0.99

    init(world: World, position: Vector3i) {
        self.world = world
        self.position = position
        populationDensity = nil

        tiles = Array()
        for x in 0..<Area.size {
            for y in 0..<Area.size {
                tiles.append(Tile(area: self, position: Vector2(x, y)))
            }
        }

        populationDensity = calculatePopulationDensity()
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

    func render() {
        for tile in tiles { tile.render() }
    }

    func tile(at position: Vector2i) -> Tile {
        return tiles[index(position)]
    }

    func adjacentArea(direction: Vector2i) -> Area? {
        return world.area(at: position + Vector3(direction))
    }

    var adjacent4Areas: Array<Area?> {
        return Direction4.allDirections.map { adjacentArea(direction: $0.vector) }
    }

    var adjacent8Areas: Array<Area?> {
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
        return position.z >= 0 ? world.sunlight : Color.black
    }

    private func connectStairs() {
        if let areaAbove = areaAbove {
            for tile in areaAbove.tiles {
                if tile.structure?.id == "stairsDown" {
                    self.tile(at: tile.position).structure = Structure(id: "stairsUp")
                }
            }
        }
        if let areaBelow = areaBelow {
            for tile in areaBelow.tiles {
                if tile.structure?.id == "stairsUp" {
                    self.tile(at: tile.position).structure = Structure(id: "stairsDown")
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
        return position.y + position.x * Area.size
    }
}
