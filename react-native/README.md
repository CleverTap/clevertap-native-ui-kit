# CleverTap Native Display for React Native

Package: `@clevertap/native-display-sdk`

## What this is

CleverTap lets you design UI campaigns (banners, cards, carousels, and more) on
the CleverTap dashboard and send them to your app. This package draws those
campaigns as real, native React Native screens - no WebViews. You design once on
the dashboard; the app shows it without an app-store update.

This package is only the part that draws the campaign. The campaign itself is
delivered by the main CleverTap SDK (`clevertap-react-native`). So you always set
up CleverTap first, then add this package on top.

Works with both kinds of React Native apps: plain ("bare") React Native and Expo.

## Quick facts

| Question | Answer |
|---|---|
| Which platforms? | iOS and Android |
| Minimum versions | React Native 0.73+, React 18+, `clevertap-react-native` 4.1+ |
| Does it add native code of its own? | No. This package is pure TypeScript. (The main CleverTap SDK does have native code.) |
| Does it work with Expo? | Yes, with `expo prebuild` or EAS Build. **Not** with Expo Go. |
| Where are campaigns designed? | On the CleverTap dashboard, not in code. |
| Who authors the JSON? | The dashboard does. App developers normally never write it by hand. |

## Contents

- [Before you start](#before-you-start)
- [Which setup do I need?](#which-setup-do-i-need)
- [Set up - bare React Native](#set-up---bare-react-native)
- [Set up - Expo](#set-up---expo)
- [Optional UI features](#optional-ui-features)
- [Using it in your code](#using-it-in-your-code)
- [FAQ and troubleshooting](#faq-and-troubleshooting)
- [Reference and advanced](#reference-and-advanced)

## Before you start

Check off these first. They are not part of this package, but nothing works
without them:

1. **A CleverTap account.** You need an Account ID, an Account Token, and a
   Region (for example `in1`). These come from the CleverTap dashboard.
2. **The main CleverTap SDK set up in the app.** That is `clevertap-react-native`,
   installed and initialized with the credentials above. This package listens to
   it. See the [CleverTap React Native docs](https://developer.clevertap.com/docs/react-native).

   **Already using CleverTap?** Keep your existing setup as it is. Your init code,
   your credentials, and your native config do not change. You only add this
   package on top. One thing to check first: `clevertap-react-native` must be
   `4.1.0` or newer. Older apps are often on an earlier version, so confirm yours
   before you start. An out-of-date Core SDK is a common reason nothing renders.
3. **Know which kind of app you have** - bare React Native or Expo. If you are
   not sure and your project has `ios/` and `android/` folders you edit by hand,
   it is bare. If you run `npx expo ...` commands, it is Expo.

## Which setup do I need?

Follow **one** of the two tracks below - the one that matches your app. Do
**not** do both. They install different packages and set CleverTap up in
different ways, so mixing them will break the build.

| Your app | Follow |
|---|---|
| Plain React Native (has `ios/` and `android/` folders) | [Set up - bare React Native](#set-up---bare-react-native) |
| Expo | [Set up - Expo](#set-up---expo) |

## Set up - bare React Native

> Bare React Native only. If your app uses Expo, skip this section and go to
> [Set up - Expo](#set-up---expo) instead.

### 1. Install

```bash
npm install @clevertap/native-display-sdk clevertap-react-native
```

`clevertap-react-native` is the main CleverTap SDK. If you already have it, you
only need the first package.

### 2. Wire it up at app startup

Add this once, where your app starts (usually `App.tsx`):

```ts
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';

// Connect this renderer to the main CleverTap SDK.
NativeDisplayBridge.shared.bind(CleverTap);

// Ask CleverTap for any campaigns waiting for this user.
NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
```

> If your campaigns use gradients, video, web content, or blur, you also need to
> register the libraries that draw them - see
> [Optional UI features](#optional-ui-features). Text-only campaigns need nothing
> extra.

### 3. Show the campaign

Render campaigns with `<NativeDisplayView />`. See
[Using it in your code](#using-it-in-your-code) for a full example, and the
runnable app in [`example/`](example/).

### 4. Check that it works

When a campaign's trigger event fires, your app receives the campaign and draws
it. To watch this happen in the console, turn on debug logs:

```ts
import { NativeDisplayBridge, NDLogLevel } from '@clevertap/native-display-sdk';

NativeDisplayBridge.shared.setLogLevel(NDLogLevel.DEBUG);
```

If nothing shows up, see [FAQ and troubleshooting](#faq-and-troubleshooting).

## Set up - Expo

> Expo only. If your app is plain React Native, skip this section and use
> [Set up - bare React Native](#set-up---bare-react-native) instead.

This package is pure JavaScript, so it needs no special Expo config of its own.
You set up the main CleverTap SDK for Expo, then add this package like any other
JavaScript library.

### 1. Install

```bash
npx expo install @clevertap/native-display-sdk clevertap-react-native @clevertap/clevertap-expo-plugin
```

- `@clevertap/clevertap-expo-plugin` sets up CleverTap's native pieces during
  `expo prebuild` (Podfile, Info.plist, AndroidManifest, lifecycle hooks).
- `clevertap-react-native` must be `4.1.0` or newer.

> **Already have CleverTap set up in your Expo app?** You only need
> `@clevertap/native-display-sdk`. The plugin and the `app.json` block below are
> already in place, so install just that one package, then skip to
> [step 3](#3-prebuild-and-run).

### 2. Add the plugin to `app.json`

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

### 3. Prebuild and run

```bash
npx expo prebuild --clean
npx expo run:ios       # or run:android
```

### 4. Wire it up and show the campaign

The JavaScript code to start the SDK and draw a campaign is identical on both
tracks. Reuse the snippets from
[step 2](#2-wire-it-up-at-app-startup) and [step 3](#3-show-the-campaign) above -
just the code, not the bare install commands. A runnable Expo app lives in
[`expo-example/`](expo-example/).

> **Expo Go will not work.** The main CleverTap SDK needs native code that Expo
> Go cannot load. You must use `expo prebuild` + `expo run:*`, or EAS Build.

## Optional UI features

Some features of a native display template - gradients, video, web content,
blur - are drawn using well-known React Native libraries. Wiring one up takes
two steps: **install** the library, then **register** it with the SDK at startup
(see [Register them at startup](#register-them-at-startup) below). You do both
only for the libraries your campaigns actually use.

The SDK never imports these libraries itself. It uses only the ones you hand it
through `registerComponents`. If a feature's library is not registered, the SDK
falls back to a simpler look (for example, a gradient becomes a solid color)
instead of crashing. So it is safe to start with none and add a library later if
a template feature does not look right - just remember the second step, register
it, or installing alone changes nothing.

### Install all of them at once (optional)

If you would rather not think about which template feature needs which library,
install the whole set in one command. Pick the block that matches your app.

Bare React Native:

```bash
npm install react-native-linear-gradient react-native-svg react-native-reanimated \
  react-native-webview react-native-video @react-native-masked-view/masked-view \
  @react-native-community/blur react-native-fast-image
```

Expo (uses `expo install` so versions match your Expo SDK, and swaps in the
Expo-native gradient and image libraries):

```bash
npx expo install expo-linear-gradient react-native-svg react-native-reanimated \
  react-native-webview react-native-video @react-native-masked-view/masked-view \
  @react-native-community/blur expo-image
```

Two things to know:

- **React 19 and `react-native-fast-image`.** The current `react-native-fast-image`
  (8.6.3) declares a React peer range of `^17 || ^18`, so on a React 19 project
  `npm install` will reject it. Drop it from the bare command (image loading
  still works through the built-in image view, just without the fast-image
  speedup), or add `--legacy-peer-deps`. The Expo command avoids this by using
  `expo-image` instead.
- **`react-native-reanimated` needs a Babel plugin.** After installing it, add
  the plugin as the last entry in `babel.config.js` and rebuild - see the
  reanimated note in [FAQ and troubleshooting](#faq-and-troubleshooting).

### Register them at startup

Installing a library is not enough on its own. The SDK does not import these
libraries. You import each one and hand it to the SDK with `registerComponents`.
Do this once, in your app's entry file (`index.js`), before any campaign
renders. Register only the libraries you installed.

```js
import Video from 'react-native-video';
import LinearGradient from 'react-native-linear-gradient';
import * as Svg from 'react-native-svg';
import * as Reanimated from 'react-native-reanimated';
import { WebView } from 'react-native-webview';
import MaskedView from '@react-native-masked-view/masked-view';
import { BlurView } from '@react-native-community/blur';
import FastImage from 'react-native-fast-image';
import { registerComponents } from '@clevertap/native-display-sdk';

registerComponents({
  Video,
  LinearGradient,
  Svg,
  Reanimated,
  WebView,
  MaskedView,
  BlurView,
  FastImage,
});
```

Each value must match the shape the SDK reads back:

- **Default export** - `Video`, `LinearGradient`, `MaskedView`, `FastImage`.
- **Named export** - `WebView`, `BlurView`.
- **Whole module namespace** (`import * as`) - `Svg`, `Reanimated`.

**On Expo**, swap the two libraries that have Expo-native equivalents and register
them under their own keys:

```js
import LinearGradient from 'react-native-linear-gradient'; // or expo-linear-gradient
import { Image as ExpoImage } from 'expo-image'; // named export, key "ExpoImage"

registerComponents({
  // ... the rest as above ...
  LinearGradient,
  ExpoImage, // replaces FastImage under Expo
});
```

The SDK prefers `ExpoImage` over `FastImage` when both are registered. Since you
choose which keys to register, register the one you installed. For a complete
entry file, see [`example/index.js`](example/index.js) (bare) or
[`expo-example/index.js`](expo-example/index.js) (Expo).

<details>
<summary><b>Which library powers which feature</b></summary>

| Library | Powers | Expo equivalent |
|---|---|---|
| `react-native-linear-gradient` | linear gradient backgrounds | `expo-linear-gradient` (preferred under Expo) |
| `react-native-svg` | radial, sweep, and pattern backgrounds | - |
| `react-native-reanimated` | animated gradient, shimmer, pulse, particle backgrounds | - |
| `react-native-webview` | `HTML` elements | - |
| `react-native-video` | `VIDEO` elements | - |
| `@react-native-masked-view/masked-view` | gradient-filled text | - |
| `@react-native-community/blur` | blur effects | - |
| `react-native-fast-image` | faster image loading | `expo-image` (preferred under Expo) |

Minimum versions are listed as peer dependencies in
[`package.json`](package.json). Under Expo you register the Expo-native gradient
and image libraries in place of the bare ones - see
[Register them at startup](#register-them-at-startup).

</details>

## Using it in your code

Listen for campaigns, then draw each one with `<NativeDisplayView />`:

```tsx
import React, { useEffect, useState } from 'react';
import { ScrollView } from 'react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
import type {
  NativeDisplayUnit,
  NativeDisplayBridgeListener,
} from '@clevertap/native-display-sdk';

export function Campaigns() {
  const [units, setUnits] = useState<NativeDisplayUnit[]>([]);

  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(incoming) {
        setUnits(incoming);
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    return () => NativeDisplayBridge.shared.removeListener(listener);
  }, []);

  return (
    <ScrollView>
      {units.map((unit) => (
        <NativeDisplayView key={unit.unitId} unit={unit} />
      ))}
    </ScrollView>
  );
}
```

For placing campaigns into named slots, or handling taps and custom actions, see
the runnable [`example/`](example/) app, which shows every integration pattern.

## FAQ and troubleshooting

**Do we need to change native (iOS/Android) code to use this package?**
No. This package is pure TypeScript. The main CleverTap SDK does need native
setup - on Expo that is handled by `expo prebuild`.

**Can we test in Expo Go?**
No. See the [Expo Go note](#set-up---expo). Use `expo prebuild` + `expo run:*` or
EAS Build.

**We do not use video (or gradients). Do we still install those libraries?**
No. Everything under [Optional UI features](#optional-ui-features) is optional.
Install only what your campaigns use.

**Which platforms are supported?**
iOS and Android.

**Nothing is showing up. What do I check?**

1. Is the main CleverTap SDK installed and initialized with valid credentials?
2. Did you call both `NativeDisplayBridge.shared.bind(CleverTap)` and
   `fetchNativeDisplays(CleverTap)` at startup?
3. Did you register a listener with `addListener` and render
   `<NativeDisplayView />` for the units you receive? Fetching alone does not
   draw anything on screen - see [Using it in your code](#using-it-in-your-code).
4. Did the event that the campaign targets actually fire for this user?
5. Did you rebuild the app after installing? On bare React Native run
   `cd ios && pod install` for iOS, then rebuild. On Expo run
   `npx expo prebuild --clean` again.
6. Turn on debug logs with
   `NativeDisplayBridge.shared.setLogLevel(NDLogLevel.DEBUG)` and watch the
   console when the event fires.

**I get "Unable to resolve module ..." or a red error screen right after installing.**
Metro (the JavaScript bundler) is using a stale list of packages. Stop it and
restart with a clean cache: `npx react-native start --reset-cache` on bare React
Native, or `npx expo start --clear` on Expo.

**I installed a UI library (video, gradient, ...) but the feature still does not appear.**
Two things to check. First, did you register it? Installing a library does not
wire it to the SDK on its own - you must also pass it to `registerComponents` at
startup. See [Register them at startup](#register-them-at-startup). Second,
libraries with native code need a full app rebuild, not just a JavaScript reload.
Stop the app and rebuild it. On iOS run `cd ios && pod install` first (bare React
Native) or `npx expo prebuild --clean` (Expo).

If you installed `react-native-reanimated` for animated backgrounds, you must
also add its Babel plugin as the **last** entry in `babel.config.js`, or the app
can silently fail to mount on Android. The plugin name depends on your Reanimated
version: for Reanimated 4 it is `react-native-worklets/plugin`; for Reanimated 3
it is `react-native-reanimated/plugin`. Rebuild after changing `babel.config.js`.

**A gradient or video looks wrong or is missing.**
The library that draws it is either not installed or not registered. Installing
alone is not enough - you must also pass it to `registerComponents` at startup.
See [Optional UI features](#optional-ui-features) and
[Register them at startup](#register-them-at-startup).

## Reference and advanced

- **Campaign JSON schema** - the full structure the SDK draws:
  [../docs/JSON_STRUCTURE_REFERENCE.md](../docs/JSON_STRUCTURE_REFERENCE.md).
- **How it works internally** - architecture and the end-to-end render flow:
  [docs/ARCHITECTURE.md](docs/ARCHITECTURE.md) and
  [docs/HAPPY_FLOW.md](docs/HAPPY_FLOW.md).
- **How optional libraries reach the SDK** - the SDK never imports the optional
  peer libraries. The app imports each one and passes it to `registerComponents`
  at startup. The SDK reads them back from that registry
  (`src/optional/componentRegistry.ts`). A key that was never registered means
  the feature degrades gracefully. This keeps the SDK bundler-agnostic - it works
  on Metro of any version, on Expo, and on Re.Pack, with no `require` of a native
  library from inside the SDK.
- **Expo image preference** - when both `ExpoImage` and `FastImage` are
  registered, the SDK uses `ExpoImage`
  (`src/renderer/elements/ImageElement.tsx`). Since you choose which keys to
  register, register the one you installed.
- **Exported API** - `NativeDisplayBridge`, `NativeDisplayView`,
  `NativeDisplaySlotManager`, `NativeDisplaySlot`, `wireCleverTap`, `NDLogLevel`,
  and supporting types. See [`src/index.ts`](src/index.ts).

## License

MIT
