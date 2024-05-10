// swift-tools-version: 5.10
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "PinKit",
    platforms: [.iOS("17.4"), .macOS(.v10_15), .tvOS(.v17), .visionOS(.v1)],
    products: [
        // Products define the executables and libraries a package produces, making them visible to other packages.
        .library(
            name: "PinKit",
            targets: ["PinKit"]),
    ],
    dependencies: [
        .package(url: "https://github.com/SDWebImage/SDWebImageSwiftUI", from: "3.0.4"),
        .package(url: "https://github.com/ericlewis/CollectionConcurrencyKit", branch: "main"),
        .package(url: "https://github.com/apple/swift-collections.git", .upToNextMinor(from: "1.1.0")),
        .package(url: "https://github.com/kean/Get", .upToNextMinor(from: "2.2.0"))
    ],
    targets: [
        // Targets are the basic building blocks of a package, defining a module or a test suite.
        // Targets can depend on other targets in this package and products from dependencies.
        .target(
            name: "PinKit",
            dependencies: [
                "SDWebImageSwiftUI",
                "CollectionConcurrencyKit",
                "Get",
                "Models",
                .product(name: "Collections", package: "swift-collections")
            ]),
        .target(name: "Models"),
        .testTarget(
            name: "PinKitTests",
            dependencies: ["PinKit"]),
    ]
)
