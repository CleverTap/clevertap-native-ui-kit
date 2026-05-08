---
title: IMAGE element
sidebar_label: IMAGE
description: Loads remote images and animated GIFs.
---

# IMAGE

The **IMAGE** element loads a remote image (or animated GIF) over HTTPS and renders it inside its layout box. Use it for hero images, product photos, avatars, decorative illustrations, brand logos.

## Features

- Loads from any HTTP/HTTPS URL
- Auto-detects animated GIFs by URL extension / MIME type / known hosts
- Four content-fit modes: `crop`, `contain`, `fill`, `tile`
- Crossfade animation on load (both platforms)
- Cached via Coil (Android) / URLCache (iOS)

## JSON schema

```json
{
  "type": "element",
  "elementType": "image",
  "id": "hero",
  "bindings": {
    "url": "https://cdn.example.com/banner.png"
  },
  "layout": {
    "width":  { "value": 100, "unit": "percent" },
    "height": { "value": 200, "unit": "dp" }
  },
  "imageConfig": {
    "fit": "crop",
    "animated": null
  },
  "style": {
    "borderRadius": 8,
    "opacity": 1.0
  }
}
```

| Field | Required | Notes |
|-------|----------|-------|
| `bindings.url` | yes | HTTP or HTTPS. Supports `{{variable}}` interpolation. |
| `imageConfig.fit` | optional | Default `crop`. See fit modes below. |
| `imageConfig.animated` | optional | `null` (auto), `true` (force GIF), `false` (force still). |

## Fit modes

| Mode | Behaviour | iOS ContentMode | Android ContentScale |
|------|-----------|-----------------|----------------------|
| `crop` | Fill the box, crop overflow (default) | `.fill` | `Crop` |
| `contain` | Fit inside the box, may letterbox | `.fit` | `Fit` |
| `fill` | Stretch to fill (distorts aspect) | `.fill` | `FillBounds` |
| `tile` | Repeat across the box (treated as `crop` today) | `.fill` | `Crop` |

Use `crop` for hero images, `contain` for logos/icons, `fill` only when you intentionally want stretching.

## Animated GIFs

`imageConfig.animated` controls GIF playback:

| Value | Effect |
|-------|--------|
| `null` (default) | Auto-detect: animate when URL ends in `.gif`, MIME is `image/gif`, or host is a known GIF host (giphy, tenor, gfycat, imgur). |
| `true` | Force animated decode. Useful if the URL is a GIF without a clear extension. |
| `false` | Always render as a still image (the first frame). |

Auto-detection covers the common case. Override only when the URL is opaque (no extension, no obvious host).

## Platform parity

| Platform | Primitive | Source |
|----------|-----------|--------|
| Android | Coil's `AsyncImage` (+ Coil GIF decoder) | `ElementRenderer.kt:101–147` |
| iOS | SwiftUI `AsyncImage` for stills, custom `GIFImage` (UIViewRepresentable) for animated GIFs | `NativeDisplayRenderer.swift` |

Both platforms cache loaded images. Coil uses its own cache; iOS uses `URLCache.shared`.

## Examples

### Hero image, full width, fixed aspect

```json
{
  "type": "element",
  "elementType": "image",
  "id": "hero",
  "bindings": { "url": "{{heroUrl}}" },
  "layout": {
    "width": { "value": 100, "unit": "percent" },
    "aspectRatio": 1.78
  },
  "imageConfig": { "fit": "crop" },
  "style": { "borderRadius": 12 }
}
```

### Logo, contain, no crop

```json
{
  "type": "element",
  "elementType": "image",
  "id": "logo",
  "bindings": { "url": "{{brandLogoUrl}}" },
  "layout": { "width": { "value": 120, "unit": "dp" }, "height": { "value": 40, "unit": "dp" } },
  "imageConfig": { "fit": "contain" }
}
```

### Forced GIF playback

```json
{
  "imageConfig": { "animated": true }
}
```

## Common pitfalls

**`http://` URLs are blocked on iOS** unless your `Info.plist` opts in via App Transport Security exceptions. Always use `https://` in production configs.

**No `layout.height` and no `aspectRatio`** → image collapses to 0 height. Pick one — either set a fixed/percent height, or set `aspectRatio` so height derives from width.

**Tile mode is approximated as crop today.** True repeating-tile rendering is tracked but not yet scheduled — use `crop` and live with it for now.

**Animated GIFs hold memory while on screen.** If you have many GIFs in a long scrolling list, consider rendering them as stills with a tap-to-play affordance.

**Loading a single very large image (>4096px)** will spike memory on low-end Android devices. Pre-process to a reasonable max dimension on the backend.

## See also

- [BOX](/components/containers/box) — wrap an image in a BOX to overlay a label
- [VIDEO element](/components/elements/video) — for actual video, not GIF
