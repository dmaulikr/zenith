public extension FloatingPoint {

    public var radiansAsDegrees: Self {
        return self * 180 / .pi
    }

    public var degreesAsRadians: Self {
        return self * .pi / 180
    }
}

public extension SignedNumber {

    /// `1` if this number is positive, `-1` if this number is negative, else `0`.
    public var sign: Self {
        if self > 0 {
            return 1
        } else if self < 0 {
            return -1
        } else {
            return 0
        }
    }
}

public extension SignedInteger {

    func wrapped(to range: Range<Self>) -> Self {
        let distance = range.upperBound - range.lowerBound
        let temp = (self - range.lowerBound) % distance
        return (temp < Self(0) ? range.upperBound : range.lowerBound) + temp
    }

    mutating func wrap(to range: Range<Self>) {
        self = self.wrapped(to: range)
    }
}

public extension FloatingPoint {

    func wrapped(to range: Range<Self>) -> Self {
        let distance = range.upperBound - range.lowerBound
        let temp = (self - range.lowerBound).truncatingRemainder(dividingBy: distance)
        return (temp < Self(0) ? range.upperBound : range.lowerBound) + temp
    }

    mutating func wrap(to range: Range<Self>) {
        self = self.wrapped(to: range)
    }
}

public extension Comparable {

    func clamped(to range: ClosedRange<Self>) -> Self {
        return min(max(self, range.lowerBound), range.upperBound)
    }

    mutating func clamp(to range: ClosedRange<Self>) {
        self = self.clamped(to: range)
    }
}

/// - Returns: an array containing the positions of each tile that a line corresponding
/// to the given direction vector would intersect as determined by [Bresenham's line
/// algorithm](https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm).
public func raycastIntegerBresenham(direction delta: Vector2i) -> [Vector2i] {
    if let cachedResults = raycastIntegerBresenhamCache[delta] {
        return cachedResults
    }

    let absDelta = Vector2(abs(delta.x), abs(delta.y))
    let change1 = Vector2(delta.x.sign, delta.y.sign)
    let change2 = absDelta.x > absDelta.y ? Vector2(delta.x.sign, 0) : Vector2(0, delta.y.sign)
    let longest = absDelta.x > absDelta.y ? absDelta.x : absDelta.y
    let shortest = absDelta.x > absDelta.y ? absDelta.y : absDelta.x

    var numerator = longest / 2
    var current = Vector2(0, 0)
    var results = [Vector2i]()
    results.reserveCapacity(longest + 1)

    for _ in 0...longest {
        results.append(current)
        numerator += shortest
        if numerator >= longest {
            numerator -= longest
            current += change1
        } else {
            current += change2
        }
    }

    raycastIntegerBresenhamCache[delta] = results
    return results
}

private var raycastIntegerBresenhamCache = [Vector2i: [Vector2i]]()

public let neighborOffsets = [Vector2(0, -1), Vector2(0, 1), Vector2(-1, 0), Vector2(1, 0)]

/// Returns the tile positions making up any one of the shortest paths leading from
/// the source to the target tile position, using the A* pathfinding algorithm.
/// The algorithm will only traverse through tile for which `isAllowed` returns true.
/// If no suitable path is found, an empty array is returned.
public func findPathAStar(from source: Vector2i, to target: Vector2i, isAllowed: (Vector2i) -> Bool) -> [Vector2i] {
    // A* search algorithm implementation adapted from
    // https://en.wikipedia.org/w/index.php?title=A*_search_algorithm&oldid=734434637#Pseudocode

    // The set of nodes already evaluated.
    var closedSet = Set<Vector2i>()

    // For each node, which node it can most efficiently be reached from.
    // If a node can be reached from many nodes, cameFrom will eventually contain the
    // most efficient previous step.
    var cameFrom = [Vector2i: Vector2i]()

    // For each node, the cost of getting from the start node to that node.
    var gScore = [Vector2i: Int]() // default value = infinity

    // The cost of going from start to start is zero.
    gScore[source] = 0

    // For each node, the total cost of getting from the start node to the goal
    // by passing by that node. That value is partly known, partly heuristic.
    var fScore = [Vector2i: Int]() // default value = infinity

    // For the first node, that value is completely heuristic.
    fScore[source] = heuristicCostEstimate(source, target)

    // The set of currently discovered nodes still to be evaluated.
    // Initially, only the start node is known.
    var openSet = Heap<Vector2i>() { (fScore[$0] ?? Int.max) < (fScore[$1] ?? Int.max) }
    openSet.insert(source)

    while !openSet.isEmpty {
        // Find the node in openSet having the lowest fScore value.
        let current = openSet.remove()!

        if current == target {
            return reconstructPath(cameFrom, current)
        }

        closedSet.insert(current)

        for offset in neighborOffsets {
            let neighbor = current + offset

            if closedSet.contains(neighbor) { continue } // Ignore the neighbor which is already evaluated.
            if !isAllowed(neighbor) { continue }

            // The distance from start to a neighbor.
            let tentative_gScore = (gScore[current] ?? (Int.max - 1)) + 1 // - 1 to prevent overflow.

            if !openSet.contains(neighbor) { // Discover a new node.
                openSet.insert(neighbor)
            } else if tentative_gScore >= gScore[neighbor] ?? Int.max {
                continue // This is not a better path.
            }

            // This path is the best until now. Record it!
            cameFrom[neighbor] = current
            gScore[neighbor] = tentative_gScore

            fScore[neighbor] = (gScore[neighbor] ?? Int.max) + heuristicCostEstimate(neighbor, target)
        }
    }
    
    return []
}

/// Used by `findPathAStar` to collect all tile positions making up the path from `source` to `target`.
private func reconstructPath(_ cameFrom: [Vector2i: Vector2i], _ current: Vector2i) -> [Vector2i] {
    var current = current
    var totalPath = [current]

    while let newCurrent = cameFrom[current] {
        current = newCurrent
        totalPath.append(current)
    }

    return totalPath
}

/// Used by `findPathAStar` to estimate the relative path length between the given two positions.
private func heuristicCostEstimate(_ a: Vector2i, _ b: Vector2i) -> Int {
    let distance = Vector2(abs(a.x - b.x), abs(a.y - b.y))
    return distance.x * distance.y
}
