// swift-tools-version: 6.2
// The swift-tools-version declares the minimum version of Swift required to build this package.

import PackageDescription

let package = Package(
    name: "XSwiftTools",
    platforms: [
      .macOS(.v14),
      .iOS(.v17)
    ],
    dependencies: [
        /*.package(
            url: "https://github.com/stackotter/swift-cross-ui",
            branch: "main"
        ),*/
        .package(path: "../swift-test-parser"),
        .package(path: "../swift-cross-ui"),
        .package(path: "../XSwiftToolsPlugin")
    ],
    targets: [
        .executableTarget(
            name: "XSwiftTools",
            dependencies: [
                .product(name: "TestParser", package: "swift-test-parser"),
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
                .product(name: "XSwiftToolsPluginInterface", package: "XSwiftToolsPlugin")
            ]
        )
    ]
)
