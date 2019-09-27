// swift-tools-version:5.1
import PackageDescription

let package = Package(
    name: "HexavilleFramework",
    products: [
        .library(name: "HexavilleFramework", targets: ["HexavilleFramework"]),
        .executable(name: "hexaville-framework-example", targets: ["HexavilleFrameworkExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "2.8.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "2.4.0"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "HexavilleFramework", dependencies: [
            "NIO",
            "NIOHTTP1",
            "NIOSSL",
            "NIOFoundationCompat",
            "SwiftCLI"
        ]),
        .target(name: "HexavilleFrameworkExample", dependencies: ["HexavilleFramework"]),
        .testTarget(name: "HexavilleFrameworkTests", dependencies: ["HexavilleFramework"])
    ]
)
