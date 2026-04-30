//
//  NativeDisplayUnitCacheImpl.swift
//  CleverTapNativeDisplay
//

// MARK: - Display Unit Cache Adapter
// Bridges Core SDK's CleverTapDisplayUnitCache protocol (v7.x+) to the
// NativeDisplayBridge's existing cache. Core SDK calls this object for all
// display-unit lookups (`getDisplayUnitForID:`, `getAllDisplayUnits`) and
// server-driven updates (`updateDisplayUnits:`). Lookups consult the bridge;
// `updateDisplayUnits:` routes server payloads back into the bridge's parser
// so existing NativeDisplayBridgeListener consumers still fire once.
//
// No compile-time dependency on CleverTap Core SDK — protocol conformance is
// adopted at runtime via `objc_getProtocol` + `class_addProtocol`, and
// CleverTapDisplayUnit instances are constructed via `NSClassFromString` +
// `performSelector(initWithJSON:)`.

import Foundation
import ObjectiveC

/// Implements (at runtime) Core SDK's `CleverTapDisplayUnitCache` protocol.
/// Selector signatures match those declared in the protocol so Core SDK can
/// invoke us via `id<CleverTapDisplayUnitCache>` references.
@objc final class NativeDisplayUnitCacheImpl: NSObject {

    private weak var bridge: NativeDisplayBridge?

    /// Stable identity used by the bridge to detect whether the cache is
    /// installed. Core SDK keeps a strong reference; we keep one too via
    /// `CleverTapAutoWire.activeCache` for symmetry.
    init(bridge: NativeDisplayBridge) {
        self.bridge = bridge
        super.init()
    }

    // MARK: - Protocol Adoption

    private static var protocolAdopted = false

    /// Dynamically conform to `CleverTapDisplayUnitCache`. Core SDK's setter is
    /// declared as `id<CleverTapDisplayUnitCache>` — Objective-C dispatch
    /// doesn't enforce conformance at the call site, but adopting defensively
    /// makes `conformsToProtocol:` return YES if anyone checks.
    static func adoptProtocolIfNeeded() {
        guard !protocolAdopted else { return }
        if let proto = objc_getProtocol("CleverTapDisplayUnitCache") {
            class_addProtocol(NativeDisplayUnitCacheImpl.self, proto)
            protocolAdopted = true
        }
    }

    // MARK: - CleverTapDisplayUnitCache (selector-matched)

    @objc(getDisplayUnitForID:)
    func getDisplayUnitForID(_ unitID: String) -> NSObject? {
        guard let unit = bridge?.getNativeDisplayForId(unitID) else { return nil }
        return makeCleverTapDisplayUnit(rawJson: unit.rawJson)
    }

    @objc(getAllDisplayUnits)
    func getAllDisplayUnits() -> NSArray {
        let units = (bridge?.getAllNativeDisplays() ?? [])
            .compactMap { makeCleverTapDisplayUnit(rawJson: $0.rawJson) }
        return units as NSArray
    }

    @objc(updateDisplayUnits:)
    func updateDisplayUnits(_ displayUnits: NSArray?) {
        guard let dicts = displayUnits as? [[String: Any]], !dicts.isEmpty else { return }
        let jsonStrings: [String] = dicts.compactMap { dict in
            guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
            return String(data: data, encoding: .utf8)
        }
        if !jsonStrings.isEmpty {
            bridge?.processDisplayUnits(jsonStrings)
        }
    }

    @objc(reset)
    func reset() {
        bridge?.clear()
    }

    // MARK: - Helpers

    private func makeCleverTapDisplayUnit(rawJson: String?) -> NSObject? {
        guard let raw = rawJson,
              let data = raw.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return nil }
        return Self.instantiateCleverTapDisplayUnit(with: dict)
    }

    /// Allocates and `initWithJSON:`-initializes a `CleverTapDisplayUnit`
    /// instance dynamically. Swift hides `+alloc`, so we go through
    /// `performSelector("alloc")` instead.
    static func instantiateCleverTapDisplayUnit(with dict: [String: Any]) -> NSObject? {
        guard let cls = NSClassFromString("CleverTapDisplayUnit") as? NSObject.Type else { return nil }
        guard let allocated = cls.perform(NSSelectorFromString("alloc"))?.takeUnretainedValue() as? NSObject else {
            return nil
        }
        let initSelector = NSSelectorFromString("initWithJSON:")
        guard let unmanaged = allocated.perform(initSelector, with: dict) else { return nil }
        return unmanaged.takeUnretainedValue() as? NSObject
    }
}
