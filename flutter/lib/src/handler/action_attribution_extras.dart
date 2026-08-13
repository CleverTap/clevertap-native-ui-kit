import 'dart:convert';

import '../internal/nd_sdk_version.dart';
import '../models/action.dart';
import '../models/enums.dart';

/// Pure helper that turns an [NDAction] into a flat map of key/value pairs that
/// the bridge feeds into Core SDK's element-click attribution path via
/// `additionalProperties`.
///
/// All action entries (including `metadata`, which carries BE-injected `wzrk_*`
/// attribution fields) become Core SDK's additionalProperties map.
///
/// The BE injects attribution fields such as `wzrk_element_id`, `wzrk_c2a`,
/// `wzrk_act`, and `wzrk_data` into each action's `metadata` field server-side.
/// The [CustomAction] / [OpenUrlAction] cases spread `metadata` into the extras
/// map, so those keys reach Core SDK verbatim. The client never injects `wzrk_*`
/// keys itself — that namespace is server-owned (Core SDK strips client-supplied
/// `wzrk_*` keys from additionalProperties).
///
/// Per-action `metadata` / `params` / `properties` maps are spread verbatim so
/// the client's own keys land on the event with their original names. A
/// [CustomAction] `value` that is a JSON object is treated the same way (entries
/// spread); primitive values land under a single `action_value` key.
///
/// Output keys produced by this helper:
/// - `action_type` — one of `open_url` / `custom` / `navigate` / `event` /
///   `composite`.
/// - `action_key` — the [CustomAction.key] discriminator.
/// - Action-specific keys scoped with the `action_` prefix (`action_url`,
///   `action_destination`, `action_event_name`, …).
/// - Spread entries from [CustomAction] `value` map / metadata / params /
///   properties.
///
/// Key collisions resolve last-write-wins under this order: reserved keys →
/// value entries → metadata entries.
///
/// Mirrors Android's `ActionAttributionExtras` (Kotlin) and iOS's
/// `ActionAttributionExtras` (Swift) key-for-key.
abstract final class ActionAttributionExtras {
  static const String _keyActionType = 'action_type';

  // ND SDK version attribution — stamped on every clicked event so the server
  // can identify which ND SDK build produced the analytics. Non-`wzrk_`
  // namespace because `wzrk_*` is owned by the Core SDK / BE enrichment path.
  static const String _keyNdLibVersionName = 'nd_lib_v_name';
  static const String _keyNdLibVersionCode = 'nd_lib_v_code';

  /// Flatten [action] into a raw extras map. Returns an empty map for null.
  static Map<String, Object?> from(NDAction? action) {
    final out = <String, Object?>{};
    if (action != null) _appendAction(action, out);
    return out;
  }

  static void _appendAction(NDAction action, Map<String, Object?> out) {
    switch (action) {
      case OpenUrlAction a:
        out[_keyActionType] = 'open_url';
        out['action_url'] = a.url;
        out['action_open_in_browser'] = a.openInBrowser;
        a.metadata?.forEach((k, v) => out[k] = v);
      case CustomAction a:
        out[_keyActionType] = 'custom';
        out['action_key'] = a.key;
        final value = a.value;
        if (value is Map) {
          // Spread the bundle entries so the dashboard can slice per KV name
          // (e.g. the BE's `{ "type": "custom", "key": "kv", "value": {...} }`).
          value.forEach((k, v) => out[k.toString()] = _toScalar(v));
        } else if (value != null) {
          out['action_value'] = _toScalar(value);
        }
        a.metadata?.forEach((k, v) => out[k] = v);
      case NavigateAction a:
        out[_keyActionType] = 'navigate';
        out['action_destination'] = a.destination;
        a.params?.forEach((k, v) => out[k] = v);
      case TrackEventAction a:
        out[_keyActionType] = 'event';
        out['action_event_name'] = a.eventName;
        a.properties?.forEach((k, v) => out[k] = _toScalar(v));
      case CompositeAction a:
        out[_keyActionType] = 'composite';
        out['action_count'] = a.actions.length;
        out['action_mode'] = switch (a.executionMode) {
          ExecutionMode.sequential => 'sequential',
          ExecutionMode.parallel => 'parallel',
        };
    }
  }

  /// Reduce a decoded-JSON value to a Core-SDK-compatible scalar.
  /// Scalars (String/num/bool) round-trip as their native type; objects/arrays
  /// are serialized to a compact JSON string so the payload stays analytics
  /// friendly.
  static Object? _toScalar(Object? value) {
    if (value == null) return null;
    if (value is String || value is num || value is bool) return value;
    return jsonEncode(value);
  }

  /// Strip keys whose values are not Core-SDK-friendly (`null`, empty keys)
  /// before handing the map to the platform channel, then stamp the ND SDK
  /// version. Always returns a non-empty map — the version stamp is attached to
  /// every payload so the server can attribute the click to a specific build.
  static Map<String, Object> sanitize(Map<String, Object?>? extras) {
    final out = <String, Object>{};
    if (extras != null) {
      extras.forEach((k, v) {
        if (k.isEmpty || v == null) return;
        out[k] = v;
      });
    }
    // Caller-supplied keys win — only set the version stamp if absent.
    out.putIfAbsent(_keyNdLibVersionName, () => NDSdkVersion.name);
    out.putIfAbsent(_keyNdLibVersionCode, () => NDSdkVersion.code);
    return out;
  }

  /// Standalone ND SDK version stamp used by event paths that carry no other
  /// extras. The clicked-event path stamps the same keys inside [sanitize].
  static Map<String, Object> versionStamp() => {
        _keyNdLibVersionName: NDSdkVersion.name,
        _keyNdLibVersionCode: NDSdkVersion.code,
      };
}
