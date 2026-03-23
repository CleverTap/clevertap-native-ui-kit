//
//  CleverTapAutoWire.swift
//  CleverTapNativeDisplay
//

// MARK: - CleverTap Core SDK Auto-Wire
// Runtime detection and registration with CleverTap Core SDK via Obj-C runtime.
// No compile-time dependency on CleverTap SDK — all interaction via NSClassFromString
// and performSelector.

import Foundation

/// Handles runtime detection of the CleverTap Core SDK and automatic registration
/// as a display unit delegate. If the Core SDK is not present, this is a silent no-op.
internal class CleverTapAutoWire: NSObject {

    /// The bridge instance to forward display units to.
    private weak var bridge: NativeDisplayBridge?

    /// Optional client handler to forward raw display units to.
    private var clientHandler: (([AnyObject]) -> Void)?

    /// Shared observer instance kept alive while auto-wire is active.
    private static var activeObserver: CleverTapAutoWire?

    // MARK: - Public API

    /// Attempt to auto-wire the bridge to the CleverTap Core SDK.
    /// - Parameter bridge: The bridge instance to receive display unit callbacks.
    /// - Returns: The CleverTap shared instance if auto-wire succeeded, `nil` otherwise.
    @discardableResult
    static func tryAutoWire(bridge: NativeDisplayBridge) -> NSObject? {
        // 1. Check if CleverTap class exists
        guard let ctClass = NSClassFromString("CleverTap") as? NSObject.Type else {
            print("[NativeDisplayBridge] CleverTap SDK not found, manual mode only")
            return nil
        }

        // 2. Get shared instance
        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard ctClass.responds(to: sharedSelector) else {
            print("[NativeDisplayBridge] CleverTap class does not respond to sharedInstance")
            return nil
        }

        guard let result = ctClass.perform(sharedSelector),
              let sharedInstance = result.takeUnretainedValue() as? NSObject else {
            print("[NativeDisplayBridge] Failed to get CleverTap shared instance")
            return nil
        }

        // 3. Create observer and register as display unit delegate
        let observer = CleverTapAutoWire()
        observer.bridge = bridge

        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard sharedInstance.responds(to: setDelegateSelector) else {
            print("[NativeDisplayBridge] CleverTap instance does not support setDisplayUnitDelegate:")
            return nil
        }

        sharedInstance.perform(setDelegateSelector, with: observer)

        // 4. Keep observer alive
        activeObserver = observer

        // 5. Register for notification-based updates as a fallback
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(handleDisplayUnitsNotification(_:)),
            name: NSNotification.Name("CleverTapDisplayUnitsLoaded"),
            object: nil
        )

        print("[NativeDisplayBridge] Auto-wired to CleverTap Core SDK")
        return sharedInstance
    }

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
        // Verify this looks like a CleverTap instance
        let className = String(describing: type(of: cleverTap))
        guard className.contains("CleverTap") else {
            print("[NativeDisplayBridge] bind() called with non-CleverTap object: \(className)")
            return false
        }

        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard cleverTap.responds(to: setDelegateSelector) else {
            print("[NativeDisplayBridge] CleverTap instance does not support setDisplayUnitDelegate:")
            return false
        }

        // Create observer and register as delegate
        let observer = CleverTapAutoWire()
        observer.bridge = bridge
        observer.clientHandler = clientHandler

        cleverTap.perform(setDelegateSelector, with: observer)

        // Keep observer alive
        activeObserver = observer

        let suffix = clientHandler != nil ? " (with client handler forwarding)" : ""
        print("[NativeDisplayBridge] Bound to CleverTap instance\(suffix)")
        return true
    }

    /// Tear down auto-wire (called from bridge.clear()).
    static func tearDown() {
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        activeObserver = nil
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
