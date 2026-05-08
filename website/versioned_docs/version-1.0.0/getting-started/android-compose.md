---
title: Render slots in Compose
sidebar_label: Android (Compose)
sidebar_position: 3
description: Drop NativeDisplaySlot into any Composable and let the bridge route campaigns to it.
---

# Render slots in Compose

Once the bridge is initialized ([Quickstart](/getting-started/quickstart)), rendering a Native Display campaign on a Compose screen is one composable.

```kotlin
import com.clevertap.android.nativedisplay.placement.NativeDisplaySlot

@Composable
fun HomeScreen() {
    Column {
        AppHeader()

        // The bridge routes any incoming campaign with slotId="hero_banner"
        // into this composable. No JSON parsing, no listener wiring.
        NativeDisplaySlot(slotId = "hero_banner")

        AppFeed()
    }
}
```

That's the entire integration on the rendering side. As soon as a campaign with that slot ID arrives via the Core SDK, this composable replaces its content with the rendered config. When the campaign is dismissed or expires, the composable goes back to empty.

## Slot lifecycle

`NativeDisplaySlot` registers with `NativeDisplaySlotManager` on first composition and unregisters in `onDispose`. You don't manage this manually.

- Multiple screens can declare slots with the **same** `slotId` — they all render the same unit when one arrives.
- A slot with **no** unit available is invisible (renders an empty `Box` of zero size, or your `loading` slot).

## Showing a placeholder while waiting

```kotlin
NativeDisplaySlot(
    slotId = "hero_banner",
    loading = {
        Box(
            modifier = Modifier
                .fillMaxWidth()
                .height(180.dp)
                .background(MaterialTheme.colorScheme.surfaceVariant)
        )
    },
)
```

The `loading` lambda renders only while the slot has no unit.

## Listening to action events

If a campaign config has `actions` blocks (button taps, deep links, dismiss), pass an action listener:

```kotlin
NativeDisplaySlot(
    slotId = "hero_banner",
    actionListener = object : NativeDisplayActionListener {
        override fun onAction(
            action: NativeDisplayAction,
            nodeId: String,
            trigger: String,
        ) {
            when (action.type) {
                "open_url"    -> openInBrowser(action.url)
                "dismiss"     -> dismissCampaign()
                "track_event" -> analytics.track(action.event, action.properties)
            }
        }
    },
)
```

See [Actions](/concepts/actions) for the full event surface.

## Where to place slots

Anywhere a Composable can render — top of a feed, inside a `LazyColumn` item, in a bottom-sheet, on an onboarding screen. The Core SDK delivers a campaign once; the slot it targets renders it; everywhere else stays untouched.

A common pattern is a feed with mixed app content + ad slots:

```kotlin
LazyColumn {
    items(feedItems) { item ->
        when (item) {
            is FeedItem.Article  -> ArticleRow(item)
            is FeedItem.AdSlot   -> NativeDisplaySlot(slotId = item.slotId)
        }
    }
}
```

## When to render manually instead

For previews, tests, or flows that intentionally bypass the dashboard, see [Advanced → manual config](/advanced/manual-config). 95% of production code uses `NativeDisplaySlot`.

## Next

- [Concepts](/concepts/config-structure) — how a config is structured
- [Actions](/concepts/actions) — handle taps, dismisses, deep links
- [Components](/components/containers/box) — what containers and elements your campaigns can use
