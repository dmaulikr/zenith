struct Assets {
    static let assetsPath = #file.substring(to: #file.range(of: "/", options: .backwards)!.upperBound) + "../../../"
    static let configPath = assetsPath + "Config/"
    static let graphicsPath = assetsPath + "Graphics/"
}

let app = Application(windowOptions: Window.Options(size: Vector2(512, 384), title: "Zenith"))

Sprite.transparentColor = Color(r: 0x5a, g: 0x52, b: 0x68)

let font = BitmapFont(fileName: Assets.graphicsPath + "font.bmp")

app.pushState(MainMenu(font: font))
app.run()
