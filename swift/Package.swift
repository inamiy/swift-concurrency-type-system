// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "SwiftConcurrencyTypeSystem",
    platforms: [.iOS(.v17), .macCatalyst(.v17), .macOS(.v14)],
    products: [
        .library(
            name: "concurrency-type-check",
            targets: ["concurrency-type-check"]
        ),
    ],
    targets: [
        .target(
            name: "concurrency-type-check"
        ),
        .testTarget(
            name: "concurrency-type-checkTests",
            dependencies: ["concurrency-type-check"]
        ),
    ],
    swiftLanguageModes: [.v6]
)
