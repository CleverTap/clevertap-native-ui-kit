//
//  NativeDisplayConfigParser.swift
//  CleverTapNativeDisplay
//

// MARK: - Config Parser
// Parses raw display unit JSON and extracts Native Display configurations

import Foundation

/// Parses raw JSON strings (from CleverTap Core SDK display units or other sources)
/// and extracts Native Display configurations.
///
/// Detection strategy (in order):
/// 1. `native_display_config` top-level key -> parse its value as `ResolvedConfig`
/// 2. `custom_kv.nd_config` string value -> parse as `ResolvedConfig`
/// 3. `root` top-level key present -> treat entire JSON as ND config
///
/// Returns `nil` if the JSON is not a Native Display unit or parsing fails.
internal class NativeDisplayConfigParser {

    // MARK: - Public API

    /// Attempt to parse a raw JSON string into a `NativeDisplayUnit`.
    /// - Parameter jsonString: Raw JSON string from a display unit payload.
    /// - Returns: A `NativeDisplayUnit` if parsing succeeds, `nil` otherwise.
    func tryParse(_ jsonString: String) -> NativeDisplayUnit? {
        guard let data = jsonString.data(using: .utf8) else {
            print("[NativeDisplayBridge] Failed to convert JSON string to Data")
            return nil
        }
        return tryParse(data: data, rawJson: jsonString)
    }

    /// Attempt to parse raw JSON data into a `NativeDisplayUnit`.
    /// - Parameters:
    ///   - data: Raw JSON data from a display unit payload.
    ///   - rawJson: Optional original JSON string for retention in the unit.
    /// - Returns: A `NativeDisplayUnit` if parsing succeeds, `nil` otherwise.
    func tryParse(data: Data, rawJson: String? = nil) -> NativeDisplayUnit? {
        guard let jsonObject = try? JSONSerialization.jsonObject(with: data) as? [String: Any] else {
            print("[NativeDisplayBridge] Failed to deserialize JSON")
            return nil
        }

        // Extract unit ID (required)
        guard let unitId = jsonObject["wzrk_id"] as? String else {
            print("[NativeDisplayBridge] Missing wzrk_id in display unit JSON")
            return nil
        }

        // Extract custom extras
        let customExtras = extractCustomExtras(from: jsonObject)

        // Retain raw JSON string
        let rawJsonString = rawJson ?? String(data: data, encoding: .utf8)

        // Strategy 1: Look for "native_display_config" key
        if let config = tryParseNativeDisplayConfig(from: jsonObject) {
            return NativeDisplayUnit(
                unitId: unitId,
                config: config,
                customExtras: customExtras,
                rawJson: rawJsonString
            )
        }

        // Strategy 2: Look for "custom_kv.nd_config" string
        if let config = tryParseFromCustomKV(from: jsonObject) {
            return NativeDisplayUnit(
                unitId: unitId,
                config: config,
                customExtras: customExtras,
                rawJson: rawJsonString
            )
        }

        // Strategy 3: Look for "root" key — treat entire JSON as ND config
        if let config = tryParseAsDirectConfig(from: jsonObject, data: data) {
            return NativeDisplayUnit(
                unitId: unitId,
                config: config,
                customExtras: customExtras,
                rawJson: rawJsonString
            )
        }

        print("[NativeDisplayBridge] JSON does not contain a Native Display config (unitId: \(unitId))")
        return nil
    }

    // MARK: - Private Parsing Strategies

    /// Strategy 1: Parse `native_display_config` top-level key.
    private func tryParseNativeDisplayConfig(from jsonObject: [String: Any]) -> ResolvedConfig? {
        guard let ndConfigObj = jsonObject["native_display_config"] else {
            return nil
        }

        do {
            let ndConfigData = try JSONSerialization.data(withJSONObject: ndConfigObj)
            let config = try ResolvedConfig.from(jsonData: ndConfigData)
            return config
        } catch {
            print("[NativeDisplayBridge] Failed to parse native_display_config: \(error.localizedDescription)")
            return nil
        }
    }

    /// Strategy 2: Parse `custom_kv.nd_config` string value.
    private func tryParseFromCustomKV(from jsonObject: [String: Any]) -> ResolvedConfig? {
        guard let customKV = jsonObject["custom_kv"] as? [String: Any],
              let ndConfigString = customKV["nd_config"] as? String else {
            return nil
        }

        do {
            let config = try ResolvedConfig.from(jsonString: ndConfigString)
            return config
        } catch {
            print("[NativeDisplayBridge] Failed to parse custom_kv.nd_config: \(error.localizedDescription)")
            return nil
        }
    }

    /// Strategy 3: Check for `root` key and treat entire JSON as ND config.
    private func tryParseAsDirectConfig(from jsonObject: [String: Any], data: Data) -> ResolvedConfig? {
        guard jsonObject["root"] != nil else {
            return nil
        }

        do {
            let config = try ResolvedConfig.from(jsonData: data)
            return config
        } catch {
            print("[NativeDisplayBridge] Failed to parse JSON as direct ND config: \(error.localizedDescription)")
            return nil
        }
    }

    // MARK: - Helpers

    /// Extract custom key-value pairs from the `custom_kv` field.
    private func extractCustomExtras(from jsonObject: [String: Any]) -> [String: String] {
        guard let customKV = jsonObject["custom_kv"] as? [String: Any] else {
            return [:]
        }

        var extras: [String: String] = [:]
        for (key, value) in customKV {
            // Skip the nd_config key — that's an internal config field, not a custom extra
            if key == "nd_config" { continue }
            if let stringValue = value as? String {
                extras[key] = stringValue
            } else if let numberValue = value as? NSNumber {
                extras[key] = numberValue.stringValue
            }
        }
        return extras
    }
}
