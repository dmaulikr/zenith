import PackageDescription

let package = Package(
    name: "zenith",
    dependencies: [
        .Package(url: "https://github.com/emlai/CSDL2.swift.git", majorVersion: 1),
        .Package(url: "https://github.com/jdfergason/swift-toml.git", Version(0, 3, 0)),
    ]
)
