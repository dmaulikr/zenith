import Foundation

public extension Int {

    /// - returns: a uniformly distributed pseudo-random `Int` in the given range.
    public static func random(_ range: Range<Int>) -> Int {
        let distance = range.upperBound - range.lowerBound
        return range.lowerBound + Int(Double.random(0...1) * Double(distance))
    }

    /// - returns: a uniformly distributed pseudo-random `Int` in the given range.
    public static func random(_ range: ClosedRange<Int>) -> Int {
        let distance = range.upperBound - range.lowerBound + 1
        return range.lowerBound + Int(Double.random(0...1) * Double(distance))
    }
}

public extension Double {

    /// - returns: a uniformly distributed pseudo-random `Double` in the range `0...1`.
    private static var random: Double {
        return Double(arc4random()) / Double(UInt32.max)
    }

    /// - returns: a uniformly distributed pseudo-random `Double` in the given range.
    public static func random(_ range: ClosedRange<Double>) -> Double {
        let distance = range.upperBound - range.lowerBound
        return range.lowerBound + Double.random * distance
    }
}

public extension Float {

    /// - returns: a uniformly distributed pseudo-random `Float` in the range `0...1`.
    private static var random: Float {
        return Float(arc4random()) / Float(UInt32.max)
    }

    /// - returns: a uniformly distributed pseudo-random `Float` in the given range.
    public static func random(_ range: ClosedRange<Float>) -> Float {
        let distance = range.upperBound - range.lowerBound
        return range.lowerBound + Float.random * distance
    }
}

public extension Array {
    /// A randomly selected element from the array, or nil if the array is empty.
    public func randomElement() -> Element? {
        if isEmpty { return nil }
        return self[Int.random(0..<count)]
    }
}
