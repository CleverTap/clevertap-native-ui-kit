//
//  NativeDisplaySlotManager.swift
//  CleverTapNativeDisplay
//
//  Slot-based placement system for Native Display units.
//  Routes units to registered slots based on the top-level `slot_id` field
//  exposed by `NativeDisplayUnit.slotId`.
//

import Foundation

// MARK: - Slot Observer Protocol

/// Protocol for observing slot-level unit availability.
///
/// Implement this to receive callbacks when a display unit becomes available
/// or is cleared for a specific slot. Observers are held weakly by the
/// `NativeDisplaySlotManager` — no need to unregister on deallocation,
/// though explicit unregistration is recommended for deterministic cleanup.
public protocol NativeDisplaySlotObserver: AnyObject {
    /// Called when a display unit becomes available for the observed slot.
    /// - Parameter unit: The native display unit ready for rendering.
    func onUnitAvailable(_ unit: NativeDisplayUnit)

    /// Called when the display unit for the observed slot is cleared.
    /// - Parameter slotId: The slot identifier that was cleared.
    func onUnitCleared(slotId: String)
}

// MARK: - Slot Manager

/// Singleton manager that routes `NativeDisplayUnit` instances to registered slots.
///
/// Units are matched to slots via `NativeDisplayUnit.slotId`, which the parser populates
/// from the top-level `slot_id` key on the display-unit JSON.
/// The manager listens to the bridge for incoming units and maintains a latest-unit-per-slot
/// index so that late-registering observers receive the current unit immediately.
///
/// ## Usage
///
/// ```swift
/// // Register a slot observer
/// NativeDisplaySlotManager.shared.registerSlot("hero_banner", observer: self)
///
/// // Later, unregister
/// NativeDisplaySlotManager.shared.unregisterSlot("hero_banner", observer: self)
///
/// // Query active slots
/// let activeSlots = NativeDisplaySlotManager.shared.getActiveSlotIds()
///
/// // Sync slot IDs to server
/// NativeDisplaySlotManager.shared.syncCurrentSlotIds(cleverTapInstance)
/// ```
public class NativeDisplaySlotManager: NativeDisplayBridgeListener {

    /// Shared singleton instance.
    public static let shared = NativeDisplaySlotManager()

    // MARK: - Private State

    /// Registry of slot observers. Key is slotId, value is weak set of observers.
    private var slotRegistry: [String: NSHashTable<AnyObject>] = [:]

    /// Latest unit per slotId for immediate delivery to late registrants.
    private var unitIndex: [String: NativeDisplayUnit] = [:]

    /// Thread-safety lock for all mutable state.
    private let lock = NSLock()

    /// Event name for slot sync requests.
    static let wzrkSlotSync = "wzrk_nd_slot_sync"

    // MARK: - Init

    private init() {
        NativeDisplayBridge.shared.addListener(self)
    }

    // MARK: - Bridge Listener

    /// Called by the bridge when display units are loaded or updated.
    /// Reads `slotId` from each unit, updates the index, and notifies matching observers.
    public func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        NDLogger.d(Self.self, "onNativeDisplaysLoaded: \(units.count) unit(s) received")
        lock.lock()

        // Build a map of slotId -> unit for this batch, and collect observers to notify
        var notifications: [(NativeDisplaySlotObserver, NativeDisplayUnit)] = []

        for unit in units {
            guard let slotId = unit.slotId, !slotId.isEmpty else {
                NDLogger.v(Self.self, "Unit '\(unit.unitId)' has no slotId, skipping slot routing")
                continue
            }

            unitIndex[slotId] = unit
            NDLogger.d(Self.self, "Slot '\(slotId)' updated with unit '\(unit.unitId)'")

            if let observers = slotRegistry[slotId] {
                let activeObservers = observers.allObjects.compactMap { $0 as? NativeDisplaySlotObserver }
                for observer in activeObservers {
                    notifications.append((observer, unit))
                }
            }
        }

        lock.unlock()

        // Notify on main thread
        if !notifications.isEmpty {
            DispatchQueue.main.async {
                for (observer, unit) in notifications {
                    observer.onUnitAvailable(unit)
                }
            }
        }
    }

    // MARK: - Registration

    /// Register an observer for a specific slot.
    ///
    /// If a unit is already available for the given slot, the observer receives
    /// an immediate `onUnitAvailable` callback on the main thread.
    ///
    /// - Parameters:
    ///   - slotId: The slot identifier to observe.
    ///   - observer: The observer to register (held weakly).
    public func registerSlot(_ slotId: String, observer: NativeDisplaySlotObserver) {
        NDLogger.d(Self.self, "Registering observer for slot '\(slotId)'")
        lock.lock()

        let table: NSHashTable<AnyObject>
        if let existing = slotRegistry[slotId] {
            table = existing
        } else {
            table = NSHashTable<AnyObject>.weakObjects()
            slotRegistry[slotId] = table
        }
        table.add(observer)

        let existingUnit = unitIndex[slotId]
        lock.unlock()

        // Deliver existing unit immediately if available
        if let unit = existingUnit {
            NDLogger.d(Self.self, "Slot '\(slotId)': delivering cached unit '\(unit.unitId)' immediately to new observer")
            DispatchQueue.main.async {
                observer.onUnitAvailable(unit)
            }
        }
    }

    /// Unregister an observer from a specific slot.
    ///
    /// - Parameters:
    ///   - slotId: The slot identifier to stop observing.
    ///   - observer: The observer to remove.
    public func unregisterSlot(_ slotId: String, observer: NativeDisplaySlotObserver) {
        NDLogger.d(Self.self, "Unregistering observer for slot '\(slotId)'")
        lock.lock()
        defer { lock.unlock() }

        slotRegistry[slotId]?.remove(observer)

        // Clean up empty tables
        if let table = slotRegistry[slotId], table.count == 0 {
            slotRegistry.removeValue(forKey: slotId)
            NDLogger.d(Self.self, "Slot '\(slotId)' has no remaining observers — removed from registry")
        }
    }

    // MARK: - Query

    /// Returns the set of slot IDs that currently have at least one registered observer.
    public func getActiveSlotIds() -> Set<String> {
        lock.lock()
        defer { lock.unlock() }

        var activeIds = Set<String>()
        for (slotId, table) in slotRegistry {
            if table.count > 0 {
                activeIds.insert(slotId)
            }
        }
        return activeIds
    }

    /// Returns the currently indexed unit for a given slot, if any.
    ///
    /// - Parameter slotId: The slot identifier to look up.
    /// - Returns: The latest `NativeDisplayUnit` for the slot, or `nil`.
    public func getUnit(forSlot slotId: String) -> NativeDisplayUnit? {
        lock.lock()
        defer { lock.unlock() }
        return unitIndex[slotId]
    }

    // MARK: - Server Sync

    /// Send the current set of active slot IDs to the server via the CleverTap instance.
    ///
    /// Records a `wzrk_nd_slot_sync` event with a `slot_ids` property containing
    /// the comma-separated list of active slot identifiers.
    ///
    /// - Parameter cleverTap: A `CleverTap` instance (passed as `Any?` to avoid compile dependency).
    /// - Returns: `true` if the event was sent, `false` otherwise.
    @discardableResult
    public func syncCurrentSlotIds(_ cleverTap: Any?) -> Bool {
        guard let ct = cleverTap as? NSObject else {
            NDLogger.w(Self.self, "syncCurrentSlotIds() called with nil or non-NSObject")
            return false
        }

        let recordEventSelector = NSSelectorFromString("recordEvent:withProps:")
        guard ct.responds(to: recordEventSelector) else {
            NDLogger.w(Self.self, "CleverTap instance does not support recordEvent:withProps:")
            return false
        }

        let activeSlots = getActiveSlotIds()
        let props: [String: Any] = ["slot_ids": activeSlots.sorted().joined(separator: ",")]
        ct.perform(recordEventSelector, with: NativeDisplaySlotManager.wzrkSlotSync, with: props)

        NDLogger.d(Self.self, "Synced \(activeSlots.count) active slot IDs to server")
        return true
    }

    // MARK: - Clear

    /// Clear a specific slot's cached unit and notify observers.
    ///
    /// - Parameter slotId: The slot identifier to clear.
    public func clearSlot(_ slotId: String) {
        NDLogger.d(Self.self, "Clearing slot '\(slotId)'")
        lock.lock()

        unitIndex.removeValue(forKey: slotId)

        let observers: [NativeDisplaySlotObserver]
        if let table = slotRegistry[slotId] {
            observers = table.allObjects.compactMap { $0 as? NativeDisplaySlotObserver }
        } else {
            observers = []
        }

        lock.unlock()

        if !observers.isEmpty {
            DispatchQueue.main.async {
                for observer in observers {
                    observer.onUnitCleared(slotId: slotId)
                }
            }
        }
    }

    /// Clear all cached units and notify all observers.
    public func clearAll() {
        NDLogger.d(Self.self, "Clearing all slots")
        lock.lock()

        let allSlotIds = Array(unitIndex.keys)
        unitIndex.removeAll()

        var notifications: [(NativeDisplaySlotObserver, String)] = []
        for slotId in allSlotIds {
            if let table = slotRegistry[slotId] {
                let observers = table.allObjects.compactMap { $0 as? NativeDisplaySlotObserver }
                for observer in observers {
                    notifications.append((observer, slotId))
                }
            }
        }

        lock.unlock()

        if !notifications.isEmpty {
            DispatchQueue.main.async {
                for (observer, slotId) in notifications {
                    observer.onUnitCleared(slotId: slotId)
                }
            }
        }
    }
}
