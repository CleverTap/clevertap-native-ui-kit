---
title: Render slots in SwiftUI
sidebar_label: iOS (SwiftUI)
sidebar_position: 5
description: Drop a NativeDisplaySlot view into any SwiftUI screen and let the bridge route campaigns to it.
---

# Render slots in SwiftUI

Once the bridge is initialized ([Quickstart](/getting-started/quickstart)), rendering a Native Display campaign on a SwiftUI screen is one view.

```swift
import SwiftUI
import CleverTapNativeDisplay

struct HomeScreen: View {
    var body: some View {
        VStack(spacing: 0) {
            AppHeader()

            // The bridge routes any incoming campaign with slotId == "hero_banner"
            // into this view. No JSON parsing, no listener wiring.
            NativeDisplaySlot(slotId: "hero_banner")

            AppFeed()
        }
    }
}
```

When a matching campaign arrives, the view replaces its content with the rendered config. When the campaign is dismissed or expires, the view goes back to its loading placeholder.

## Slot lifecycle

`NativeDisplaySlot` registers with `NativeDisplaySlotManager` in `onAppear` and unregisters in `onDisappear`. You don't manage this manually.

- Multiple views can declare slots with the **same** `slotId` — they all render the same unit when one arrives.
- A slot with **no** unit available renders the `loading` view (or `EmptyView` by default).

## Showing a placeholder while waiting

```swift
NativeDisplaySlot(slotId: "hero_banner") {
    RoundedRectangle(cornerRadius: 8)
        .fill(Color.gray.opacity(0.15))
        .frame(height: 180)
}
```

The trailing closure renders only while the slot has no unit.

## Listening to action events

```swift
NativeDisplaySlot(
    slotId: "hero_banner",
    actionListener: MyActionListener()
)

class MyActionListener: NativeDisplayActionListener {
    func onAction(
        _ action: NativeDisplayAction,
        nodeId: String,
        trigger: String
    ) {
        switch action.type {
        case "open_url":    UIApplication.shared.open(URL(string: action.url)!)
        case "dismiss":     dismissCampaign()
        case "track_event": Analytics.track(action.event, action.properties)
        default: break
        }
    }
}
```

See [Actions](/concepts/actions) for the full event surface.

## Where to place slots

Anywhere a `View` can render. Inside a `List`, between sections, in a `.sheet`, on an onboarding flow. A common pattern is a mixed feed:

```swift
List {
    ForEach(feedItems) { item in
        switch item {
        case .article(let article): ArticleRow(article)
        case .adSlot(let slotId):   NativeDisplaySlot(slotId: slotId)
        }
    }
}
```

## When to render manually instead

For SwiftUI previews, tests, or flows that intentionally bypass the dashboard, see [Advanced → manual config](/advanced/manual-config). 95% of production code uses `NativeDisplaySlot`.

## Next

- [Concepts](/concepts/config-structure) — how a config is structured
- [Actions](/concepts/actions) — handle taps, dismisses, deep links
- [Components](/components/containers/box) — what containers and elements your campaigns can use
