import CSDL2
import Toml

class PreferencesMenu: State {

    private let preferences: [MenuItem: () -> String]
    private let resolutions: [Vector2i]
    private var currentResolutionIndex: Int
    private let scales: [Double]
    private var currentScaleIndex: Int
    private let menu: Menu<MenuItem>
    private let toml: Toml

    private enum MenuItem: String, CustomStringConvertible {
        case back = "Back"
        case resolution = "Resolution"
        case scale = "Scale"

        var description: String { return rawValue }
    }

    init() {
        toml = (try? Toml(contentsOfFile: Assets.preferencesPath)) ?? Toml()

        preferences = [
            .resolution: { "\(app.window.resolution.x)x\(app.window.resolution.y)" },
            .scale: { "\(app.window.scale)x" },
        ]
        resolutions = [Vector2(512, 384), Vector2(640, 480),
                       Vector2(800, 600), Vector2(1024, 768)]
        if let resolutionPreference: [Int] = toml.array("resolution") {
            let resolutionPreferenceVector = Vector2(resolutionPreference[0], resolutionPreference[1])
            currentResolutionIndex = resolutions.index(of: resolutionPreferenceVector) ?? 0
        } else {
            currentResolutionIndex = 0
        }

        scales = app.window.isHighDPI ? [1, 1.5, 2] : [1, 2]
        let defaultScaleIndex = scales.index(of: 2)!
        let scalePreference = toml.double("scale")
        currentScaleIndex = scales.index(of: scalePreference ?? 2) ?? defaultScaleIndex

        menu = Menu(items: [.back, .resolution, .scale])
    }

    func update() {
        switch Int(app.waitForKeyPress()) {
            case SDLK_UP:   menu.selectPrevious()
            case SDLK_DOWN: menu.selectNext()
            case SDLK_RETURN:
                switch menu.selection! {
                    case .back:
                        app.popState()
                    case .resolution:
                        currentResolutionIndex += 1
                        currentResolutionIndex %= resolutions.count
                        app.window.resolution = resolutions[currentResolutionIndex]
                    case .scale:
                        currentScaleIndex += 1
                        currentScaleIndex %= scales.count
                        app.window.scale = scales[currentScaleIndex]
                }
                try? savePreferencesToFile()
            case SDLK_ESCAPE:
                app.popState()
            default:
                break
        }
    }

    func render() {
        var left = app.window.resolution / 4
        var right = Vector2(app.window.resolution.x - left.x, left.y)
        let dy = Int(Double(lineHeight) * 1.5)

        for item in menu.items {
            let color = item == menu.selection ? textColorHighlight : textColor
            font.renderText(item.rawValue, at: left, color: color)

            if let text = preferences[item]?() {
                font.renderText(text, at: right, color: color, align: .right)
            }

            left.y += dy
            right.y += dy
        }
    }

    private func savePreferencesToFile() throws {
        let resolution = resolutions[currentResolutionIndex]
        toml.setValue(key: ["resolution"], value: [resolution.x, resolution.y])
        toml.setValue(key: ["scale"], value: scales[currentScaleIndex])
        try toml.description.write(toFile: Assets.preferencesPath, atomically: true, encoding: .utf8)
    }
}
