// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "JEVEmoji",
    platforms: [.macOS(.v13)],
    products: [
        .executable(name: "JEVEmoji", targets: ["JEVEmoji"])
    ],
    targets: [
        .executableTarget(name: "JEVEmoji", path: "Sources/JEVEmoji")
    ]
)
