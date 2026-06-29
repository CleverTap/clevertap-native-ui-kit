# Platform Channel Bridge — CleverTap Integration

## Overview

The platform channel bridge connects the Flutter Native Display plugin to the CleverTap Core SDK on Android and iOS. The Dart-side renderer is pure Flutter — platform channels are only needed to:

1. Fetch display unit JSON from the Core SDK cache
2. Receive push-based display unit updates
3. Report viewed/clicked events back to the Core SDK

---

## Channel Definitions

```dart
// lib/src/bridge/native_display_bridge.dart

class NativeDisplayBridge {
  static const _methodChannel = MethodChannel(
    'com.clevertap.flutter/native_display',
  );
  static const _eventChannel = EventChannel(
    'com.clevertap.flutter/native_display_events',
  );

  /// Fetch display unit JSON by ID (pull-based).
  static Future<NativeDisplayConfig?> getDisplayUnit(String unitId) async {
    final json = await _methodChannel.invokeMethod<String>(
      'getDisplayUnit',
      unitId,
    );
    if (json == null) return null;
    return NativeDisplayConfig.fromJson(jsonDecode(json));
  }

  /// Stream of display unit updates as they arrive (push-based).
  static Stream<NativeDisplayConfig> displayUnitUpdates() {
    return _eventChannel
        .receiveBroadcastStream()
        .whereType<String>()
        .map((json) => NativeDisplayConfig.fromJson(jsonDecode(json)));
  }

  static Future<void> recordViewed(String unitId) =>
      _methodChannel.invokeMethod('recordViewed', unitId);

  static Future<void> recordClicked(String unitId) =>
      _methodChannel.invokeMethod('recordClicked', unitId);

  static Future<void> recordElementClicked(
    String unitId,
    String elementId, {
    Map<String, dynamic>? additionalProperties,
  }) =>
      _methodChannel.invokeMethod('recordElementClicked', {
        'unitId': unitId,
        'elementId': elementId,
        if (additionalProperties != null) ...additionalProperties,
      });
}
```

---

## Android Bridge (Kotlin)

```kotlin
// android/src/main/kotlin/com/clevertap/flutter/nativedisplay/CleverTapNativeDisplayPlugin.kt

class CleverTapNativeDisplayPlugin : FlutterPlugin, MethodCallHandler {
  private lateinit var channel: MethodChannel
  private lateinit var eventChannel: EventChannel
  private var eventSink: EventChannel.EventSink? = null

  override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
    channel = MethodChannel(
      binding.binaryMessenger,
      "com.clevertap.flutter/native_display"
    )
    channel.setMethodCallHandler(this)

    eventChannel = EventChannel(
      binding.binaryMessenger,
      "com.clevertap.flutter/native_display_events"
    )
    eventChannel.setStreamHandler(object : EventChannel.StreamHandler {
      override fun onListen(args: Any?, sink: EventChannel.EventSink) {
        eventSink = sink
      }
      override fun onCancel(args: Any?) {
        eventSink = null
      }
    })
  }

  override fun onMethodCall(call: MethodCall, result: MethodChannel.Result) {
    when (call.method) {
      "getDisplayUnit" -> {
        val unitId = call.arguments as? String
        if (unitId == null) { result.error("INVALID_ARG", "unitId required", null); return }
        // CleverTap Core SDK returns the cached unit as a JSON string
        val json = CleverTapAPI.getDefaultInstance(context)
            ?.getDisplayUnitForId(unitId)  // returns JSONObject
            ?.toString()
        result.success(json)
      }
      "recordViewed" -> {
        val unitId = call.arguments as? String ?: return result.error("INVALID_ARG", null, null)
        CleverTapAPI.getDefaultInstance(context)?.pushDisplayUnitViewedEventForID(unitId)
        result.success(null)
      }
      "recordClicked" -> {
        val unitId = call.arguments as? String ?: return result.error("INVALID_ARG", null, null)
        CleverTapAPI.getDefaultInstance(context)?.pushDisplayUnitClickedEventForID(unitId)
        result.success(null)
      }
      "recordElementClicked" -> {
        val args = call.arguments as? Map<*, *> ?: return result.error("INVALID_ARG", null, null)
        val unitId = args["unitId"] as? String ?: return result.error("INVALID_ARG", null, null)
        val elementId = args["elementId"] as? String ?: return result.error("INVALID_ARG", null, null)
        CleverTapAPI.getDefaultInstance(context)
            ?.pushDisplayUnitElementClickedEventForID(unitId, elementId)
        result.success(null)
      }
      else -> result.notImplemented()
    }
  }
}
```

### Pushing events from Android to Dart (EventChannel)

```kotlin
// Call this when the Core SDK delivers a new display unit
fun onDisplayUnitReceived(unitJson: String) {
  Handler(Looper.getMainLooper()).post {
    eventSink?.success(unitJson)
  }
}
```

---

## iOS Bridge (Swift)

```swift
// ios/Classes/CleverTapNativeDisplayPlugin.swift

public class CleverTapNativeDisplayPlugin: NSObject, FlutterPlugin {
  private var eventSink: FlutterEventSink?

  public static func register(with registrar: FlutterPluginRegistrar) {
    let methodChannel = FlutterMethodChannel(
      name: "com.clevertap.flutter/native_display",
      binaryMessenger: registrar.messenger()
    )
    let eventChannel = FlutterEventChannel(
      name: "com.clevertap.flutter/native_display_events",
      binaryMessenger: registrar.messenger()
    )
    let instance = CleverTapNativeDisplayPlugin()
    registrar.addMethodCallDelegate(instance, channel: methodChannel)
    eventChannel.setStreamHandler(instance)
  }

  public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
    switch call.method {
    case "getDisplayUnit":
      guard let unitId = call.arguments as? String else {
        result(FlutterError(code: "INVALID_ARG", message: "unitId required", details: nil))
        return
      }
      // CleverTap Core SDK: recordDisplayUnitViewedEventForID
      let unitJson = CleverTap.sharedInstance()?.getDisplayUnit(forID: unitId)
      result(unitJson)

    case "recordViewed":
      guard let unitId = call.arguments as? String else { return result(nil) }
      CleverTap.sharedInstance()?.recordDisplayUnitViewedEvent(forID: unitId)
      result(nil)

    case "recordClicked":
      guard let unitId = call.arguments as? String else { return result(nil) }
      CleverTap.sharedInstance()?.recordDisplayUnitClickedEvent(forID: unitId)
      result(nil)

    case "recordElementClicked":
      guard let args = call.arguments as? [String: Any],
            let unitId = args["unitId"] as? String,
            let elementId = args["elementId"] as? String else { return result(nil) }
      CleverTap.sharedInstance()?.recordDisplayUnitElementClickedEvent(
        forID: unitId,
        elementID: elementId,
        additionalProperties: nil
      )
      result(nil)

    default:
      result(FlutterMethodNotImplemented)
    }
  }
}

// EventChannel stream handler
extension CleverTapNativeDisplayPlugin: FlutterStreamHandler {
  public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
    self.eventSink = events
    return nil
  }
  public func onCancel(withArguments arguments: Any?) -> FlutterError? {
    self.eventSink = nil
    return nil
  }
}

// Push display unit JSON to Flutter
func pushDisplayUnit(json: String) {
  DispatchQueue.main.async {
    self.eventSink?(json)
  }
}
```

---

## Thread Safety

| Platform | Rule |
|----------|------|
| Android | `MethodChannel` handlers run on main thread by default. If Core SDK delivers on a background thread, use `Handler(Looper.getMainLooper()).post { }` to marshal to main thread before calling `result.success()` or `eventSink?.success()`. |
| iOS | `FlutterMethodChannel` callbacks may arrive on any thread. Always dispatch to main: `DispatchQueue.main.async { }` before calling `result()` or `eventSink()`. |

---

## Data Type Mapping

Platform channels serialize automatically via `StandardMessageCodec`:

| Dart | Kotlin | Swift |
|------|--------|-------|
| `String` | `String` | `String` |
| `int` | `Int` / `Long` | `NSNumber(Int)` |
| `double` | `Double` | `NSNumber(Double)` |
| `bool` | `Boolean` | `NSNumber(Bool)` |
| `Map<String, dynamic>` | `HashMap<String, Any>` | `[String: Any]` |
| `List<dynamic>` | `ArrayList<Any>` | `[Any]` |
| `null` | `null` | `nil` |

JSON is sent as a `String` — never as a `Map` — because the Dart-side renderer parses JSON from a string. This avoids double-serialization and keeps the bridge thin.

---

## Pigeon (Future)

For type safety as the bridge grows, consider migrating to **Pigeon**:

```dart
// pigeon/native_display_api.dart
import 'package:pigeon/pigeon.dart';

@HostApi()
abstract class NativeDisplayHostApi {
  @async
  String? getDisplayUnit(String unitId);
  void recordViewed(String unitId);
  void recordClicked(String unitId);
}

@FlutterApi()
abstract class NativeDisplayFlutterApi {
  void onDisplayUnitReceived(String unitJson);
}
```

Pigeon generates type-safe Dart/Kotlin/Swift code, eliminating string-based method dispatch and manual argument casting. Adopt when the bridge has more than ~5 methods.

---

## Core SDK Method Reference

| Platform | Viewed event | Clicked event | Element clicked | Get unit JSON |
|----------|-------------|---------------|-----------------|---------------|
| Android | `pushDisplayUnitViewedEventForID(unitId)` | `pushDisplayUnitClickedEventForID(unitId)` | `pushDisplayUnitElementClickedEventForID(unitId, elementId)` | `getDisplayUnitForId(unitId).toString()` |
| iOS | `recordDisplayUnitViewedEventForID:` | `recordDisplayUnitClickedEventForID:` | `recordDisplayUnitElementClickedEventForID:elementID:additionalProperties:` | `getDisplayUnitForID:` |

Note the asymmetry: Android uses `push*`, iOS uses `record*`. This is intentional Core SDK behavior — see reference memory for context.
