# CleverTap Native Display — VIDEO element add-on

Package: `clevertap_native_display_video`

## What this is

An optional add-on for [`clevertap_native_display`](../flutter/README.md) that enables rendering of `VIDEO` elements in Native Display campaigns. It is backed by [`video_player`](https://pub.dev/packages/video_player).

The core renderer does **not** bundle `video_player` — to keep it dependency-light, video support is opt-in. Add this package only if your campaigns use `VIDEO` elements.

## Quick facts

| Question | Answer |
|---|---|
| Minimum versions | Flutter 3.24+, Dart 3.5+ |
| Backing package | `video_player` ^2.9.2 |
| Needed when? | Only if your campaigns include `VIDEO` elements |

## Install

```yaml
dependencies:
  clevertap_native_display: ^1.0.0
  clevertap_native_display_video: ^1.0.0
```

```bash
flutter pub get
```

## Usage

Call `registerClevertapVideoRenderer()` once at startup, before the first Native Display render:

```dart
import 'package:flutter/material.dart';
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';

void main() {
  registerClevertapVideoRenderer();
  runApp(const MyApp());
}
```

Without this call, `VIDEO` elements render nothing (with a warning log). The rest of the campaign renders normally.

## Campaign JSON

A `VIDEO` element reads these bindings (all optional except `url`):

| Binding | Default | Purpose |
|---------|---------|---------|
| `url` | — | Video source URL |
| `autoPlay` | `false` | Start playback automatically |
| `loop` | `false` | Loop playback |
| `muted` | `false` | Start muted |
| `showControls` | `true` | Show the custom overlay controls |
| `showFullscreen` | `true` | Show the expand/fullscreen control |

```json
{
  "type": "VIDEO",
  "bindings": {
    "url": "https://example.com/clip.mp4",
    "autoPlay": true,
    "loop": true,
    "muted": true
  },
  "layout": { "width": { "value": 100, "unit": "percent" }, "aspectRatio": 1.777 }
}
```

## Custom controls

The add-on renders its own tap-to-reveal overlay controls (play/pause, mute, expand/collapse, close) rather than the platform chrome, so the look matches the Android/iOS SDKs. The controls expose stable test tags for UI/widget tests:

```dart
import 'package:clevertap_native_display_video/clevertap_native_display_video.dart';

ndVideoTestTagPlay;     // 'nd_video_play'
ndVideoTestTagMute;     // 'nd_video_mute'
ndVideoTestTagExpand;   // 'nd_video_expand'
ndVideoTestTagCollapse; // 'nd_video_collapse'
ndVideoTestTagClose;    // 'nd_video_close'
```

## Learn more

- [Flutter Integration guide](../docs/INTEGRATION_FLUTTER.md#optional-elements-video--html)
- [Core package README](../flutter/README.md)
- [JSON Structure Reference](../docs/JSON_STRUCTURE_REFERENCE.md)
