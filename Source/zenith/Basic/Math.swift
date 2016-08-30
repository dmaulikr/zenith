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

/// - Returns: an array containing the positions of each tile that a line from
/// `startPoint` to `endPoint` would intersect as determined by [Bresenham's line
/// algorithm](https://en.wikipedia.org/wiki/Bresenham%27s_line_algorithm).
public func raycastIntegerBresenham(from startPoint: Vector2i, to endPoint: Vector2i) -> Array<Vector2i> {
    let delta = endPoint - startPoint
    let absDelta = Vector2(abs(delta.x), abs(delta.y))
    let change1 = Vector2(delta.x.sign, delta.y.sign)
    let change2 = absDelta.x > absDelta.y ? Vector2(delta.x.sign, 0) : Vector2(0, delta.y.sign)
    let longest = absDelta.x > absDelta.y ? absDelta.x : absDelta.y
    let shortest = absDelta.x > absDelta.y ? absDelta.y : absDelta.x

    var numerator = longest / 2
    var current = startPoint
    var results = Array<Vector2i>()
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

    return results
}
