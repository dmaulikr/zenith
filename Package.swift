import PackageDescription

let package = Package(
    name: "zenith",
    dependencies: [
        .Package(url: "https://github.com/emlai/CSDL2.swift.git", majorVersion: 1),
        .Package(url: "https://github.com/emlai/YamlSwift.git", versions: Version(1, 5, 0)..<Version(2, 0, 0)),
    ]
)
