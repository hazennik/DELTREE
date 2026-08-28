// swift-tools-version: 6.0
import PackageDescription

let package = Package(
    name: "DELTREE",
    platforms: [
        .macOS(.v14),
    ],
    products: [
        .library(name: "DELTREECore", targets: ["DELTREECore"]),
    ],
    targets: [
        .target(
            name: "DELTREECore",
            path: "DELTREE",
            exclude: [
                "App",
                "Assets.xcassets",
                "DELTREEApp.swift",
                "Info.plist",
                "Resources",
                "ViewModels",
                "Views",
            ],
            sources: [
                "Models",
                "Persistence",
                "Services",
            ],
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
        .testTarget(
            name: "DELTREECoreTests",
            dependencies: ["DELTREECore"],
            path: "Tests/DELTREECoreTests",
            swiftSettings: [
                .swiftLanguageMode(.v6),
                .enableUpcomingFeature("StrictConcurrency"),
            ]),
    ])
