// swift-tools-version: 6.0

import PackageDescription

let package = Package(
    name: "ClaudeCrab",
    platforms: [
        .macOS(.v13)
    ],
    products: [
        .executable(name: "ClaudeCrab", targets: ["ClaudeCrab"])
    ],
    targets: [
        .executableTarget(name: "ClaudeCrab"),
        .testTarget(
            name: "ClaudeCrabTests",
            dependencies: ["ClaudeCrab"]
        )
    ]
)
