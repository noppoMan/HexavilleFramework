// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "HexavilleFramework",
    products: [
        .library(name: "HexavilleFramework", targets: ["HexavilleFramework"]),
        .executable(name: "hexaville-framework-example", targets: ["HexavilleFrameworkExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/noppoMan/Prorsum.git", .upToNextMajor(from: "0.1.16")),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "3.1.0"))
    ],
    targets: [
        .target(name: "HexavilleFramework", dependencies: ["Prorsum", "SwiftCLI"]),
        .target(name: "HexavilleFrameworkExample", dependencies: ["HexavilleFramework"]),
        .testTarget(name: "HexavilleFrameworkTests", dependencies: ["HexavilleFramework"])
    ]
)
