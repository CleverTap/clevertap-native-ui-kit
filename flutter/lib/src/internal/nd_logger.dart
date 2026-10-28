import 'dart:developer' as developer;

import 'package:flutter/foundation.dart';

/// Log verbosity for the Native Display SDK.
///
/// Values mirror CleverTap Core SDK `setDebugLevel` integers so
/// [NDLogger.syncFromCoreSdk] can map directly:
///   `-1` OFF  · `0` INFO  · `2` DEBUG  · `3` VERBOSE
///
/// Default level is [info]. Configure via [NativeDisplayBridge.setLogLevel].
enum NDLogLevel {
  off(-1),
  info(0),
  debug(2),
  verbose(3);

  final int value;
  const NDLogLevel(this.value);

  static NDLogLevel fromInt(int v) =>
      NDLogLevel.values.firstWhere((l) => l.value == v, orElse: () => NDLogLevel.info);
}

/// Structured logger for the Native Display SDK.
///
/// Format: `[NativeDisplay]: <tag>: <msg>` — matches Android `NDLogger` and
/// iOS `NDLogger.swift` so logs read consistently across platforms.
///
/// Warnings and errors are always emitted at [NDLogLevel.info] and above —
/// they are always significant.
///
/// Dart isolates each have their own logger state. Flutter SDK code runs on
/// the root isolate; the parser runs in a child isolate but only emits log
/// lines at the warning level (its level matches the root level only if the
/// child isolate inherits state — for parser warnings the level check happens
/// in the root isolate's NDLogger, since the warning is emitted via
/// debugPrint-equivalent before being structured).
class NDLogger {
  static const String _logcatTag = 'CleverTap';
  static const String _prefix = '[NativeDisplay]';

  static NDLogLevel _level = NDLogLevel.info;
  static bool _explicitlySet = false;

  /// Set the active log level. Marks the level as explicitly set so future
  /// auto-wire syncs from Core SDK do not override the client preference.
  static void setLevel(NDLogLevel level) {
    _level = level;
    _explicitlySet = true;
  }

  /// Sync from Core SDK debug level. Does NOT mark as explicitly set —
  /// the auto-wire path remains free to re-sync on subsequent runs until the
  /// client calls [setLevel] explicitly.
  static void syncFromCoreSdk(int coreLevel) {
    if (!_explicitlySet) {
      _level = NDLogLevel.fromInt(coreLevel);
    }
  }

  static NDLogLevel get currentLevel => _level;
  static bool get isExplicitlySet => _explicitlySet;

  /// Reset logger state to defaults. Test-only — the static state is otherwise
  /// process-global and would leak between test cases.
  @visibleForTesting
  static void resetForTest() {
    _level = NDLogLevel.info;
    _explicitlySet = false;
  }

  static String _format(String tag, String msg) => '$_prefix: $tag: $msg';

  static void v(String tag, String msg) {
    if (_level.value >= NDLogLevel.verbose.value) {
      developer.log(_format(tag, msg), name: _logcatTag, level: 500);
    }
  }

  static void d(String tag, String msg) {
    if (_level.value >= NDLogLevel.debug.value) {
      developer.log(_format(tag, msg), name: _logcatTag, level: 700);
    }
  }

  static void i(String tag, String msg) {
    if (_level.value >= NDLogLevel.info.value) {
      developer.log(_format(tag, msg), name: _logcatTag, level: 800);
    }
  }

  /// Warnings are always shown at INFO and above — they are significant
  /// regardless of debug-level tuning.
  static void w(String tag, String msg) {
    if (_level.value >= NDLogLevel.info.value) {
      developer.log(_format(tag, msg), name: _logcatTag, level: 900);
    }
  }

  /// Errors are always shown at INFO and above.
  static void e(String tag, String msg, [Object? error, StackTrace? stackTrace]) {
    if (_level.value >= NDLogLevel.info.value) {
      developer.log(
        _format(tag, msg),
        name: _logcatTag,
        level: 1000,
        error: error,
        stackTrace: stackTrace,
      );
    }
  }
}
