---
title: Manual config rendering
sidebar_label: Manual config
description: Render a NativeDisplayConfig you constructed yourself, bypassing the bridge.
---

# Manual config rendering

For SwiftUI / Compose previews, unit tests, design-system catalogues, or flows that intentionally bypass the dashboard, you can construct a `NativeDisplayConfig` JSON directly and render it through `NativeDisplayView` without going through the bridge.

This is **not** the canonical integration. For production, use the [slot path](/getting-started/quickstart) — the bridge handles parsing, lifecycle, and action routing. Reach for manual rendering when you need full control or are deliberately offline.

## When this is the right tool

- **Compose / SwiftUI previews** of a known-good config.
- **Snapshot / screenshot tests** that need a deterministic input.
- **Design-system gallery screens** that show every container/element variant.
- **Internal tooling** (config validators, layout debuggers) that wants a render of arbitrary JSON.

## Android (Compose)

```kotlin
import com.clevertap.android.nativedisplay.bridge.NativeDisplayConfigParser
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

@Composable
fun PreviewMyConfig() {
    val json = """
      {
        "root": {
          "type": "container",
          "containerType": "box",
          "id": "root",
          "layout": {
            "width":  { "value": 100, "unit": "percent" },
            "height": { "value": 100, "unit": "percent" }
          },
          "style": { "backgroundColor": "#101820" }
        }
      }
    """.trimIndent()

    val resolved = remember { NativeDisplayConfigParser.parse(json) }

    NativeDisplayView(
        config = resolved,
        modifier = Modifier.fillMaxSize(),
    )
}
```

`NativeDisplayConfigParser.parse(json)` returns a `ResolvedConfig` ready for the renderer. Cache it across recompositions — re-parsing on every frame is wasted work.

## iOS (SwiftUI)

```swift
import SwiftUI
import CleverTapNativeDisplay

struct PreviewMyConfig: View {
    private let resolved: ResolvedConfig

    init() {
        let json = """
          {
            "root": {
              "type": "container",
              "containerType": "box",
              "id": "root",
              "layout": {
                "width":  { "value": 100, "unit": "percent" },
                "height": { "value": 100, "unit": "percent" }
              },
              "style": { "backgroundColor": "#101820" }
            }
          }
        """
        self.resolved = try! NativeDisplayConfigParser.parse(json: json)
    }

    var body: some View {
        NativeDisplayView(config: resolved)
            .ignoresSafeArea()
    }
}
```

Parse once, store on the view, and let SwiftUI re-use it across renders.

## Listening to events

`NativeDisplayView` accepts the same `actionListener` and `componentListener` that the slot path accepts:

```kotlin
NativeDisplayView(
    config = resolved,
    actionListener = MyActionListener(),
    componentListener = MyComponentListener(),
    unitId = "preview",
)
```

```swift
NativeDisplayView(
    config: resolved,
    actionListener: MyActionListener(),
    componentListener: MyComponentListener(),
    unitId: "preview",
)
```

## What you lose vs. the slot path

When you render manually instead of via a slot:

- **No automatic delivery** of new campaigns from the dashboard.
- **No display-unit attribution events** flow through the Core SDK bridge — taps don't show up in CleverTap dashboards as click-throughs unless your `actionListener` forwards them yourself.
- **No slot lifecycle**. You manage when to mount/unmount the view yourself.

For anything user-facing in production, use slots. Manual rendering is a developer-tooling escape hatch.

## See also

- [Quickstart — bridge + slot integration](/getting-started/quickstart) — the canonical path
- [Components](/components/containers/box) — what JSON you'd construct
- [JSON schema](/json-reference/v1.0.0-schema) — full reference
