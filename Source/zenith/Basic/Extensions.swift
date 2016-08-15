extension Color {

    public func multipliedComponentwise(by factor: Double) -> Color {
        assert(0...1 ~= factor)
        var result = self
        result.red = UInt8(Double(result.red) * factor)
        result.green = UInt8(Double(result.green) * factor)
        result.blue = UInt8(Double(result.blue) * factor)
        result.alpha = UInt8(Double(result.alpha) * factor)
        return result
    }
}
