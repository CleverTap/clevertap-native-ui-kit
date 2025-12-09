// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleverTapNativeUIKit",
    platforms: [
        .iOS(.v15),
        .macOS(.v12)
    ],
    products: [
        .library(
            name: "CleverTapNativeUIKit",
            targets: ["CleverTapNativeUIKit"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CleverTapNativeUIKit",
            dependencies: [],
            path: "Sources/CleverTapNativeUIKit"
        ),
    ]
)
