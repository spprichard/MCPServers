// swift-tools-version: 6.0
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "Gateway",
    platforms: [
        .macOS(.v15)
    ],
    products: [
        .library(
            name: "MistralKit",
            targets: ["MistralKit"]
        ),
    ],
    dependencies: [
        .package(url: "https://github.com/thebarndog/swift-dotenv", from: "2.1.0"),
        .package(url: "https://github.com/Cocoanetics/SwiftMCP.git", branch: "main"),
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(name: "LibEmail", path: "/Users/stevenprichard/Developer/MCP/MCPServers/Email"),
        .package(url: "https://github.com/hummingbird-project/hummingbird.git", from: "2.0.0"),
        // 🇫🇷 MistralKit 🦾
        .package(url: "https://github.com/vapor/multipart-kit", from: "4.0.0"),
        .package(url: "https://github.com/apple/swift-openapi-runtime", from: "1.7.0"),
        .package(url: "https://github.com/apple/swift-openapi-generator", from: "1.7.1"),
        .package(url: "https://github.com/apple/swift-openapi-urlsession", from: "1.0.0"),
        .package(url: "https://github.com/apple/swift-nio", from: "2.81.0"),
        .package(url: "https://github.com/swift-extras/swift-extras-base64", .upToNextMinor(from: "0.7.0")),
    ],
    targets: [
        .executableTarget(
            name: "Gateway",
            dependencies: [
                .byName(name: "LibGateway"),
                .byName(name: "MistralKit"),
                .product(name: "ArgumentParser", package: "swift-argument-parser"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        ),
        .target(
            name: "LibGateway",
            dependencies: [
                .byName(name: "LibEmail"),
                .product(name: "SwiftMCP", package: "SwiftMCP"),
                .product(name: "SwiftDotenv", package: "swift-dotenv"),
            ]
        ),
        .target(
            name: "MistralKit",
            dependencies: [
                .product(name: "NIOCore", package: "swift-nio"),
                .product(name: "Hummingbird", package: "hummingbird"),
                .product(name: "MultipartKit", package: "multipart-kit"),
                .product(name: "ExtrasBase64", package: "swift-extras-base64"),
                .product(name: "OpenAPIRuntime", package: "swift-openapi-runtime"),
                .product(name: "OpenAPIURLSession", package: "swift-openapi-urlsession"),
            ]
        ),
    ]
)
