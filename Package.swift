// swift-tools-version:4.0
import PackageDescription

let package = Package(
    name: "HexavilleFramework",
    products: [
        .library(name: "HexavilleFramework", targets: ["HexavilleFramework"]),
        .executable(name: "hexaville-framework-example", targets: ["HexavilleFrameworkExample"]),
    ],
    dependencies: [
        .package(url: "https://github.com/noppoMan/Prorsum.git", .upToNextMajor(from: "0.3.3")),
        .package(url: "https://github.com/jakeheis/SwiftCLI.git", .upToNextMajor(from: "5.0.0"))
    ],
    targets: [
        .target(name: "HexavilleFramework", dependencies: ["Prorsum", "SwiftCLI"]),
        .target(name: "HexavilleFrameworkExample", dependencies: ["HexavilleFramework"]),
        .testTarget(name: "HexavilleFrameworkTests", dependencies: ["HexavilleFramework"])
    ]
)
