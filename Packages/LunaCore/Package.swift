// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "LunaCore",
    platforms: [
        .iOS(.v17),
        .macOS("26.0")
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
        )
    ]
)
