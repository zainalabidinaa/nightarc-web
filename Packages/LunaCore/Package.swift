// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "LunaCore",
    platforms: [
        .iOS(.v17),
        .macOS(.v14)
    ],
    products: [
        .library(
            name: "LunaCore",
            targets: ["LunaCore"]
        )
    ],
    targets: [
        .target(
            name: "LunaCore",
            path: "Sources/LunaCore"
        ),
        .testTarget(
            name: "LunaCoreTests",
            dependencies: ["LunaCore"],
            path: "Tests/LunaCoreTests"
        )
    ]
)
