import PackageDescription

let package = Package(
    name: "zenith",
    targets: [
        Target(name: "Basic", dependencies: []),
        Target(name: "Graphics", dependencies: ["Basic"]),
        Target(name: "World", dependencies: ["Basic", "Graphics"]),
        Target(name: "UI", dependencies: ["Basic", "Graphics", "World"]),
        Target(name: "zenith", dependencies: ["UI"]),
        Target(name: "WorldTests"),
    ],
    dependencies: [
        .Package(url: "https://github.com/emlai/CSDL2.swift.git", majorVersion: 1),
        .Package(url: "https://github.com/jdfergason/swift-toml.git", Version(0, 4, 0)),
    ]
)
