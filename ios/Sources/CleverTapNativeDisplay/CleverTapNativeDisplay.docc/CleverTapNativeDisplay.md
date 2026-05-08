# ``CleverTapNativeDisplay``

Server-driven UI rendering for iOS, written in Swift and SwiftUI. Renders a `NativeDisplayConfig` JSON tree into a native SwiftUI view hierarchy.

## Overview

The SDK takes a JSON configuration (typically delivered by the CleverTap backend) and produces native UI without any host-app code changes per layout. The same JSON renders identically on Android via the companion Kotlin SDK.

> Important: v1.0.0 documents only the **BOX container** and **percentage-based dimensions and styles**. Other components and units exist in the public API but are documented incrementally in later releases.

## Topics

### Entry points

- ``NativeDisplayView``

### Containers (v1.0.0)

- ``ContainerType/box``

### Layout primitives

- Layout sizing, padding, and offset live in the renderer's `LayoutModifier`. See the Renderer source for details until the API is fully documented in v1.1.0.

### See Also

- [BOX component guide](https://clevertap.github.io/clevertap-native-ui-kit/1.0.0/components/containers/box)
- [Percentage-based dimensions](https://clevertap.github.io/clevertap-native-ui-kit/1.0.0/dimensions/percent)
