import Basic

class BuildingMetadata {
    public internal(set) var allRoomTiles = [Tile]()
    public internal(set) var nonCornerTiles = [Tile]()
    public internal(set) var wallTiles = [Tile]()
    public internal(set) var doorTiles = [Tile]()
}

class Builder {

    private static var cellarPlan = [Vector2i: Rect<Int>]()

    static func spawnBuildings(to area: Area, withDensity density: Double) {
        while Double.random(0...1) < density {
            let position = Vector2(Int.random(0..<Area.size)!, Int.random(0..<Area.size)!)
            spawnBuilding(northWestCorner: area.tile(at: position))
        }
    }

    static func spawnBuilding(northWestCorner: Tile) {
        let buildingSize = Vector2(Int(Double.random(4...10)), Int(Double.random(4...10)))
        guard let metadata = tryToSpawnRoom(northWestCorner: northWestCorner, roomSize: buildingSize) else { return }

        // Spawn door
        metadata.nonCornerTiles.randomElement!.structure = Structure(type: "door")

        // Spawn stairs to cellar
        if Float.random(0...1) < 0.3 {
            let floorTiles = metadata.allRoomTiles.filter { tile in !metadata.wallTiles.contains { $0 === tile } }
            let stairwayTile = floorTiles.randomElement!
            stairwayTile.structure = Structure(type: "stairsDown")
            Builder.cellarPlan[stairwayTile.position] = Rect(position: northWestCorner.position,
                                                             size: buildingSize)
        }
    }

    static func generateCellars(to area: Area) {
        let stairwayTiles = area.tiles.filter { $0.structure?.type == "stairsUp" }
        for tile in stairwayTiles {
            guard let rect = cellarPlan.removeValue(forKey: tile.position) else {
                // FIXME: removeValue should not return nil here.
                continue
            }
            _ = tryToSpawnRoom(northWestCorner: area.tile(at: rect.topLeft), roomSize: rect.size)
        }

        for adjacentArea in area.adjacent8Areas {
            guard let adjacentArea = adjacentArea else { continue }
            generateTunnels(between: area, and: adjacentArea)
        }
    }

    private static func generateTunnels(between area1: Area, and area2: Area) {
        _ = generateRoadsBetween_loopHelper(area1) { sourceTile in
            generateRoadsBetween_loopHelper(area2) { targetTile in
                if sourceTile === targetTile { return false }

                let sourcePosition = sourceTile.globalPosition
                let targetPosition = targetTile.globalPosition

                let hasNoStructure = { (position: Vector2i) -> Bool in
                    guard let tile = sourceTile.adjacentTile(position - sourcePosition) else { return false }
                    return tile.structure == nil
                }

                let hasGround = { (position: Vector2i) -> Bool in
                    sourceTile.adjacentTile(position - sourcePosition)?.structure?.type == "ground"
                }

                if !findPathAStar(from: sourcePosition, to: targetPosition, isAllowed: hasNoStructure).isEmpty {
                    return false // A path already exists.
                }

                for roadPosition in findPathAStar(from: sourcePosition, to: targetPosition, isAllowed: hasGround) {
                    sourceTile.adjacentTile(roadPosition - sourcePosition)!.structure = nil
                }

                return true
            }
        }
    }

    /// Helper function for `generateRoadsBetween` (above) to avoid code duplication.
    private static func generateRoadsBetween_loopHelper(_ area: Area, innerLoop: (Tile) -> Bool) -> Bool {
        var didGenerate = false

        for buildingMetadata in area.buildingMetadata {
            let doorTileCandidate = buildingMetadata.nonCornerTiles.randomElement!

            for offset in neighborOffsets {
                guard let neighborTile = doorTileCandidate.adjacentTile(offset) else { continue }
                if neighborTile.structure?.type == "ground" {
                    if innerLoop(neighborTile) {
                        doorTileCandidate.structure = Structure(type: "door")
                        buildingMetadata.doorTiles.append(doorTileCandidate)
                        didGenerate = true
                    }
                    break
                }
            }
        }
        return didGenerate
    }

    private static func tryToSpawnRoom(northWestCorner: Tile, roomSize: Vector2i) -> BuildingMetadata? {
        let wallType = "brickWall"
        var metadata = BuildingMetadata()

        func isCorner(position: Vector2i) -> Bool {
            return (position.x == 0 || position.x == roomSize.x - 1)
                && (position.y == 0 || position.y == roomSize.y - 1)
        }

        func tryToCreateWall(at position: Vector2i) -> Bool {
            guard let targetTile = northWestCorner.adjacentTile(position) else {
                return false // Going outside the generated world
            }
            if let type = targetTile.structure?.type, [wallType, "stairsUp"].contains(type) {
                return false
            }

            if !isCorner(position: position) {
                for tile in targetTile.adjacent4Tiles {
                    if tile?.structure?.type == wallType { return false }
                }
                metadata.nonCornerTiles.append(targetTile)
            }
            metadata.wallTiles.append(targetTile)
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
                targetTile.groundType = "woodenFloor"
                if let type = targetTile.structure?.type, ["tree", "ground"].contains(type) {
                    targetTile.structure = nil // Remove natural obstacles, like trees.
                }
                metadata.allRoomTiles.append(targetTile)
            }
        }

        // Spawn walls
        metadata.wallTiles.forEach { $0.structure = Structure(type: wallType) }

        northWestCorner.area.registerBuilding(metadata)
        return metadata
    }
}
