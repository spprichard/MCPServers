// swift-tools-version: 6.1

import PackageDescription

let package = Package(
    name: "SSEExample",
    platforms: [
         .macOS(.v15)
    ],
    products: [
        .library(
            name: "Client",
            targets: ["Client"]
        )
    ],
    dependencies: [
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "swift6"),
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
