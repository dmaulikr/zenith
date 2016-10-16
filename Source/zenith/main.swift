import Toml
import Basic
import Graphics
import World
import UI

#if os(Linux)
    import Glibc
    srandom(UInt32(time(nil)))
#endif

let preferences = (try? Toml(contentsOfFile: Assets.preferencesPath)) ?? Toml()
let resolution = preferences.array("resolution") ?? [512, 384]
let scale = preferences.double("scale") ?? 2

app = Application(size: Vector2(resolution[0], resolution[1]), title: "Zenith")
app.window.scale = scale

Sprite.transparentColor = Color(r: 0x5a, g: 0x52, b: 0x68)

font = BitmapFont(fileName: Assets.graphicsPath + "font.bmp")

app.pushState(MainMenu(font: font))
app.run()
