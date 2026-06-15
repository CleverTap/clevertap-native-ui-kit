//
//  ActionAttributionExtras.swift
//  CleverTapNativeDisplay
//
//  Pure helper that turns an `Action` into a flat `[String: Any]` payload that
//  the bridge feeds into Core SDK's element-click attribution path.
//
//  All action entries (including action.metadata which carries BE-injected
//  wzrk_* attribution fields) become Core SDK's additionalProperties dict.
//
//  The BE injects attribution fields such as `wzrk_element_id`, `wzrk_btn_text`,
//  `wzrk_activity_type`, and `wzrk_data` into each action's `metadata` field
//  server-side. The `custom` case already spreads `action.metadata` into the
//  extras dict, so these keys reach Core SDK via `additionalProperties` without
//  a dedicated `elementID:` parameter.
//
//  Per-action `metadata` / `params` / `properties` maps are spread verbatim so
//  the client's own keys land on the event with their original names. A
//  `CustomAction.value` that is a dictionary is treated the same way (entries
//  spread); primitive values land under a single `action_value` key.
//
//  Output keys produced by this helper:
//  - `action_type` — one of `open_url` / `custom` / `navigate` / `event` /
//    `composite`.
//  - `action_key` — the `CustomAction.key` discriminator (e.g. `"kv"` for the
//    BE's KV-bundle shape, `"close"` for the close-action shape).
//  - Action-specific keys scoped with the `action_` prefix (`action_url`,
//    `action_destination`, `action_event_name`, …).
//  - Spread entries from `CustomAction.value` dictionary / metadata / params /
//    properties.
//
//  Key collisions resolve last-write-wins under this order: reserved keys →
//  value entries → metadata entries.
//

import Foundation

enum ActionAttributionExtras {

    static let keyActionType = "action_type"

    static func from(action: Action?) -> [String: Any] {
        var out: [String: Any] = [:]
        if let action = action {
            append(action, into: &out)
        }
        return out
    }

    private static func append(_ action: Action, into out: inout [String: Any]) {
        switch action {
        case .openUrl(let a):
            out[keyActionType] = "open_url"
            out["action_url"] = a.url
            out["action_open_in_browser"] = a.openInBrowser
            if let metadata = a.metadata {
                for (k, v) in metadata { out[k] = v }
            }
        case .custom(let a):
            out[keyActionType] = "custom"
            out["action_key"] = a.key
            if let dict = a.value.value as? [String: Any] {
                // Spread the bundle entries so the dashboard can slice per KV name
                // (e.g. the BE's `{ "type": "custom", "key": "kv", "value": {...} }` shape).
                for (entryKey, raw) in dict {
                    if let s = scalar(fromAny: raw) {
                        out[entryKey] = s
                    }
                }
            } else if let s = scalar(from: a.value) {
                out["action_value"] = s
            }
            if let metadata = a.metadata {
                for (k, v) in metadata { out[k] = v }
            }
        case .navigate(let a):
            out[keyActionType] = "navigate"
            out["action_destination"] = a.destination
            if let params = a.params {
                for (k, v) in params { out[k] = v }
            }
        case .trackEvent(let a):
            out[keyActionType] = "event"
            out["action_event_name"] = a.eventName
            if let properties = a.properties {
                for (k, v) in properties {
                    if let scalar = scalar(from: v) { out[k] = scalar }
                }
            }
        case .composite(let a):
            out[keyActionType] = "composite"
            out["action_count"] = a.actions.count
            out["action_mode"] = a.executionMode.rawValue
        }
    }

    /// Reduce an `AnyCodable` value to a Core-SDK-compatible scalar.
    /// Scalars (string/number/bool) round-trip as their native type; objects/arrays are
    /// serialized to a compact JSON string so the payload remains analytics-friendly.
    private static func scalar(from anyCodable: AnyCodable) -> Any? {
        return scalar(fromAny: anyCodable.value)
    }

    /// Same coercion as `scalar(from:)` but starting from a raw `Any` — used when spreading
    /// the already-unwrapped entries of an `AnyCodable`-wrapped dictionary.
    private static func scalar(fromAny v: Any) -> Any? {
        if v is Void { return nil }
        if v is NSNull { return nil }
        if let s = v as? String { return s }
        if let b = v as? Bool { return b }
        if let i = v as? Int { return i }
        if let d = v as? Double { return d }
        if let n = v as? NSNumber { return n }
        if let data = try? JSONSerialization.data(withJSONObject: unwrap(v), options: []),
           let s = String(data: data, encoding: .utf8) {
            return s
        }
        return String(describing: v)
    }

    /// Unwrap nested AnyCodable values inside arrays/dictionaries so JSONSerialization
    /// can produce a clean JSON string.
    private static func unwrap(_ value: Any) -> Any {
        if let arr = value as? [Any] { return arr.map { unwrap(($0 as? AnyCodable)?.value ?? $0) } }
        if let dict = value as? [String: Any] {
            return dict.mapValues { unwrap(($0 as? AnyCodable)?.value ?? $0) }
        }
        return value
    }

    /// Strip keys whose values are not Core-SDK-friendly before handing the dict to the
    /// reflective call. Keeps strings/numbers/bools/NSNumber and drops Void/nil entries.
    static func sanitize(_ extras: [String: Any]?) -> [String: Any]? {
        guard let extras = extras, !extras.isEmpty else { return nil }
        var out: [String: Any] = [:]
        for (k, v) in extras where !k.isEmpty {
            if v is Void { continue }
            if v is String || v is NSNumber || v is Bool || v is Int || v is Double || v is Float {
                out[k] = v
            } else if let arr = v as? [Any] {
                out[k] = arr
            } else if let dict = v as? [String: Any] {
                out[k] = dict
            } else {
                out[k] = String(describing: v)
            }
        }
        return out.isEmpty ? nil : out
    }
}
