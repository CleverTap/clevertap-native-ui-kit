// Library-level signals that let the integration-test automation suite observe
// in-app state deterministically instead of racing a fixed wall-clock wait.
//
// This is the Flutter counterpart of the batch-counter handshake the Android and
// iOS screenshot suites use: the Events screen bumps [batchCount] every time a
// new display-units batch is delivered, and the test polls that counter to know
// the *current* event's server response has landed before it screenshots.
//
// Harmless in normal use — the notifier is only read by the test. No gating
// required.

import 'package:flutter/foundation.dart';

/// Automation-only signals shared between the sample app and the integration
/// tests. Exposed as library-level singletons so both sides reference the same
/// instance without any dependency injection.
class AutomationSignals {
  AutomationSignals._();

  /// Incremented by one each time the Events screen delivers a new
  /// display-units batch (see `_onUnitsLoaded`). The screenshot suite captures
  /// the value before firing an event, then waits until this notifier exceeds
  /// that baseline — guaranteeing the screenshot reflects *this* event's
  /// response, not a stale previous one.
  static final ValueNotifier<int> batchCount = ValueNotifier<int>(0);
}
