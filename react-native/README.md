# `@clevertap/native-display-sdk`

React Native renderer for CleverTap server-driven native display units.
Reads `native_display_config` JSON from the CleverTap SDK and renders it into
a React tree that visually matches the iOS and Android native renderers.

## Quick start (bare React Native)

```bash
npm install @clevertap/native-display-sdk clevertap-react-native
```

Optional UI peer deps - install only what your JSON payloads use. The SDK
detects what's installed and gracefully degrades when something is missing
(e.g. linear gradients fall back to solid color if `react-native-linear-gradient`
is absent).

| Peer dep | Used by | Expo equivalent |
|---|---|---|
| `react-native-linear-gradient` | `linear_gradient` background | `expo-linear-gradient` (preferred under Expo) |
| `react-native-svg` | `radial_gradient`, `sweep_gradient`, `pattern` backgrounds | — |
| `react-native-reanimated` | `animated_gradient`, `shimmer`, `pulse`, `particles` backgrounds | — |
| `react-native-webview` | `html` element | — |
| `react-native-video` | `video` element | — |
| `@react-native-masked-view/masked-view` | gradient text | — |
| `@react-native-community/blur` | TODO | — |
| `react-native-fast-image` | image element fast path | `expo-image` (preferred under Expo) |
| `expo-image` | image element under Expo | — |
| `expo-linear-gradient` | `linear_gradient` background under Expo | — |

Wire the SDK up at app startup:

```ts
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';

NativeDisplayBridge.shared.bind(CleverTap);
NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
```

Render units with `<NativeDisplayView />`, or fetch them programmatically via
`NativeDisplayBridge.shared` / `NativeDisplaySlotManager`. See the bare example
at `example/` for the full set of integration patterns.

## Expo setup

This SDK is pure JS / TypeScript - it has **no native module of its own**, so
no additional Expo config plugin is needed for it. You wire up CleverTap's
native SDK separately via `@clevertap/clevertap-expo-plugin`, then install
this SDK like any other JS package.

### Required

1. `@clevertap/clevertap-expo-plugin` - drives CleverTap native setup at
   `expo prebuild` time (Podfile, Info.plist, AndroidManifest, lifecycle hooks).
2. `clevertap-react-native` `>=4.1.0` - matches our peer requirement.
3. `@clevertap/native-display-sdk` (this package).

### app.json

Add the plugin:

```jsonc
{
  "expo": {
    "plugins": [
      ["@clevertap/clevertap-expo-plugin", {
        "accountId":    "...",
        "accountToken": "...",
        "accountRegion": "in1",
        "ios":     { "mode": "development" },
        "android": { "registerActivityLifecycleCallbacks": true }
      }]
    ]
  }
}
```

### Prebuild + run

```bash
npx expo prebuild --clean
npx expo run:ios       # or run:android
```

### Expo Go is not supported

`clevertap-react-native` requires native iOS / Android code that Expo Go
cannot supply at runtime. You must use `expo prebuild` + `expo run:*`, or
EAS Build.

### Preferred peer deps under Expo

The SDK's `src/optional/optionalDeps.ts` checks `process.env.EXPO_OS` and, when
running under Expo, prefers the Expo-native versions:

- `expo-image` over `react-native-fast-image`
- `expo-linear-gradient` over `react-native-linear-gradient`

Installing both is fine - the Expo branch wins inside Expo apps, the bare
branch wins everywhere else. Installing only the Expo variant works too.

### Example

A working Expo example app lives at `expo-example/`. It reuses the bare
example's screens 1:1 via a Metro path alias - see `expo-example/README.md`
for details.

## Bare React Native example

The bare-RN reference app is at `example/`. It demonstrates the same six
screens (Events, Slots, Browser, Bridge, Banners, Fonts) that the Expo example
loads from disk.

## License

MIT
