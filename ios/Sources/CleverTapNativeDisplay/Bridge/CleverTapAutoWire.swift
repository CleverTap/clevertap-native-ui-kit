//
//  CleverTapAutoWire.swift
//  CleverTapNativeDisplay
//

// MARK: - CleverTap Core SDK Auto-Wire
// Runtime detection and registration with CleverTap Core SDK via Obj-C runtime.
// No compile-time dependency on CleverTap SDK — all interaction via NSClassFromString
// and performSelector.

import Foundation
import ObjectiveC

/// Handles runtime detection of the CleverTap Core SDK and automatic registration
/// as a display unit delegate. If the Core SDK is not present, this is a silent no-op.
internal class CleverTapAutoWire: NSObject {

    /// The bridge instance to forward display units to.
    private weak var bridge: NativeDisplayBridge?

    /// Optional client handler to forward raw display units to.
    private var clientHandler: (([AnyObject]) -> Void)?

    /// Shared observer instance kept alive while auto-wire is active.
    private static var activeObserver: CleverTapAutoWire?

    /// Strong reference to the cache adapter installed via Core SDK v7.x's
    /// `setDisplayUnitCache:`. Held to keep the adapter alive for the lifetime
    /// of the wired CleverTap instance.
    private static var activeCache: NativeDisplayUnitCacheImpl?

    /// Whether we've already adopted the CleverTapDisplayUnitDelegate protocol at runtime.
    private static var protocolAdopted = false

    // MARK: - Protocol Adoption

    /// Dynamically adopt the `CleverTapDisplayUnitDelegate` protocol at runtime.
    ///
    /// The Core SDK's `setDisplayUnitDelegate:` checks `conformsToProtocol:` before
    /// accepting the delegate. Since we don't have a compile-time dependency on the
    /// CleverTap SDK, we use `class_addProtocol` to register conformance at runtime.
    private static func adoptProtocolIfNeeded() {
        guard !protocolAdopted else { return }
        if let proto = objc_getProtocol("CleverTapDisplayUnitDelegate") {
            class_addProtocol(CleverTapAutoWire.self, proto)
            protocolAdopted = true
            print("[NativeDisplayBridge] Adopted CleverTapDisplayUnitDelegate protocol")
        } else {
            print("[NativeDisplayBridge] CleverTapDisplayUnitDelegate protocol not found at runtime")
        }
    }

    // MARK: - Public API

    /// Attempt to auto-wire the bridge to the CleverTap Core SDK.
    /// - Parameter bridge: The bridge instance to receive display unit callbacks.
    /// - Returns: `true` if auto-wire succeeded, `false` if Core SDK not found or wiring failed.
    @discardableResult
    static func tryAutoWire(bridge: NativeDisplayBridge) -> Bool {
        adoptProtocolIfNeeded()
        NativeDisplayUnitCacheImpl.adoptProtocolIfNeeded()

        // 1. Check if CleverTap class exists
        guard let ctClass = NSClassFromString("CleverTap") as? NSObject.Type else {
            print("[NativeDisplayBridge] CleverTap SDK not found, manual mode only")
            return false
        }

        // 2. Get shared instance
        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard ctClass.responds(to: sharedSelector) else {
            print("[NativeDisplayBridge] CleverTap class does not respond to sharedInstance")
            return false
        }

        guard let result = ctClass.perform(sharedSelector),
              let sharedInstance = result.takeUnretainedValue() as? NSObject else {
            print("[NativeDisplayBridge] Failed to get CleverTap shared instance")
            return false
        }

        bridge.cleverTapInstance = sharedInstance

        // 3. Prefer the cache-attachment API (Core SDK v7.x+). When attached, server-driven
        // updates flow via cache.updateDisplayUnits(_:) → bridge.processDisplayUnits, so a
        // separate display-unit delegate is unnecessary.
        if attachCache(to: sharedInstance, bridge: bridge) {
            print("[NativeDisplayBridge] Auto-wired via setDisplayUnitCache:")
            return true
        }

        // 4. Fallback: register as display-unit delegate (older Core SDK).
        let observer = CleverTapAutoWire()
        observer.bridge = bridge

        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard sharedInstance.responds(to: setDelegateSelector) else {
            print("[NativeDisplayBridge] CleverTap instance does not support setDisplayUnitDelegate:")
            return false
        }

        sharedInstance.perform(setDelegateSelector, with: observer)

        // 5. Keep observer alive
        activeObserver = observer

        // 6. Register for notification-based updates as a fallback
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(handleDisplayUnitsNotification(_:)),
            name: NSNotification.Name("CleverTapDisplayUnitsLoaded"),
            object: nil
        )

        print("[NativeDisplayBridge] Auto-wired via setDisplayUnitDelegate: fallback")
        return true
    }

    /// Reflectively invokes `-[CleverTap setDisplayUnitCache:]` if available.
    /// Returns `true` on success; the cache is retained in `activeCache`.
    private static func attachCache(to cleverTap: NSObject, bridge: NativeDisplayBridge) -> Bool {
        let selector = NSSelectorFromString("setDisplayUnitCache:")
        guard cleverTap.responds(to: selector) else { return false }
        let cache = bridge.coreSdkCacheAdapter
        cleverTap.perform(selector, with: cache)
        activeCache = cache
        return true
    }

    /// Whether the bridge is wired through the cache-attachment path.
    static var isCacheAttached: Bool { activeCache != nil }

    /// Bind the bridge to a specific CleverTap instance.
    ///
    /// Unlike `tryAutoWire`, this accepts the instance directly rather than looking
    /// it up via `NSClassFromString`. The caller passes the CleverTap object.
    ///
    /// - Parameters:
    ///   - cleverTap: The CleverTap instance (as NSObject to avoid compile dependency).
    ///   - bridge: The bridge to forward display units to.
    /// - Returns: `true` if binding succeeded.
    /// Bind the bridge to a specific CleverTap instance.
    ///
    /// - Parameters:
    ///   - cleverTap: The CleverTap instance (as NSObject).
    ///   - bridge: The bridge to forward display units to.
    ///   - clientHandler: Optional closure to forward raw display units to the client.
    /// - Returns: `true` if binding succeeded.
    @discardableResult
    static func bindToInstance(
        _ cleverTap: NSObject,
        bridge: NativeDisplayBridge,
        clientHandler: (([AnyObject]) -> Void)? = nil
    ) -> Bool {
        adoptProtocolIfNeeded()
        NativeDisplayUnitCacheImpl.adoptProtocolIfNeeded()

        // Verify this looks like a CleverTap instance
        let className = String(describing: type(of: cleverTap))
        guard className.contains("CleverTap") else {
            print("[NativeDisplayBridge] bind() called with non-CleverTap object: \(className)")
            return false
        }

        bridge.cleverTapInstance = cleverTap

        // Prefer cache-attachment path (Core SDK v7.x+).
        if attachCache(to: cleverTap, bridge: bridge) {
            // Keep client's existing display-unit delegate intact when the cache
            // is attached. Forward any client handler via the existing delegate
            // path only if requested — otherwise skip delegate registration to
            // avoid double-firing.
            if let handler = clientHandler {
                let observer = CleverTapAutoWire()
                observer.bridge = bridge
                observer.clientHandler = handler
                let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
                if cleverTap.responds(to: setDelegateSelector) {
                    cleverTap.perform(setDelegateSelector, with: observer)
                    activeObserver = observer
                }
            }
            print("[NativeDisplayBridge] Bound via setDisplayUnitCache:" + (clientHandler != nil ? " (with client handler)" : ""))
            return true
        }

        // Fallback: register as display-unit delegate (older Core SDK).
        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard cleverTap.responds(to: setDelegateSelector) else {
            print("[NativeDisplayBridge] CleverTap instance does not support setDisplayUnitDelegate:")
            return false
        }

        let observer = CleverTapAutoWire()
        observer.bridge = bridge
        observer.clientHandler = clientHandler

        cleverTap.perform(setDelegateSelector, with: observer)

        activeObserver = observer

        let suffix = clientHandler != nil ? " (with client handler forwarding)" : ""
        print("[NativeDisplayBridge] Bound via setDisplayUnitDelegate: fallback\(suffix)")
        return true
    }

    /// Tear down auto-wire (called from bridge.clear()).
    static func tearDown() {
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        activeObserver = nil
        activeCache = nil
    }

    // MARK: - Delegate Callback (Obj-C compatible)

    /// Called by CleverTap SDK when display units are updated.
    /// Method signature matches `CleverTapDisplayUnitDelegate.displayUnitsUpdated(_:)`.
    @objc func displayUnitsUpdated(_ displayUnits: [AnyObject]) {
        guard let bridge = bridge else { return }

        // Forward to client handler first
        clientHandler?(displayUnits)

        let jsonStrings: [String] = displayUnits.compactMap { unit in
            // CleverTapDisplayUnit has a `json` property returning [String: Any]?
            guard let jsonDict = unit.perform(NSSelectorFromString("json"))?.takeUnretainedValue() as? [String: Any] else {
                // Fallback: try `jsonObject` property
                guard let jsonObj = unit.perform(NSSelectorFromString("jsonObject"))?.takeUnretainedValue() as? [String: Any] else {
                    return nil
                }
                return serializeToString(jsonObj)
            }
            return serializeToString(jsonDict)
        }

        if !jsonStrings.isEmpty {
            bridge.processDisplayUnits(jsonStrings)
        }
    }

    // MARK: - Notification Handler

    @objc private func handleDisplayUnitsNotification(_ notification: Notification) {
        guard let bridge = bridge,
              let displayUnits = notification.userInfo?["displayUnits"] as? [AnyObject] else {
            return
        }
        displayUnitsUpdated(displayUnits)
    }

    // MARK: - Helpers

    private func serializeToString(_ dict: [String: Any]) -> String? {
        guard let data = try? JSONSerialization.data(withJSONObject: dict) else {
            return nil
        }
        return String(data: data, encoding: .utf8)
    }
}
