//
//  NativeDisplayUnitCacheImpl.swift
//  CleverTapNativeDisplay
//

// MARK: - Native Display Unit Cache
// Owns the in-memory store of NativeDisplayUnits for the bridge AND adopts
// Core SDK's CleverTapDisplayUnitCache protocol at runtime so that
// `recordDisplayUnit*EventForID:` lookups resolve through the same data.
// Single source of truth — no duplicate storage between this class and
// NativeDisplayBridge.
//
// No compile-time dependency on CleverTap Core SDK — protocol conformance is
// adopted at runtime via `objc_getProtocol` + `class_addProtocol`, and
// CleverTapDisplayUnit instances are constructed via `NSClassFromString` +
// `performSelector(initWithJSON:)`.

import Foundation
import ObjectiveC

/// Adopts (at runtime) Core SDK's `CleverTapDisplayUnitCache` protocol.
/// Selector signatures match the protocol so Core SDK can invoke us via
/// `id<CleverTapDisplayUnitCache>` references.
@objc final class NativeDisplayUnitCacheImpl: NSObject {

    // MARK: - State

    private var cache: [String: NativeDisplayUnit] = [:]
    private let lock = NSLock()

    /// Bridge-supplied callback for server-driven `updateDisplayUnits:` calls.
    /// Set by the bridge during construction; the closure parses, replaces
    /// cache contents (via `replaceAll`) and notifies bridge listeners.
    var onServerUpdate: ((NSArray) -> Void)?

    // MARK: - Bridge-facing storage primitives

    func replaceAll(_ units: [NativeDisplayUnit]) {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll(keepingCapacity: true)
        for unit in units { cache[unit.unitId] = unit }
    }

    func put(_ unit: NativeDisplayUnit) {
        lock.lock(); defer { lock.unlock() }
        cache[unit.unitId] = unit
    }

    func get(_ unitId: String) -> NativeDisplayUnit? {
        lock.lock(); defer { lock.unlock() }
        return cache[unitId]
    }

    func getAll() -> [NativeDisplayUnit] {
        lock.lock(); defer { lock.unlock() }
        return Array(cache.values)
    }

    func clearStorage() {
        lock.lock(); defer { lock.unlock() }
        cache.removeAll(keepingCapacity: true)
    }

    var count: Int {
        lock.lock(); defer { lock.unlock() }
        return cache.count
    }

    // MARK: - Protocol Adoption

    private static var protocolAdopted = false

    /// Dynamically conform to `CleverTapDisplayUnitCache`. Core SDK's setter
    /// is `id<CleverTapDisplayUnitCache>`; Objective-C dispatch doesn't
    /// enforce conformance at the call site, but adopting defensively makes
    /// `conformsToProtocol:` return YES if anyone checks.
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
        guard let unit = get(unitID) else { return nil }
        return makeCleverTapDisplayUnit(rawJson: unit.rawJson)
    }

    @objc(getAllDisplayUnits)
    func getAllDisplayUnits() -> NSArray {
        let units = getAll().compactMap { makeCleverTapDisplayUnit(rawJson: $0.rawJson) }
        return units as NSArray
    }

    @objc(updateDisplayUnits:)
    func updateDisplayUnits(_ displayUnits: NSArray?) {
        guard let arr = displayUnits else { return }
        // Bridge handles parsing + listener notify; bridge calls back via
        // `replaceAll` so the storage write goes through this same instance.
        onServerUpdate?(arr)
    }

    @objc(reset)
    func reset() {
        clearStorage()
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
