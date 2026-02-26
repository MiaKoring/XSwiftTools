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
        .package(path: "../XSwiftToolsSupport"),
        .package(path: "../swift-cross-ui"),
        .package(url: "https://github.com/Frizlab/FSEventsWrapper.git", .upToNextMajor(from: "2.1.0"))
    ],
    targets: [
        .executableTarget(
            name: "XSwiftTools",
            dependencies: [
                .product(name: "XSwiftToolsSupport", package: "XSwiftToolsSupport"),
                .product(name: "SwiftCrossUI", package: "swift-cross-ui"),
                .product(name: "DefaultBackend", package: "swift-cross-ui"),
                .product(name: "FSEventsWrapper", package: "FSEventsWrapper")
            ]
        )
    ]
)
