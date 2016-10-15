import CSDL2

public struct Color: Equatable {

    public var red: UInt8
    public var green: UInt8
    public var blue: UInt8
    public var alpha: UInt8

    public init(r: UInt8, g: UInt8, b: UInt8, a: UInt8 = 255) {
        red = r
        green = g
        blue = b
        alpha = a
    }

    public init(hue: Double, saturation: Double, lightness: Double, alpha: Double = 1) {
        assert(0...1 ~= hue)
        assert(0...1 ~= saturation)
        assert(0...1 ~= lightness)
        assert(0...1 ~= alpha)

        let (r, g, b) = Color.hslAsRGB(hue, saturation, lightness)
        self.init(r: UInt8(r * 255), g: UInt8(g * 255), b: UInt8(b * 255), a: UInt8(alpha * 255))
    }

    public static let white = Color(r: 255, g: 255, b: 255)
    public static let black = Color(r: 0, g: 0, b: 0)

    public var hue: Double {
        get {
            let r = Double(red), g = Double(green), b = Double(blue)
            let minComponent = min(r, g, b), maxComponent = max(r, g, b)
            if maxComponent - minComponent == 0 { return 0 }

            var hue: Double
            switch maxComponent {
                case r:
                    hue = (g - b) / (maxComponent - minComponent)
                case g:
                    hue = (b - r) / (maxComponent - minComponent) + 2
                default:
                    hue = (r - g) / (maxComponent - minComponent) + 4
            }

            hue /= 6
            return hue < 0 ? hue + 1 : hue
        }
        set {
            let (r, g, b) = Color.hslAsRGB(newValue, saturation, lightness)
            red   = UInt8(r * 255)
            green = UInt8(g * 255)
            blue  = UInt8(b * 255)
        }
    }

    public var saturation: Double {
        get {
            let minComponent = min(Double(red)/255, Double(green)/255, Double(blue)/255)
            let maxComponent = max(Double(red)/255, Double(green)/255, Double(blue)/255)
            return (maxComponent - minComponent) / (1 - abs(2 * lightness - 1))
        }
        set {
            let (r, g, b) = Color.hslAsRGB(hue, newValue, lightness)
            red   = UInt8(r * 255)
            green = UInt8(g * 255)
            blue  = UInt8(b * 255)
        }
    }

    public var lightness: Double {
        get {
            let minComponent = min(Double(red)/255, Double(green)/255, Double(blue)/255)
            let maxComponent = max(Double(red)/255, Double(green)/255, Double(blue)/255)
            return (maxComponent + minComponent) / 2
        }
        set {
            let (r, g, b) = Color.hslAsRGB(hue, saturation, newValue)
            red   = UInt8(r * 255)
            green = UInt8(g * 255)
            blue  = UInt8(b * 255)
        }
    }

    public enum BlendMode {
        case alpha
        case additive
        case multiply
        case lighten
        case screen
    }

    public func blended(with color: Color, blendMode: BlendMode = .alpha) -> Color {
        let srcR = Double(color.red) / 255.0
        let srcG = Double(color.green) / 255.0
        let srcB = Double(color.blue) / 255.0
        let srcA = Double(color.alpha) / 255.0
        var dstR = Double(red) / 255.0
        var dstG = Double(green) / 255.0
        var dstB = Double(blue) / 255.0
        var dstA = Double(alpha) / 255.0

        switch blendMode {
            case .alpha:
                dstR = srcR * srcA + dstR * (1 - srcA)
                dstG = srcG * srcA + dstG * (1 - srcA)
                dstB = srcB * srcA + dstB * (1 - srcA)
                dstA =        srcA + dstA * (1 - srcA)
            case .additive:
                dstR = srcR * srcA + dstR
                dstG = srcG * srcA + dstG
                dstB = srcB * srcA + dstB
            case .multiply:
                dstR = srcR * dstR
                dstG = srcG * dstG
                dstB = srcB * dstB
            case .lighten:
                dstR = max(dstR, srcR)
                dstG = max(dstG, srcG)
                dstB = max(dstB, srcB)
            case .screen:
                dstR = 1 - (1 - dstR) * (1 - srcR)
                dstG = 1 - (1 - dstG) * (1 - srcG)
                dstB = 1 - (1 - dstB) * (1 - srcB)
        }

        return Color(r: UInt8(min(dstR, 1.0) * 255),
                     g: UInt8(min(dstG, 1.0) * 255),
                     b: UInt8(min(dstB, 1.0) * 255),
                     a: UInt8(min(dstA, 1.0) * 255))
    }

    public mutating func blend(with color: Color, blendMode: BlendMode = .alpha) {
        self = self.blended(with: color, blendMode: blendMode)
    }

    func asSDLColor() -> SDL_Color {
        return SDL_Color(r: red, g: green, b: blue, a: alpha)
    }

    private static func hslAsRGB(_ hue: Double, _ saturation: Double, _ lightness: Double)
    -> (r: Double, g: Double, b: Double) {
        // HSL to RGB conversion algorithm. Source:
        // https://en.wikipedia.org/w/index.php?title=HSL_and_HSV&oldid=694879918#From_HSL

        let c = (1 - abs(2 * lightness - 1)) * saturation
        let h = hue.truncatingRemainder(dividingBy: 1) * 6
        let x = c * (1 - abs(h.truncatingRemainder(dividingBy: 2) - 1))

        var r = 0.0, g = 0.0, b = 0.0

        switch h {
            case 0..<1: (r, g, b) = (c, x, 0)
            case 1..<2: (r, g, b) = (x, c, 0)
            case 2..<3: (r, g, b) = (0, c, x)
            case 3..<4: (r, g, b) = (0, x, c)
            case 4..<5: (r, g, b) = (x, 0, c)
            case 5..<6: (r, g, b) = (c, 0, x)
            default: assertionFailure("unreachable")
        }

        let m = lightness - c / 2
        return (r + m, g + m, b + m)
    }
}

public func ==(left: Color, right: Color) -> Bool {
    return left.red == right.red
        && left.green == right.green
        && left.blue == right.blue
        && left.alpha == right.alpha
}
