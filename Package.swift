// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "CleverTapNativeDisplay",
    platforms: [
        .iOS(.v15)
    ],
    products: [
        .library(
            name: "CleverTapNativeDisplay",
            targets: ["CleverTapNativeDisplay"]
        ),
    ],
    dependencies: [],
    targets: [
        .target(
            name: "CleverTapNativeDisplay",
            dependencies: [],
            path: "ios/Sources/CleverTapNativeDisplay"
        ),
        .testTarget(
            name: "CleverTapNativeDisplayTests",
            dependencies: ["CleverTapNativeDisplay"],
            path: "ios/Tests/CleverTapNativeDisplayTests"
        ),
    ]
)
