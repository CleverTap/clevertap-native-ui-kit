library clevertap_native_display_webview;

import 'package:clevertap_native_display/clevertap_native_display.dart';

import 'src/html_element.dart';

export 'src/html_element.dart' show HtmlElement;

/// Enables rendering of Native Display `HTML` elements.
///
/// Call once at app startup, before the first Native Display render:
///
/// ```dart
/// void main() {
///   registerClevertapHtmlRenderer();
///   runApp(const MyApp());
/// }
/// ```
///
/// Without this, HTML elements render nothing (with a warning log) — the core
/// SDK does not depend on `webview_flutter`.
void registerClevertapHtmlRenderer() {
  NativeDisplayRenderers.register(
    ElementType.html,
    (node, style, evaluator) =>
        HtmlElement(node: node, style: style, evaluator: evaluator),
  );
}
