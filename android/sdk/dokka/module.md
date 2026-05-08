# Module clevertap-native-ui-kit

Server-driven UI rendering for Android, written in Kotlin and Jetpack Compose. Renders a `NativeDisplayConfig` JSON tree into a native Compose UI.

## v1.0.0 documented surface

The first release documents only the **BOX container** plus **percentage-based dimensions and styles**. Everything else (other containers, elements, units, arrangement strategies, theme system, animations, actions) is in the public API but documented incrementally in subsequent releases.

## Entry points

- [`NativeDisplayView`](com.clevertap.android.nativedisplay/-native-display-view) — Compose entry point that takes a `NativeDisplayConfig` and renders it.
- [`ContainerType.BOX`](com.clevertap.android.nativedisplay.models/-container-type/-b-o-x) — overlapping-children container; the only container documented in v1.0.0.

## See also

- [BOX component guide](https://clevertap.github.io/clevertap-native-ui-kit/1.0.0/components/containers/box)
- [Percentage-based dimensions](https://clevertap.github.io/clevertap-native-ui-kit/1.0.0/dimensions/percent)
