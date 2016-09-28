import Toml

#if os(Linux)
    import Glibc
    srandom(UInt32(time(nil)))
#endif

struct Assets {
    static let assetsPath = #file.substring(to: #file.range(of: "/", options: .backwards)!.upperBound) + "../../../"
    static let configPath = assetsPath + "Config/"
    static let graphicsPath = assetsPath + "Graphics/"
    static let preferencesPath = assetsPath + "preferences.cfg"
}

let preferences = (try? Toml(contentsOfFile: Assets.preferencesPath)) ?? Toml()
let resolution = preferences.array("resolution") ?? [512, 384]
let scale = preferences.double("scale") ?? 2

let app = Application(size: Vector2(resolution[0], resolution[1]), title: "Zenith")
app.window.scale = scale

Sprite.transparentColor = Color(r: 0x5a, g: 0x52, b: 0x68)

let font = BitmapFont(fileName: Assets.graphicsPath + "font.bmp")

app.pushState(MainMenu(font: font))
app.run()
