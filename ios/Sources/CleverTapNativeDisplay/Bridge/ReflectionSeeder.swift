//
//  ReflectionSeeder.swift
//  CleverTapNativeDisplay
//

// MARK: - Older Core SDK Fallback
// Used when -[CleverTap setDisplayUnitCache:] is not available on the host's
// Core SDK version. Reaches the existing CTDisplayUnitController via KVC and
// merges the supplied units into its `displayUnits` array so that the
// mandatory cache lookup inside `recordDisplayUnit*EventForID:` succeeds.
//
// Failures are logged once per process and propagated as `false` so callers
// can fall through to a callback-only path.

import Foundation
import ObjectiveC

enum ReflectionSeeder {

    private static var loggedFailure = false

    /// Merges the supplied units into Core SDK's display-unit cache.
    ///
    /// - Parameters:
    ///   - cleverTapInstance: the live CleverTap instance.
    ///   - unitDicts: dictionary representations of `CleverTapDisplayUnit`s
    ///     (typically from `NativeDisplayUnit.rawJson`).
    /// - Returns: `true` if at least one unit was added; `false` on failure.
    @discardableResult
    static func seed(cleverTapInstance: NSObject, unitDicts: [[String: Any]]) -> Bool {
        guard !unitDicts.isEmpty else { return false }
        guard let controller = cleverTapInstance.value(forKey: "displayUnitController") as? NSObject else {
            return logOnce("displayUnitController not reachable via KVC")
        }
        guard NSClassFromString("CleverTapDisplayUnit") is NSObject.Type else {
            return logOnce("CleverTapDisplayUnit class not available")
        }

        let unitIDKey = "unitID"

        var byID: [String: NSObject] = [:]
        if let existing = controller.value(forKey: "displayUnits") as? [NSObject] {
            for unit in existing {
                if let id = unit.value(forKey: unitIDKey) as? String {
                    byID[id] = unit
                }
            }
        }

        for dict in unitDicts {
            guard let unit = NativeDisplayUnitCacheImpl.instantiateCleverTapDisplayUnit(with: dict) else { continue }
            guard let id = unit.value(forKey: unitIDKey) as? String else { continue }
            byID[id] = unit
        }

        controller.setValue(Array(byID.values), forKey: "displayUnits")
        return true
    }

    @discardableResult
    private static func logOnce(_ message: String) -> Bool {
        guard !loggedFailure else { return false }
        loggedFailure = true
        print("[ReflectionSeeder] \(message); display unit events may be unattributed.")
        return false
    }
}
