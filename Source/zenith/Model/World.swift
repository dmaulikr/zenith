import CSDL2

class World {

    private var areas: Dictionary<Vector3i, Area>
    var player: Creature!
    private let areaGenerationDistance = 1
    private let areaUpdateDistance = 1
    private let areaDrawDistance = 1
    private let lineOfSightUpdateDistance: Vector2i

    init(worldViewSize: Vector2i) {
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

    func update() {
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
                    tile.lightColor = Color.black
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

        for dx in -lineOfSightUpdateDistance.x...lineOfSightUpdateDistance.x {
            for dy in -lineOfSightUpdateDistance.y...lineOfSightUpdateDistance.y {
                let vector = Vector2(dx, dy)
                player.tileUnder.adjacentTile(vector)?.updateFogOfWar(lineOfSight: vector)
            }
        }
    }

    func render(destination: Rect<Int>) {
        var viewport = SDL_Rect()
        SDL_RenderGetViewport(renderer, &viewport)
        var clipRect = SDL_Rect()
        SDL_RenderGetClipRect(renderer, &clipRect)

        var sdlRect = destination.asSDLRect()
        SDL_RenderSetClipRect(renderer, &sdlRect)

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
                SDL_RenderSetViewport(renderer, &sdlRect)
                area.render()
            }
        }

        if SDL_RectEmpty(&clipRect) == SDL_TRUE {
            SDL_RenderSetClipRect(renderer, nil)
        } else {
            SDL_RenderSetClipRect(renderer, &clipRect)
        }
        SDL_RenderSetViewport(renderer, &viewport)
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
