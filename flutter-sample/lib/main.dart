import 'package:clevertap_plugin/clevertap_plugin.dart';
import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import 'app.dart';

/// Set by the screenshot automation via `--dart-define=ND_AUTOMATION=true`.
/// When on, we discard CleverTap in-app notifications: the automation drives the
/// Flutter UI directly, and a native in-app overlay would cover it and break the
/// finders. Normal (human) runs leave in-apps enabled.
const _automation = bool.fromEnvironment('ND_AUTOMATION');

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // Surface the Native Display SDK's own logs while demoing. In a production
  // host you'd typically call NativeDisplayBridge.syncLogLevelFromCore(...)
  // with the CleverTap Core SDK debug level instead.
  NativeDisplayBridge.setLogLevel(NDLogLevel.verbose);

  if (_automation) {
    // CleverTap auto-initialises natively before this runs, so the discard
    // registers ahead of the app-launch in-app being shown.
    CleverTapPlugin.discardInAppNotifications();
  }

  runApp(const NativeDisplaySampleApp());
}
