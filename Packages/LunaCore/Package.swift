// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "NightarcCore",
    platforms: [
        .iOS(.v17),
        .macOS("14.0")
    ],
    products: [
        .library(
            name: "NightarcCore",
            targets: ["NightarcCore"]
        )
    ],
    targets: [
        .target(
            name: "NightarcCore",
            path: "Sources/LunaCore"
        ),
        .testTarget(
            name: "NightarcCoreTests",
            dependencies: ["NightarcCore"],
            path: "Tests/LunaCoreTests"
        )
    ]
)
