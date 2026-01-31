// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "WindowGrip",
    platforms: [
        .macOS(.v14) // Using v14 as a safe modern baseline, v15 might require very recent tools
    ],
    products: [
        .executable(name: "WindowGrip", targets: ["WindowGrip"])
    ],
    targets: [
        .executableTarget(
            name: "WindowGrip",
            path: "WindowGrip/WindowGrip",
            exclude: [
                "App/Info.plist",
                "App/WindowGrip.entitlements"
            ],
            resources: [
                .process("Assets.xcassets")
            ]
        )
    ]
)
