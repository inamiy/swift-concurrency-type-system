// swift-tools-version: 6.2

import PackageDescription

let package = Package(
    name: "docs-scripts",
    platforms: [.macOS(.v13)],
    dependencies: [
        .package(url: "https://github.com/inamiy/markdown-toc.git", branch: "main"),
    ],
    targets: []
)
