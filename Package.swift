// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "HexavilleFramework",
    products: [
        .library(name: "HexavilleFramework", targets: ["HexavilleFramework"]),
        .executable(name: "hexaville-framework-example", targets: ["HexavilleFrameworkExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-nio.git", from: "1.11.0"),
        .package(url: "https://github.com/apple/swift-nio-ssl.git", from: "1.3.2"),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "5.0.0")),
        .package(url: "https://github.com/Hexaville/PKGConfig.git", .branch("master"))
    ],
    targets: [
        .target(name: "HexavilleFramework", dependencies: [
            "NIO",
            "NIOHTTP1",
            "NIOOpenSSL",
            "NIOFoundationCompat",
            "SwiftCLI",
            "PKGConfig"
        ]),
        .target(name: "HexavilleFrameworkExample", dependencies: ["HexavilleFramework"]),
        .testTarget(name: "HexavilleFrameworkTests", dependencies: ["HexavilleFramework"])
    ]
)
