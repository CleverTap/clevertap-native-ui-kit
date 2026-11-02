/// CleverTap Native Display + `clevertap_plugin` integration add-on.
///
/// Importing this package gives you everything from the core
/// `clevertap_native_display` library plus the one-call
/// [CleverTapNativeDisplayBinding.bindCleverTap] wiring. Standalone apps that
/// only render manual JSON should depend on `clevertap_native_display` directly
/// and skip this package (and its `clevertap_plugin` dependency) entirely.
library clevertap_plugin_with_native_display;

// Re-export the core SDK so integrators need a single import.
export 'package:clevertap_native_display/clevertap_native_display.dart';

export 'src/clevertap_auto_wire.dart' show CleverTapNativeDisplayBinding;
