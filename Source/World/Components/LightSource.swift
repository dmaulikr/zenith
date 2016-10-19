import Foundation
import Toml
import Graphics

struct LightSource: Component {
    let lightColor: Color
    let lightRange: Int

    init(type: String, config: Toml) {
        lightColor = config.color(type, "lightColor")!
        lightRange = config.int(type, "lightRange")!
    }

    func serialize(to stream: OutputStream) { }

    func deserialize(from stream: InputStream) { }
}
