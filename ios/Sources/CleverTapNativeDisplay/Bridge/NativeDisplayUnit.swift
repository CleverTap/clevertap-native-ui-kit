//
//  NativeDisplayUnit.swift
//  CleverTapNativeDisplay
//

// MARK: - Native Display Unit
// Represents a single native display unit delivered via the bridge

import Foundation

/// A native display unit containing a parsed configuration and metadata.
/// Created by the bridge when processing display unit JSON from CleverTap Core SDK
/// or from manual JSON input.
public struct NativeDisplayUnit {
    /// Unique identifier for this display unit (maps to `wzrk_id` in the JSON payload).
    public let unitId: String

    /// The resolved configuration ready for rendering with `NativeDisplayView`.
    public let config: ResolvedConfig

    /// Slot identifier from the top-level `slot_id` key in the display unit JSON,
    /// or `nil` when the unit is not bound to a placement slot.
    public let slotId: String?

    /// Custom key-value pairs extracted from the `custom_kv` field in the display unit JSON.
    public let customExtras: [String: String]

    /// The original raw JSON string, retained for debugging or re-serialization.
    public let rawJson: String?

    public init(
        unitId: String,
        config: ResolvedConfig,
        slotId: String? = nil,
        customExtras: [String: String] = [:],
        rawJson: String? = nil
    ) {
        self.unitId = unitId
        self.config = config
        self.slotId = slotId
        self.customExtras = customExtras
        self.rawJson = rawJson
    }
}
