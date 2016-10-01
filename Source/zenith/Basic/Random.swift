import Foundation

public extension Int {

    /// - returns: a uniformly distributed pseudo-random `Int` in the given range.
    public static func random(_ range: Range<Int>) -> Int? {
        if range.isEmpty {
            return nil
        }
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
        #if os(Linux)
            return Double(Glibc.random()) / Double(RAND_MAX)
        #else
            return Double(arc4random()) / Double(UInt32.max)
        #endif
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
        #if os(Linux)
            return Float(Glibc.random()) / Float(RAND_MAX)
        #else
            return Float(arc4random()) / Float(UInt32.max)
        #endif
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
        if let index = Int.random(0..<count) {
            return self[index]
        }
        return nil
    }
}
