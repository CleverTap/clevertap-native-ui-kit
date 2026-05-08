---
title: Actions
sidebar_label: Actions
description: Triggers fired on tap, long-press, double-tap, appear, and disappear.
---

# Actions

Every node can declare an `actions` block that maps a **trigger name** to a list of action objects. When the trigger fires, the SDK runs each action in order, then notifies the host app's `NativeDisplayActionListener`.

Actions are how you make CTAs do something — open a URL, dismiss the unit, fire a custom event back to the host app.

## Triggers

| Trigger | Fired when |
|---------|-----------|
| `onClick` | Single tap. The most common trigger. |
| `onLongPress` | Long-press (≥ 500 ms by default). |
| `onDoubleTap` | Two taps in quick succession. |
| `onAppear` | Node first becomes visible on screen. |
| `onDisappear` | Node leaves the screen. |

## JSON schema

```json
{
  "actions": {
    "onClick": [
      { "type": "open_url", "url": "https://example.com" }
    ],
    "onLongPress": [
      { "type": "dismiss" }
    ],
    "onAppear": [
      { "type": "track_event", "event": "card_viewed" }
    ]
  }
}
```

A trigger is a list — you can fire multiple actions in sequence.

## Action types (v1.0.0 documented)

### `open_url`

Hands the URL off to the host app via `NativeDisplayActionListener.onOpenUrl(url:)`. The host app decides whether to open in-app, in a browser, or as a deeplink.

```json
{ "type": "open_url", "url": "https://example.com/promo" }
```

The `url` field supports `{{variable}}` interpolation.

### `dismiss`

Asks the host to close / remove the current display unit. Useful for "X" buttons on banners, modals, full-screen takeovers.

```json
{ "type": "dismiss" }
```

### `track_event`

Forwards an event name back to the host's `NativeDisplayActionListener.onAction(...)`. The host typically threads it into analytics (CleverTap, Mixpanel, etc.).

```json
{
  "type": "track_event",
  "event": "promo_clicked",
  "properties": { "campaignId": "{{campaignId}}", "tier": "gold" }
}
```

`properties` is an arbitrary key/value map. String values support `{{variables}}`.

### `custom`

Anything host-app-specific. The SDK passes the entire action object through unchanged.

```json
{ "type": "custom", "name": "show_login_sheet", "args": { "trigger": "promo" } }
```

The host implements `onCustomAction(...)` to handle it.

## Listener delivery

The host app installs a listener once per `NativeDisplayView`:

```kotlin
NativeDisplayView(
    config = resolved,
    actionListener = object : NativeDisplayActionListener {
        override fun onAction(action: NativeDisplayAction, nodeId: String, trigger: String) {
            when (action.type) {
                "open_url"    -> openInBrowser(action.url)
                "dismiss"     -> finish()
                "track_event" -> analytics.track(action.event, action.properties)
                "custom"      -> handleCustom(action)
            }
        }
    },
)
```

The listener receives the action, the firing node's `id`, and the trigger name. Return value can be used to short-circuit — e.g. consuming an `open_url` so the SDK doesn't try a default behaviour.

## Platform parity

| Platform | Source |
|----------|--------|
| Android | `ActionHandler.kt:71–105` |
| iOS | `ActionHandler.swift` (mirror implementation) |

Trigger semantics, action types, listener flow are identical.

## Examples

### Banner with open-URL on tap and dismiss on long-press

```json
{
  "type": "container",
  "containerType": "box",
  "id": "banner",
  "actions": {
    "onClick":     [ { "type": "open_url", "url": "{{ctaUrl}}" } ],
    "onLongPress": [ { "type": "dismiss" } ]
  },
  "children": [ /* hero image, headline, etc. */ ]
}
```

### Track impression on appear

```json
{
  "actions": {
    "onAppear": [
      { "type": "track_event", "event": "promo_impression", "properties": { "id": "{{promoId}}" } }
    ]
  }
}
```

## Common pitfalls

**Trigger fires for the node, not for the deepest tappable child.** If a BOX has `onClick` and a child BUTTON also has `onClick`, the BUTTON wins and the BOX never fires. Don't double-wire unless you know which one bubbles.

**`onAppear` fires per scroll** in some `GALLERY` modes — once on initial layout, then again as the node enters the viewport after being scrolled off. Use a guard in your listener if you only want a single impression event.

**Forgetting the listener** ⇒ taps register, ripples animate, but nothing reaches your app. Always install a `NativeDisplayActionListener` if your config uses any actions.

**Custom action types in v1.0.0** ⇒ the SDK passes them through verbatim; if the host doesn't implement `onCustomAction`, the action is silently dropped.

## See also

- [BUTTON element](/components/elements/button)
- [Animations](/concepts/animations) — for triggering visual animations on tap (paired with custom actions)
- [CleverTap Core SDK](/integrations/core-sdk) — for routing `track_event` actions through CleverTap analytics
