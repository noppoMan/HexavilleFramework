// swift-tools-version:3.1

import PackageDescription

let package = Package(
    name: "HexavilleFramework",
    targets: [
        Target(name: "HexavilleFramework"),
        Target(name: "HexavilleFrameworkExample", dependencies: ["HexavilleFramework"]),
    ],
    dependencies: [
        .Package(url: "https://github.com/noppoMan/Prorsum.git", majorVersion: 0, minor: 1),
        .Package(url: "https://github.com/jakeheis/SwiftCLI.git", majorVersion: 3, minor: 1)
    ]
)
