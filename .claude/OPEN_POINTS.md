# Open Points & Design Decisions

This file tracks unresolved design questions and open product decisions for the Native Display SDK.

---

## [OP-001] Error Handling: Failed Elements in Production

**Status:** Open
**Raised:** 2026-03-17
**Context:** During investigation of error handling in Android and iOS SDKs, the following question arose around what to render when an element fails (image load failure, missing URL, video player error, JSON parse error).

### Decision Made
- In **production**: silent failure — render nothing (`EmptyView` on iOS, early `return` on Android Compose). No empty space, no placeholder, no error text.
- In **debug**: show the existing error placeholder views (`"No Image"`, `"No Video URL"`, `"Video Player Unavailable"`, etc.) to aid development.

### Open Sub-Points

#### 1. Video Fallback Image
The video element currently shows a `"No Video"` debug placeholder when the URL is missing or invalid. In production it would silently disappear.

**Proposed idea:** Support an optional `fallbackImageUrl` binding on the VIDEO element. If the video fails to load (invalid URL, network error, ExoPlayer init failure) and a `fallbackImageUrl` is provided, render it as a static image instead of disappearing entirely.

```json
{
  "type": "VIDEO",
  "bindings": {
    "url": "{{videoUrl}}",
    "fallbackImageUrl": "https://example.com/poster.jpg"
  }
}
```

This gives config authors control over graceful degradation without forcing a blank space. Considerations:
- Should the fallback trigger only on URL-missing or also on mid-playback errors?
- Should it be a full IMAGE element style (with `imageConfig` options like `fit`, `animated`) or a simple URL string?
- Android: ExoPlayer has a native `setMediaItem` + listener path; fallback can be set in `Player.Listener.onPlayerError`
- iOS: AVPlayer error can be caught in `AVPlayerItem.Status.failed` observer

#### 2. Image Load Failure (Network Error)
Currently on iOS, a network image load failure shows the SF Symbols `"photo"` icon in debug. In production it would silently disappear (zero space).

**Proposed idea:** Support an optional `fallbackImageUrl` on the IMAGE element as well — same pattern as video fallback. If the primary URL fails, retry with the fallback before disappearing.

#### 3. GIF Load Failure (iOS)
GIF failures are already silently blank (no placeholder even in debug). This is inconsistent with static image behaviour.

**Proposed idea:** In debug, GIF load failures should show the same `"No Image"` placeholder as static images. In production, they should collapse to zero height just like static images. This is a consistency fix regardless of the broader fallback decision.

#### 4. JSON Parse Error Callback
Currently neither platform notifies the client of a JSON parse failure with structured metadata. The client only receives a thrown exception (iOS) or `null` return (Android sample loader).

**Proposed idea:** Add a `onConfigParseError(error)` callback to the existing listener interfaces (`NativeDisplayActionListener` on iOS, equivalent on Android). This lets client apps log parse errors to their own analytics/crash reporting without needing to re-wrap the SDK's parsing entry points.

---

## Notes
- Add new open points with the format `[OP-NNN]` and increment the counter.
- When a point is resolved, mark **Status:** Resolved and add a **Resolution:** line.
