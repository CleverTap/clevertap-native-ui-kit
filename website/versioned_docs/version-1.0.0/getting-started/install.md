---
title: Install the SDK
sidebar_label: Install
sidebar_position: 1
description: Add the Native UI Kit to an Android or iOS project.
---

# Install the SDK

Add the dependency, then continue to the [quickstart](/getting-started/quickstart).

## Android

The SDK is published as `com.clevertap.android:clevertap-native-ui-kit`.

```kotlin title="app/build.gradle.kts"
dependencies {
    implementation("com.clevertap.android:clevertap-native-ui-kit:1.0.0")

    // Required: Jetpack Compose BOM and core
    implementation(platform("androidx.compose:compose-bom:2024.12.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.activity:activity-compose:1.9.3")

    // CleverTap Core SDK — this is what the bridge pairs with
    implementation("com.clevertap.android:clevertap-android-sdk:7.5.0")
}
```

**Minimum**: Android API 23 (6.0). **Compile**: API 36. **Java target**: 17.

Optional video support (only if you render `VIDEO` elements):

```kotlin
implementation("androidx.media3:media3-exoplayer:1.5.0")
implementation("androidx.media3:media3-ui:1.5.0")
```

## iOS

### CocoaPods (recommended)

```ruby title="Podfile"
pod 'CleverTapNativeDisplay', '~> 1.0.0'
pod 'CleverTapSDK'   # the Core SDK the bridge pairs with
```

CocoaPods is the recommended distribution channel — the pod is published to the public CocoaPods spec repo and works without GitHub access.

### Swift Package Manager

The SDK is also published to a Swift Package registry. Your CleverTap support contact will share the package URL during onboarding — paste it into **File → Add Packages…** in Xcode and pin to **1.0.0** or "Up to Next Major Version".

**Minimum**: iOS 15, tvOS 15. **Swift tools**: 5.9+.

## Next

Continue → **[Quickstart](/getting-started/quickstart)** — wire up the bridge.
