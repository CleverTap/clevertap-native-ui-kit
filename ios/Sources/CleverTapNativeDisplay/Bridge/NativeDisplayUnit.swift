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
///
/// This is a reference type (`@objc` class) so it can flow through the `@objc`
/// `NativeDisplayBridgeListener` / `NativeDisplaySlotObserver` callbacks and be
/// consumed from Objective-C. `config` and `resolvedStyles` carry Swift-only
/// value types, so they stay non-`@objc` (the SDK renders them internally; Obj-C
/// callers pass the unit straight to a view initializer).
@objc public final class NativeDisplayUnit: NSObject {
    /// Unique identifier for this display unit (maps to `wzrk_id` in the JSON payload).
    @objc public let unitId: String

    /// The resolved configuration ready for rendering with `NativeDisplayView`.
    /// Swift-only — `ResolvedConfig` is a value type not representable in Obj-C.
    public let config: ResolvedConfig

    /// Slot identifier from the top-level `slot_id` key in the display unit JSON,
    /// or `nil` when the unit is not bound to a placement slot.
    @objc public let slotId: String?

    /// Custom key-value pairs extracted from the `custom_kv` field in the display unit JSON.
    @objc public let customExtras: [String: String]

    /// The original raw JSON string, retained for debugging or re-serialization.
    @objc public let rawJson: String?

    /// Pre-resolved per-node styles produced at parse time, off the main thread.
    /// When non-nil, `NativeDisplayView` skips the on-main `StyleResolver.resolveAll`
    /// walk and uses this dictionary directly. Keyed by `NativeDisplayNode.id`.
    /// Swift-only — `Style` is a value type not representable in Obj-C.
    public let resolvedStyles: [String: Style]?

    public init(
        unitId: String,
        config: ResolvedConfig,
        slotId: String? = nil,
        customExtras: [String: String] = [:],
        rawJson: String? = nil,
        resolvedStyles: [String: Style]? = nil
    ) {
        self.unitId = unitId
        self.config = config
        self.slotId = slotId
        self.customExtras = customExtras
        self.rawJson = rawJson
        self.resolvedStyles = resolvedStyles
        super.init()
    }
}
