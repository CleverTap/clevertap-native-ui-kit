---
title: Render slots in XML
sidebar_label: Android (XML)
sidebar_position: 4
description: Drop a NativeDisplaySlotView in any layout XML and let the bridge route campaigns to it.
---

# Render slots in XML

If your app is on traditional `View`-based layouts, the SDK exposes `NativeDisplaySlotView` — a `FrameLayout` subclass that auto-subscribes to a slot.

## 1 — Add to layout

```xml title="res/layout/activity_main.xml"
<LinearLayout xmlns:android="http://schemas.android.com/apk/res/android"
              xmlns:app="http://schemas.android.com/apk/res-auto"
              android:layout_width="match_parent"
              android:layout_height="match_parent"
              android:orientation="vertical">

    <com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView
        android:id="@+id/hero_slot"
        android:layout_width="match_parent"
        android:layout_height="wrap_content"
        app:slotId="hero_banner" />

    <!-- the rest of your screen -->

</LinearLayout>
```

That's it. The bridge ([Quickstart](/getting-started/quickstart)) routes any campaign with `slotId="hero_banner"` into this view.

## Setting the slot ID at runtime

If you'd rather not hard-code the slot ID in XML:

```kotlin
val slot = findViewById<NativeDisplaySlotView>(R.id.hero_slot)
slot.slotId = "hero_banner"
```

`slotId` can be changed at any time — the view re-subscribes immediately.

## Listening to actions

```kotlin
slot.actionListener = NativeDisplayActionListener { action, nodeId, trigger ->
    when (action.type) {
        "open_url"    -> openInBrowser(action.url)
        "dismiss"     -> hideHero()
        "track_event" -> analytics.track(action.event, action.properties)
    }
}
```

See [Actions](/concepts/actions).

## In a RecyclerView

To render different campaigns per row:

```kotlin
class FeedAdapter(...) : RecyclerView.Adapter<...>() {

    inner class SlotViewHolder(itemView: View) : RecyclerView.ViewHolder(itemView) {
        private val slot = itemView.findViewById<NativeDisplaySlotView>(R.id.slot)
        fun bind(slotId: String) {
            slot.slotId = slotId
        }
    }

    override fun onBindViewHolder(holder: ViewHolder, position: Int) {
        when (val item = items[position]) {
            is FeedItem.Article -> (holder as ArticleViewHolder).bind(item)
            is FeedItem.AdSlot  -> (holder as SlotViewHolder).bind(item.slotId)
        }
    }
}
```

The slot view caches its observer registration across `onViewRecycled` / `onViewAttached` so RecyclerView reuse doesn't leak listeners.

## Next

- [Concepts](/concepts/config-structure)
- [Actions](/concepts/actions)
- [Compose path](/getting-started/android-compose) — if you mix Compose and Views
