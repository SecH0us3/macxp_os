// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "MacXP",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(name: "MacXP", dependencies: []),
        .testTarget(name: "MacXPTests", dependencies: ["MacXP"]),
    ]
)
