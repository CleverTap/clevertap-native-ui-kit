// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleverTapNativeDisplay",
    platforms: [
        .iOS(.v15),
        .tvOS(.v15)
    ],
    products: [
        .library(
            name: "CleverTapNativeDisplay",
            targets: ["CleverTapNativeDisplay"]
        ),
    ],
    dependencies: [
        // Generates DocC documentation. Used by the docs site CI job
        // to produce static HTML for `/api/ios/<version>/`.
        .package(url: "https://github.com/swiftlang/swift-docc-plugin", from: "1.3.0"),
    ],
    targets: [
        .target(
            name: "CleverTapNativeDisplay",
            dependencies: [],
            path: "Sources/CleverTapNativeDisplay"
        ),
        .testTarget(
            name: "CleverTapNativeDisplayTests",
            dependencies: ["CleverTapNativeDisplay"],
            path: "Tests/CleverTapNativeDisplayTests"
        ),
    ]
)
