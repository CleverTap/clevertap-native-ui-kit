library clevertap_native_display_video;

import 'package:clevertap_native_display/clevertap_native_display.dart';

import 'src/video_element.dart';

export 'src/video_element.dart' show VideoElement;

/// Enables rendering of Native Display `VIDEO` elements.
///
/// Call once at app startup, before the first Native Display render:
///
/// ```dart
/// void main() {
///   registerClevertapVideoRenderer();
///   runApp(const MyApp());
/// }
/// ```
///
/// Without this, VIDEO elements render nothing (with a warning log) — the core
/// SDK does not depend on `video_player`.
void registerClevertapVideoRenderer() {
  NativeDisplayRenderers.register(
    ElementType.video,
    (node, style, evaluator) =>
        VideoElement(node: node, style: style, evaluator: evaluator),
  );
}
