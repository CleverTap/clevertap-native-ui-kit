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

    /// Wrapper SDK identifier passed to `-[CleverTap setCustomSdkVersion:withVersion:]`.
    /// The Core SDK uses this to attribute analytics events back to the Native Display
    /// SDK rather than the host integration. Mirrors `CUSTOM_SDK_NAME` in the Android
    /// `CleverTapAutoWire`.
    private static let customSdkName = "Native Display"

    /// Selector for `-[CleverTap setCustomSdkVersion:version:]` resolved once at
    /// module load. Signature on Core SDK (per `CleverTap.h`):
    /// `- (void)setCustomSdkVersion:(NSString *)name version:(int)version;`.
    /// Note the second arg label is `version:` (NOT `withVersion:`) and the type is
    /// `int` (32-bit, fixed-width) rather than `NSInteger` (pointer-sized). We can't
    /// use `perform(_:with:with:)` for the primitive — we resolve the IMP and call it
    /// via `@convention(c)` with the exact `Int32` width.
    private static let setCustomSdkVersionSelector: Selector = NSSelectorFromString(
        "setCustomSdkVersion:version:"
    )

    /// The bridge instance to forward display units to.
    private weak var bridge: NativeDisplayBridge?

    /// Optional client handler to forward raw display units to.
    private var clientHandler: (([AnyObject]) -> Void)?

    /// Shared observer instance kept alive while auto-wire is active.
    private static var activeObserver: CleverTapAutoWire?

    /// Whether we've already adopted the CleverTapDisplayUnitDelegate protocol at runtime.
    private static var protocolAdopted = false

    /// Identity reference to the CleverTap instance we last stamped via
    /// `tagCustomSdkVersion`. Guards against re-tagging when wiring runs more than
    /// once for the same instance (e.g. clients calling `bind(_:)` twice). When a
    /// different instance arrives, the tag fires again.
    ///
    /// Held weakly so we don't extend the Core SDK instance's lifetime, and so
    /// pointer identity comparison via `===` remains meaningful for the lifetime
    /// of the attached instance only.
    private static weak var taggedInstance: NSObject?

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
            NDLogger.d(Self.self, "Adopted CleverTapDisplayUnitDelegate protocol")
        } else {
            NDLogger.w(Self.self, "CleverTapDisplayUnitDelegate protocol not found at runtime")
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
            NDLogger.d(Self.self, "CleverTap SDK not found, manual mode only")
            return false
        }

        // 2. Get shared instance
        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard ctClass.responds(to: sharedSelector) else {
            NDLogger.w(Self.self, "CleverTap class does not respond to sharedInstance")
            return false
        }

        guard let result = ctClass.perform(sharedSelector),
              let sharedInstance = result.takeUnretainedValue() as? NSObject else {
            NDLogger.w(Self.self, "Failed to get CleverTap shared instance")
            return false
        }

        bridge.cleverTapInstance = sharedInstance

        // 3. Tag the Core SDK with the ND wrapper SDK identifier so server-side
        // analytics can attribute events back to a specific Native Display SDK build.
        tagCustomSdkVersion(sharedInstance)

        // 4. Sync Core SDK log level when the client has not set one explicitly.
        syncLogLevelFromCoreSdk(sharedInstance)

        // 4. Prefer the cache-attachment API (Core SDK v7.x+). When attached, server-driven
        // updates flow via cache.updateDisplayUnits(_:) → bridge.processDisplayUnits, so a
        // separate display-unit delegate is unnecessary.
        if attachCache(to: sharedInstance, bridge: bridge) {
            NDLogger.d(Self.self, "Auto-wired via setDisplayUnitCache:")
            return true
        }

        // 4. Fallback: register as display-unit delegate (older Core SDK).
        let observer = CleverTapAutoWire()
        observer.bridge = bridge

        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard sharedInstance.responds(to: setDelegateSelector) else {
            NDLogger.w(Self.self, "CleverTap instance does not support setDisplayUnitDelegate:")
            return false
        }

        sharedInstance.perform(setDelegateSelector, with: observer)

        // 5. Keep observer aliverandom
        activeObserver = observer

        // 6. Register for notification-based updates as a fallback
        NotificationCenter.default.addObserver(
            observer,
            selector: #selector(handleDisplayUnitsNotification(_:)),
            name: NSNotification.Name("CleverTapDisplayUnitsLoaded"),
            object: nil
        )

        NDLogger.d(Self.self, "Auto-wired via setDisplayUnitDelegate: fallback")
        return true
    }

    /// Reflectively invokes `-[CleverTap setDisplayUnitCache:]` if available.
    /// Returns `true` on success.
    private static func attachCache(to cleverTap: NSObject, bridge: NativeDisplayBridge) -> Bool {
        let selector = NSSelectorFromString("setDisplayUnitCache:")
        guard cleverTap.responds(to: selector) else { return false }
        let cache = bridge.coreSdkCacheAdapter
        cleverTap.perform(selector, with: cache)
        bridge.isCacheAttached = true
        return true
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
        adoptProtocolIfNeeded()
        NativeDisplayUnitCacheImpl.adoptProtocolIfNeeded()

        // Verify this looks like a CleverTap instance
        let className = String(describing: type(of: cleverTap))
        guard className.contains("CleverTap") else {
            NDLogger.w(Self.self, "bind() called with non-CleverTap object: \(className)")
            return false
        }

        bridge.cleverTapInstance = cleverTap

        // Tag the Core SDK with the ND wrapper identifier before any further
        // wiring so subsequent events carry the version stamp.
        tagCustomSdkVersion(cleverTap)

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
            NDLogger.d(Self.self, "Bound via setDisplayUnitCache:" + (clientHandler != nil ? " (with client handler)" : ""))
            return true
        }

        // Fallback: register as display-unit delegate (older Core SDK).
        let setDelegateSelector = NSSelectorFromString("setDisplayUnitDelegate:")
        guard cleverTap.responds(to: setDelegateSelector) else {
            NDLogger.w(Self.self, "CleverTap instance does not support setDisplayUnitDelegate:")
            return false
        }

        let observer = CleverTapAutoWire()
        observer.bridge = bridge
        observer.clientHandler = clientHandler

        cleverTap.perform(setDelegateSelector, with: observer)

        activeObserver = observer

        let suffix = clientHandler != nil ? " (with client handler forwarding)" : ""
        NDLogger.d(Self.self, "Bound via setDisplayUnitDelegate: fallback\(suffix)")
        return true
    }

    /// Tag the attached Core SDK instance with the Native Display wrapper identifier
    /// via `-[CleverTap setCustomSdkVersion:withVersion:]`.
    ///
    /// The Core SDK uses this to attribute analytics events back to a specific
    /// wrapper SDK build (e.g. server can distinguish ND 1.0.0 from a host app's
    /// own events).
    ///
    /// One-shot per instance: we hold a weak reference to the last-tagged instance
    /// and skip re-tagging when the same instance is re-wired (e.g. clients calling
    /// `bind(_:)` twice). Re-tagging fires when a different instance arrives.
    ///
    /// Defensive reflection: when the selector is absent (older Core SDK that
    /// predates wrapper SDK support), we log at warning level and continue —
    /// attribution falls back to the host-app namespace.
    ///
    /// IMP-cast invocation: `setCustomSdkVersion:withVersion:` takes a primitive
    /// `NSInteger` second argument; `perform(_:with:with:)` can only pass `Any`
    /// (id) values and would garble the integer register. Resolving the IMP and
    /// calling it through a `@convention(c)` function pointer with the exact C
    /// signature is the only safe form.
    private static func tagCustomSdkVersion(_ ctInstance: NSObject) {
        if let last = taggedInstance, last === ctInstance {
            // Already tagged this exact instance — avoid double-fire on re-wire.
            return
        }
        guard ctInstance.responds(to: setCustomSdkVersionSelector) else {
            NDLogger.w(
                Self.self,
                "CleverTap instance does not respond to setCustomSdkVersion:version: — wrapper attribution unavailable"
            )
            return
        }
        guard let imp = class_getMethodImplementation(
            type(of: ctInstance),
            setCustomSdkVersionSelector
        ) else {
            NDLogger.w(
                Self.self,
                "Could not resolve IMP for setCustomSdkVersion:version:"
            )
            return
        }
        // Obj-C `int` is fixed-width 32-bit on all iOS architectures. Passing the
        // pointer-sized `Int` (8 bytes on 64-bit) would garble adjacent registers,
        // so we narrow to `Int32` explicitly.
        typealias SetCustomSdkVersionIMP = @convention(c) (AnyObject, Selector, NSString, Int32) -> Void
        let fn = unsafeBitCast(imp, to: SetCustomSdkVersionIMP.self)
        fn(
            ctInstance,
            setCustomSdkVersionSelector,
            customSdkName as NSString,
            Int32(NativeDisplaySDKVersion.code)
        )
        taggedInstance = ctInstance
        NDLogger.d(
            Self.self,
            "Tagged Core SDK with Native Display version \(NativeDisplaySDKVersion.code)"
        )
    }

    /// Sync the ND SDK log level from Core SDK's `debugLevel` property.
    ///
    /// Only runs when the client has not set a log level explicitly (via
    /// `NativeDisplayBridge.setLogLevel`). Failures are silently ignored — the
    /// default level remains unchanged if the property is unavailable.
    ///
    /// CleverTap Core SDK integer mapping: -1 OFF, 0 INFO, 1 DEBUG, 2 VERBOSE.
    private static func syncLogLevelFromCoreSdk(_ ctInstance: NSObject) {
        // Fall back to .debug for unknown future Core SDK levels (matches Android behavior).
        let cleverTapClass: AnyClass = type(of: ctInstance)
        let selector = Selector(("getDebugLevel"))
        guard let method = class_getClassMethod(cleverTapClass, selector) else { return }
        typealias GetDebugLevelIMP = @convention(c) (AnyClass, Selector) -> Int32
        let imp = method_getImplementation(method)
        let fn = unsafeBitCast(imp, to: GetDebugLevelIMP.self)
        let rawValue = fn(cleverTapClass, selector)

        let level = NDLogLevel(rawValue: Int(rawValue)) ?? .debug
        // Use syncFromCoreSdk so explicitlySet is NOT flipped — a future client call
        // to NativeDisplayBridge.setLogLevel will still override, and re-initialization
        // will re-sync from Core SDK if the client never set a level explicitly.
        NDLogger.syncFromCoreSdk(level)
    }

    /// Tear down auto-wire (called from bridge.clear()).
    static func tearDown() {
        if let observer = activeObserver {
            NotificationCenter.default.removeObserver(observer)
        }
        activeObserver = nil
        // Clear the weak identity so a subsequent re-wire (post-clear) re-tags
        // the same instance — symmetric with `bridge.isInitialized = false`.
        taggedInstance = nil
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
        guard bridge != nil,
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
