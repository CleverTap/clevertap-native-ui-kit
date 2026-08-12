import 'package:flutter/material.dart';
import 'package:clevertap_native_display/clevertap_native_display.dart';

import 'app.dart';

void main() {
  // Surface the Native Display SDK's own logs while demoing. In a production
  // host you'd typically call NativeDisplayBridge.syncLogLevelFromCore(...)
  // with the CleverTap Core SDK debug level instead.
  NativeDisplayBridge.setLogLevel(NDLogLevel.debug);
  runApp(const NativeDisplaySampleApp());
}
