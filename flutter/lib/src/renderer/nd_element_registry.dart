import 'package:flutter/widgets.dart';

import '../evaluator/variable_evaluator.dart';
import '../models/enums.dart';
import '../models/native_display_node.dart';
import '../models/style.dart';

/// Builds a widget for a pluggable element type (VIDEO, HTML) whose heavy native
/// dependency (video_player / webview_flutter) is deliberately NOT bundled in the
/// core SDK. The signature matches the built-in element widgets, so a host-side
/// builder is a one-liner.
typedef NdElementBuilder = Widget Function(
  NativeDisplayElement node,
  Style style,
  VariableEvaluator evaluator,
);

/// Registry for optional element renderers.
///
/// VIDEO and HTML pull in large native plugins (`video_player`,
/// `webview_flutter`) that most integrators don't need, so the core SDK does not
/// depend on them. Instead, a host that wants those elements adds the matching
/// add-on package and registers its builder once at startup:
///
/// ```dart
/// // from package:clevertap_native_display_video
/// registerClevertapVideoRenderer();
/// ```
///
/// Element types with no registered builder render nothing (an empty
/// [SizedBox.shrink]) and log a warning — never a crash and never a forced
/// dependency.
class NativeDisplayRenderers {
  NativeDisplayRenderers._();

  static final Map<ElementType, NdElementBuilder> _builders =
      <ElementType, NdElementBuilder>{};

  /// Register a builder for [type]. Call once at app startup. Re-registering
  /// replaces the previous builder.
  static void register(ElementType type, NdElementBuilder builder) {
    _builders[type] = builder;
  }

  /// Remove a previously registered builder for [type].
  static void unregister(ElementType type) {
    _builders.remove(type);
  }

  /// The builder registered for [type], or `null` if none.
  static NdElementBuilder? builderFor(ElementType type) => _builders[type];

  /// Clears all registrations. Intended for tests.
  static void clear() => _builders.clear();
}
