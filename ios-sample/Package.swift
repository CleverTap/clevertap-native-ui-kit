// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "NativeDisplaySample",
    platforms: [
        .iOS(.v15)
    ],
    dependencies: [
        // Reference the local SDK package
        .package(name: "CleverTapNativeDisplay", path: "../ios"),
        // CleverTap iOS SDK for real integration demo
        .package(url: "https://github.com/CleverTap/clevertap-ios-sdk", .upToNextMajor(from: "7.0.0"))
    ],
    targets: [
        .executableTarget(
            name: "NativeDisplaySample",
            dependencies: [
                .product(name: "CleverTapNativeDisplay", package: "CleverTapNativeDisplay"),
                .product(name: "CleverTapSDK", package: "clevertap-ios-sdk")
            ],
            path: "NativeDisplaySample"
        )
    ]
)
