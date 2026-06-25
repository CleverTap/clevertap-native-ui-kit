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
            path: "ios/Sources/CleverTapNativeDisplay",
            resources: [
                // Apple privacy manifest. .copy keeps it verbatim (no processing)
                // so it ships in the SDK's resource bundle for App Store review.
                .copy("PrivacyInfo.xcprivacy")
            ]
        ),
        .testTarget(
            name: "CleverTapNativeDisplayTests",
            dependencies: ["CleverTapNativeDisplay"],
            path: "ios/Tests/CleverTapNativeDisplayTests"
        ),
    ]
)
