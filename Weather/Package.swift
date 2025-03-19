// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Weather",
    platforms: [
        .macOS(.v15)
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "async"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ]
        ),
    ]
)
