import Yaml

protocol Configurable {

    var config: Yaml { get }
}

class Configuration {

    static func load(name: String) -> Yaml {
        return try! Yaml.load(String(contentsOfFile: Assets.configPath + "\(name).yml")).value!
    }
}
