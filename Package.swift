// swift-tools-version: 6.1
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "poweron_gadget",
    defaultLocalization: "en",
    platforms: [
        .macOS(.v12)
    ],
    products: [
        .executable(name: "poweron_gadget", targets: ["poweron_gadget"]),
        .executable(name: "PowerOnHelper", targets: ["PowerOnHelper"])
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PowerOnShared",
            path: "Sources/PowerOnShared"
            ),
        .executableTarget(
            name: "poweron_gadget",
            dependencies: ["PowerOnShared"],
            resources: [.process("Resources")]
            ),
        .executableTarget(
            name: "PowerOnHelper",
            dependencies: ["PowerOnShared"],
            path: "Sources/PowerOnHelper",
            sources: ["PowerOnHelper.swift", "main.swift"]
            ),
    ]
)
