//
//  ActionAttributionExtras.swift
//  CleverTapNativeDisplay
//
//  Pure helper that turns an `Action` (and the originating node id) into a flat
//  `[String: Any]` payload suitable for the additional-properties parameter of
//  CleverTap Core SDK's `-[CleverTap recordDisplayUnitClickedEventForID:additionalProperties:]`
//  / `-[CleverTap recordDisplayUnitViewedEventForID:additionalProperties:]` selectors.
//
//  The output is intentionally flat and JSON-friendly — Core SDK's event pipeline expects
//  scalar values (`String` / `NSNumber`). Nested objects/arrays from `CustomAction.value`
//  are JSON-serialized into a string so attribution dashboards receive a complete record
//  of what the button did rather than dropping structured payloads on the floor.
//
//  Reserved keys produced by this helper:
//  - `wzrk_btn_id` — the node id of the clicked component (matches Core SDK push-notification
//    convention for button identification).
//  - `wzrk_action_type` — one of `open_url` / `custom` / `navigate` / `event` / `composite`.
//
//  Action-specific keys are scoped with the `action_` prefix to avoid collisions with the
//  Core SDK's own `wzrk_*` enrichment. Per-action `metadata` / `params` / `properties` maps
//  are spread verbatim so the client's own keys land on the event with their original names.
//

import Foundation

enum ActionAttributionExtras {

    static let keyButtonId = "wzrk_btn_id"
    static let keyActionType = "wzrk_action_type"

    static func from(action: Action?, nodeId: String?) -> [String: Any] {
        var out: [String: Any] = [:]
        if let nodeId = nodeId, !nodeId.isEmpty {
            out[keyButtonId] = nodeId
        }
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
        case .custom(let a):
            out[keyActionType] = "custom"
            out["action_key"] = a.key
            if let scalar = scalar(from: a.value) {
                out["action_value"] = scalar
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
        let v = anyCodable.value
        if v is Void { return nil }
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
