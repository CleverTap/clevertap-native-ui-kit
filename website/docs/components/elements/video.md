---
title: VIDEO element
sidebar_label: VIDEO
description: Plays HTTP-streamed video via ExoPlayer (Android) and AVKit (iOS).
---

# VIDEO

The **VIDEO** element streams a remote video file over HTTPS. Useful for product demos, explainer animations, looping background hero videos.

## Dependency requirement (Android)

The SDK declares ExoPlayer as `compileOnly` — you must add it to your **app** module if you plan to render VIDEO elements:

```kotlin
implementation("androidx.media3:media3-exoplayer:1.5.0")
implementation("androidx.media3:media3-ui:1.5.0")
implementation("androidx.media3:media3-exoplayer-hls:1.5.0")  // for HLS streams
```

Without these, the SDK falls back to a placeholder. iOS uses the built-in AVKit and needs no extra dependency.

## Features

- HTTP / HTTPS / HLS streaming
- Auto-play, loop, mute, controls, fullscreen toggles — all via JSON bindings
- Optional `openUrl` deeplink fired when the user taps the video frame

## JSON schema

```json
{
  "type": "element",
  "elementType": "video",
  "id": "hero-video",
  "bindings": {
    "url":            "https://cdn.example.com/promo.mp4",
    "autoPlay":       true,
    "loop":           true,
    "muted":          true,
    "showControls":   false,
    "showFullscreen": false,
    "openUrl":        "https://example.com/learn-more"
  },
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "aspectRatio": 1.78
  },
  "style": { "borderRadius": 8 }
}
```

| Binding | Type | Default | Effect |
|---------|------|---------|--------|
| `url` | string | required | HTTP / HTTPS / HLS URL. Supports `{{variables}}`. |
| `autoPlay` | bool | `false` | Start playing on render. |
| `loop` | bool | `false` | Loop indefinitely. |
| `muted` | bool | `false` | Mute audio track. |
| `showControls` | bool | `true` | Show transport controls (play/pause/scrubber). |
| `showFullscreen` | bool | `false` | Render a fullscreen toggle button. |
| `openUrl` | string | none | If set, tapping the video opens this URL via the host app's URL handler (overrides the play/pause tap). |

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | ExoPlayer + Media3 PlayerView | `ElementRenderer.kt:200–253` |
| iOS | `VideoPlayer` (SwiftUI wrapper around AVKit) | `NativeDisplayRenderer.swift` (VideoNode branch) |

The Compose-side player is wired through `LocalVideoPlayerFactory` so host apps can swap in their own player implementation if needed (e.g. their own DRM-aware ExoPlayer).

## Examples

### Auto-play looping mute hero video

```json
{
  "type": "element",
  "elementType": "video",
  "id": "background-video",
  "bindings": {
    "url": "{{backgroundLoopUrl}}",
    "autoPlay": true,
    "loop": true,
    "muted": true,
    "showControls": false
  },
  "layout": { "width": { "value": 100, "unit": "percent" }, "aspectRatio": 0.5625 }
}
```

### Tap-to-deeplink demo

```json
{
  "bindings": {
    "url": "https://cdn.example.com/demo.mp4",
    "autoPlay": true,
    "loop": true,
    "muted": true,
    "openUrl": "https://example.com/product-demo"
  }
}
```

## Common pitfalls

**Missing ExoPlayer on Android** ⇒ the video renders as a black box. Add the Media3 dependencies to your app build.gradle.

**No `layout.height` or `aspectRatio`** ⇒ video collapses to 0 height. Pick one. `aspectRatio: 1.78` (16:9) and `aspectRatio: 0.5625` (9:16) are the common picks.

**Auto-play with audio.** Browsers and OS-level autoplay policies may suppress sound. Pair `autoPlay: true` with `muted: true` for reliable playback.

**Cellular data.** Auto-playing high-bitrate video over cellular drains battery and burns the user's data. Consider `autoPlay: false` and a poster image fallback for non-WiFi sessions if your host app exposes that signal as a variable.

**HLS streams** require the `media3-exoplayer-hls` artifact on Android.

## See also

- [IMAGE](/components/elements/image) — for stills and GIFs
- [HTML](/components/elements/html) — for HTML5 video that's not natively-playable
- [Actions](/concepts/actions) — for richer interactions than `openUrl`
