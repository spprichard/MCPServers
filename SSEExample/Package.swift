// swift-tools-version: 5.9
// Using version 5.9 to match SwiftMCP, due to build errors within SwiftMCP when using Swift 6.0

import PackageDescription

let package = Package(
    name: "SSEExample",
    platforms: [
        .macOS(.v14)
        // .macOS(.v15) // TODO: Add support for v15 when moving to Swift 6.0
    ],
    products: [
        .library(
            name: "Client",
            targets: ["Client"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        
        // Client
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.6.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
    ],
    targets: [
        .target(
            name: "Client",
            dependencies: [
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ],
            plugins: [.plugin(name: "OpenAPIGenerator", package: "swift-openapi-generator")]
        ),
        .target(
            name: "LibServer",
            dependencies: [
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "Server",
            dependencies: [
                .byName(name: "LibServer"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
            ]
        ),
        .executableTarget(
            name: "ClientApp",
            dependencies: [
                .target(name: "Client")
            ]
        ),
    ]
)
