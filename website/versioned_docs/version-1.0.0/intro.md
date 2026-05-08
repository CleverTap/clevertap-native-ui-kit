---
slug: /
title: Native UI Kit
sidebar_position: 1
---

The **CleverTap Native UI Kit** renders native mobile interfaces from JSON delivered by your CleverTap dashboard. The same JSON renders identically as Jetpack Compose on Android and SwiftUI on iOS — no native code change per campaign.

It's designed to pair with the **CleverTap Core SDK** and your existing campaigns. You drop a slot into your screen, point it at a slot ID, and any Native Display campaign targeting that slot renders automatically.

## How it fits in

```
    CleverTap dashboard          Your app
    ┌──────────────────┐        ┌──────────────────────────────────┐
    │  Native Display  │        │  CleverTap Core SDK              │
    │     campaign     │ ─────► │       │                          │
    │   (JSON config)  │        │       ▼                          │
    └──────────────────┘        │  NativeDisplayBridge             │
                                 │       │                          │
                                 │       ▼                          │
                                 │  NativeDisplaySlot("hero_banner")│
                                 │  ────► renders the campaign      │
                                 └──────────────────────────────────┘
```

You author campaigns in the CleverTap dashboard. The Core SDK delivers them. The Native UI Kit's bridge parses them. Slot views in your app auto-render the matching unit.

## Three steps to integrate

1. **Install** the SDK — [Gradle / SwiftPM / CocoaPods](/getting-started/install).
2. **Initialize the bridge** once at app start, after the Core SDK — [Quickstart](/getting-started/quickstart).
3. **Drop a slot** in any screen with the slot ID configured in your campaign — platform guides for [Compose](/getting-started/android-compose), [Android XML](/getting-started/android-xml), [SwiftUI](/getting-started/ios-swiftui), [Objective-C](/getting-started/ios-objc).

## What's documented

- **4 containers** — [BOX](/components/containers/box), [VERTICAL](/components/containers/vertical), [HORIZONTAL](/components/containers/horizontal), [GALLERY](/components/containers/gallery).
- **7 elements** — [TEXT](/components/elements/text), [IMAGE](/components/elements/image), [BUTTON](/components/elements/button), [VIDEO](/components/elements/video), [HTML](/components/elements/html), [SPACER](/components/elements/spacer), [DIVIDER](/components/elements/divider).
- **6 dimension units** — [percent](/dimensions/percent), [dp](/dimensions/dp), [sp](/dimensions/sp), [px](/dimensions/px), [`wrap_content` / `match_parent`](/dimensions/special).
- **Concepts** — [config structure](/concepts/config-structure), [layout](/concepts/layout-system), [arrangement](/concepts/arrangement-strategies), [style cascading](/concepts/style-cascading), [style classes](/concepts/style-classes-deep), [theme](/concepts/theme), [variables](/concepts/templates-and-variables), [animations](/concepts/animations), [actions](/concepts/actions).
- **Integrations** — [Core SDK bridge](/integrations/core-sdk), [backend payload spec](/integrations/backend-payload).
- **Advanced** — [manual config rendering](/advanced/manual-config) for offline previews, tests, or flows that don't go through the dashboard.
- **API reference** — Dokka HTML for Android, DocC static for iOS.
