class Builder {

    private static var cellarPlan = Dictionary<Vector2i, Rect<Int>>()

    static func spawnBuildings(to area: Area, withDensity density: Double) {
        while Double.random(0...1) < density {
            let position = Vector2(Int.random(0..<Area.size), Int.random(0..<Area.size))
            spawnBuilding(northWestCorner: area.tile(at: position))
        }
    }

    static func spawnBuilding(northWestCorner: Tile) {
        let buildingSize = Vector2(Int(Double.random(4...10)), Int(Double.random(4...10)))
        let result = tryToSpawnRoom(northWestCorner: northWestCorner, roomSize: buildingSize)
        if result == nil { return }
        let (allRoomTiles, nonCornerTiles, wallTiles) = result!

        // Spawn door
        nonCornerTiles.randomElement()!.structure = Structure(id: "door")

        // Spawn stairs to cellar
        if Float.random(0...1) < 0.3 {
            let stairwayTile = allRoomTiles.filter { tile in !wallTiles.contains { $0 === tile } }.randomElement()!
            stairwayTile.structure = Structure(id: "stairsDown")
            Builder.cellarPlan[stairwayTile.position] = Rect(position: northWestCorner.position,
                                                             size: buildingSize)
        }
    }

    static func generateCellars(to area: Area) {
        let stairwayTiles = area.tiles.filter { $0.structure?.id == "stairsUp" }
        for tile in stairwayTiles {
            guard let rect = cellarPlan.removeValue(forKey: tile.position) else {
                // FIXME: removeValue should not return nil here.
                continue
            }
            _ = tryToSpawnRoom(northWestCorner: area.tile(at: rect.topLeft), roomSize: rect.size)
        }
    }

    private static func tryToSpawnRoom(northWestCorner: Tile, roomSize: Vector2i)
        -> (allRoomTiles: [Tile], nonCornerTiles: [Tile], wallTiles: [Tile])? {
        let wallType = "brickWall"
        var allRoomTiles = Array<Tile>()
        var wallTiles = Array<Tile>()
        var nonCornerTiles = Array<Tile>()

        func isCorner(position: Vector2i) -> Bool {
            return (position.x == 0 || position.x == roomSize.x - 1)
                && (position.y == 0 || position.y == roomSize.y - 1)
        }

        func tryToCreateWall(at position: Vector2i) -> Bool {
            guard let targetTile = northWestCorner.adjacentTile(position) else {
                return false // Going outside the generated world
            }
            if [wallType, "stairsUp"].contains({ $0 == targetTile.structure?.id }) {
                return false
            }

            if !isCorner(position: position) {
                for tile in targetTile.adjacent4Tiles {
                    if tile?.structure?.id == wallType { return false }
                }
                nonCornerTiles.append(targetTile)
            }
            wallTiles.append(targetTile)
            return true
        }

        // North wall including corners
        for x in 0..<roomSize.x {
            if !tryToCreateWall(at: Vector2(x, 0)) {
                return nil
            }
        }
        // South wall including corners
        for x in 0..<roomSize.x {
            if !tryToCreateWall(at: Vector2(x, roomSize.y - 1)) {
                return nil
            }
        }
        // West wall excluding corners
        for y in 1..<roomSize.y {
            if !tryToCreateWall(at: Vector2(0, y)) {
                return nil
            }
        }
        // East wall excluding corners
        for y in 1..<roomSize.y {
            if !tryToCreateWall(at: Vector2(roomSize.x - 1, y)) {
                return nil
            }
        }

        // Create floor
        for x in 0..<roomSize.x {
            for y in 0..<roomSize.y {
                let targetTile = northWestCorner.adjacentTile(Vector2(x, y))!
                targetTile.groundId = "woodenFloor"
                if ["tree", "ground"].contains({ $0 == targetTile.structure?.id }) {
                    targetTile.structure = nil // Remove natural obstacles, like trees.
                }
                allRoomTiles.append(targetTile)
            }
        }

        // Spawn walls
        wallTiles.forEach { $0.structure = Structure(id: wallType) }
        return (allRoomTiles: allRoomTiles, nonCornerTiles: nonCornerTiles, wallTiles: wallTiles)
    }
}
