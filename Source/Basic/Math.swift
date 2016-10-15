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
