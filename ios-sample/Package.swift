// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativeDisplaySample",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // Reference the local SDK package
        .package(name: "CleverTapNativeDisplay", path: "../ios")
    ],
    targets: [
        .executableTarget(
            name: "NativeDisplaySample",
            dependencies: [
                .product(name: "CleverTapNativeDisplay", package: "CleverTapNativeDisplay")
            ],
            path: "NativeDisplaySample"
        )
    ]
)
