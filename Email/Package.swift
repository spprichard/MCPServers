// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Email",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "LibEmail",
            type: .static,
            targets: [
                "LibEmail"
            ]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/Cocoanetics/SwiftMail.git", branch: "main"),
        .package(url: "https://github.com/thebarndog/swift-dotenv", from: "2.1.0"),
    ],
    targets: [
        .executableTarget(
            name: "App",
            dependencies: [
                .byName(name: "LibEmail"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .target(
            name: "LibEmail",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftMail", package: "SwiftMail"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        ),
        .testTarget(
            name: "LibEmailTests",
            dependencies: [
                .byName(name: "LibEmail"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        )
    ]
)
