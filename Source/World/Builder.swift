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

        for adjacentArea in area.adjacent8Areas.flatMap({ $0 }) {
            generateTunnels(between: area, and: adjacentArea)
        }
        generateTunnels(between: area, and: area)
    }

    private static func generateTunnels(between area1: Area, and area2: Area) {
        _ = generateRoadsBetween_loopHelper(area1) { sourceBuilding in
            generateRoadsBetween_loopHelper(area2) { targetBuilding in
                if sourceBuilding === targetBuilding { return false }
//
//                guard let sourceTileTemp
//                    = sourceBuilding.nonCornerTiles.randomElement!.adjacent4Tiles.first(where: { $0?.structure?.type == "ground" }) else { return false }
//                guard let targetTileTemp
//                    = targetBuilding.nonCornerTiles.randomElement!.adjacent4Tiles.first(where: { $0?.structure?.type == "ground" }) else { return false }
//                guard let sourceTile = sourceTileTemp else { return false }
//                guard let targetTile = targetTileTemp else { return false }

                let sourceTile = sourceBuilding.nonCornerTiles.randomElement!
                let targetTile = targetBuilding.nonCornerTiles.randomElement!

                let sourceTileStructureBackup = sourceTile.structure
                let targetTileStructureBackup = targetTile.structure
                sourceTile.structure = nil
                targetTile.structure = nil
                defer {
                    if sourceTile.structure?.type != "door" { sourceTile.structure = sourceTileStructureBackup }
                    if targetTile.structure?.type != "door" { targetTile.structure = targetTileStructureBackup }
                }

                let sourcePosition = sourceTile.globalPosition
                let targetPosition = targetTile.globalPosition

                func hasNoStructure(position: Vector2i) -> Bool {
                    guard let tile = sourceTile.adjacentTile(position - sourcePosition) else { return false }
                    return tile.structure == nil
                }

                func hasGroundOrNoStructure(position: Vector2i) -> Bool {
                    guard let tile = sourceTile.adjacentTile(position - sourcePosition) else { return false }
                    if let structure = tile.structure { return structure.type == "ground" }
                    return true
                }

                func cost(from: Vector2i, to: Vector2i) -> Int {
                    guard let tile = sourceTile.adjacentTile(to - sourcePosition) else { return Int.max }
                    return tile.structure != nil ? 1 : 0
//                    return 0
                }

                if findPathAStar(from: sourcePosition, to: targetPosition,
                                 isAllowed: hasNoStructure, cost: cost) != nil {
                    return false // A path already exists.
                }

                guard let path = findPathAStar(from: sourcePosition, to: targetPosition,
                                               isAllowed: hasGroundOrNoStructure, cost: cost) else {
//                    fatalError()
                    return false
                }

                for roadPosition in path {
                    sourceTile.adjacentTile(roadPosition - sourcePosition)?.structure = nil
                }

                sourceTile.structure = Structure(type: "door")
                targetTile.structure = Structure(type: "door")
                return true
            }
        }
    }

    /// Helper function for `generateRoadsBetween` (above) to avoid code duplication.
    private static func generateRoadsBetween_loopHelper(_ area: Area, innerLoop: (BuildingMetadata) -> Bool) -> Bool {
        var didGenerate = false
        for buildingMetadata in area.buildingMetadata {
            if innerLoop(buildingMetadata) { didGenerate = true }
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
