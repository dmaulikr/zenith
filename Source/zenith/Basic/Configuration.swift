import Toml

protocol Configurable {

    var config: Toml { get }
}

class Configuration {

    static func load(name: String) -> Toml {
        return try! Toml(contentsOfFile: Assets.configPath + "\(name).cfg")
    }
}
