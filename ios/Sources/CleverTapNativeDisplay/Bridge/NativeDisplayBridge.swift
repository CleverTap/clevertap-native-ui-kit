//
//  NativeDisplayBridge.swift
//  CleverTapNativeDisplay
//

// MARK: - Native Display Bridge
// Main entry point for integrating Native Display SDK with CleverTap Core SDK.
// Supports both auto-wire (runtime Core SDK detection) and manual JSON input modes.

import Foundation

/// Bridge between CleverTap Core SDK and the Native Display SDK.
///
/// Provides two integration modes:
/// - **Auto-wire**: Detects CleverTap Core SDK at runtime and registers as a display unit
///   delegate automatically. Call `initialize()` once at app startup.
/// - **Manual**: Feed raw JSON strings directly via `processDisplayUnits(_:)`.
///   Works with any JSON source — no Core SDK required.
///
/// ## Usage
///
/// ### Auto-wire (recommended)
/// ```swift
/// // In AppDelegate or app startup
/// NativeDisplayBridge.shared.initialize()
/// NativeDisplayBridge.shared.addListener(self)
/// ```
///
/// ### Manual
/// ```swift
/// let bridge = NativeDisplayBridge.shared
/// bridge.addListener(self)
/// bridge.processDisplayUnits(jsonStrings)
/// ```
///
/// ### Rendering
/// ```swift
/// func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
///     for unit in units {
///         // unit.config is a ResolvedConfig ready for NativeDisplayView
///         NativeDisplayView(config: unit.config)
///     }
/// }
/// ```
public class NativeDisplayBridge {

    /// Shared singleton instance.
    public static let shared = NativeDisplayBridge()

    // MARK: - Private State

    /// Cache of parsed display units keyed by unitId. Access synchronized via `lock`.
    private var cache: [String: NativeDisplayUnit] = [:]

    /// Thread-safety lock for cache and listener access.
    private let lock = NSLock()

    /// Weak listener references.
    private var listeners = NSHashTable<AnyObject>.weakObjects()

    /// Parser instance.
    private let parser = NativeDisplayConfigParser()

    /// Whether auto-wire has been attempted.
    private var isInitialized = false

    /// Weak reference to the CleverTap Core SDK instance.
    /// Stored as NSObject to avoid a compile-time dependency on the CleverTap SDK.
    internal weak var cleverTapInstance: NSObject?

    /// Event name for server fetch requests.
    static let wzrkFetch = "wzrk_fetch"

    /// Fetch type constant for Native Display units.
    static let fetchTypeNativeDisplay = 9

    // MARK: - Init

    private init() {}

    // MARK: - Auto-Wire

    /// Initialize the bridge with auto-wire support.
    /// Detects CleverTap Core SDK at runtime via `NSClassFromString`.
    /// Safe to call even without Core SDK — silently logs and continues in manual mode.
    public func initialize() {
        lock.lock()
        defer { lock.unlock() }

        guard !isInitialized else {
            print("[NativeDisplayBridge] Already initialized")
            return
        }
        isInitialized = true

        CleverTapAutoWire.tryAutoWire(bridge: self)
    }

    // MARK: - Bind to CleverTap Instance

    /// Bind the bridge to a CleverTap instance directly.
    ///
    /// Registers a composite display unit delegate that forwards to both the bridge
    /// and an optional client callback. This avoids replacing the client's existing
    /// delegate, since the Core SDK only supports a single display unit delegate.
    ///
    /// ```swift
    /// // Without client callback
    /// NativeDisplayBridge.shared.bind(CleverTap.sharedInstance())
    ///
    /// // With client callback (both receive display units)
    /// NativeDisplayBridge.shared.bind(CleverTap.sharedInstance()) { displayUnits in
    ///     // Client's own display unit handling
    /// }
    /// ```
    ///
    /// - Parameters:
    ///   - cleverTap: A `CleverTap` instance (passed as `Any?` to avoid compile dependency).
    ///     If nil or not a valid CleverTap instance, this is a no-op.
    ///   - forwardTo: Optional closure that receives raw display unit objects from the Core SDK.
    ///     Called before the bridge processes units, preserving the client's existing handling.
    /// - Returns: `true` if binding succeeded, `false` otherwise.
    @discardableResult
    public func bind(_ cleverTap: Any?, forwardTo clientHandler: (([AnyObject]) -> Void)? = nil) -> Bool {
        guard let instance = cleverTap as? NSObject else {
            print("[NativeDisplayBridge] bind() called with nil or non-NSObject, ignoring")
            return false
        }
        return CleverTapAutoWire.bindToInstance(instance, bridge: self, clientHandler: clientHandler)
    }

    /// Request the CleverTap server to fetch Native Display units.
    ///
    /// Sends a `wzrk_fetch` event with fetch type `9` (Native Display) via the
    /// provided CleverTap instance. The server will respond with display units
    /// through the normal `adUnit_notifs` pipeline, which the bridge listener
    /// will pick up automatically.
    ///
    /// ```swift
    /// NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap.sharedInstance())
    /// // Response arrives via NativeDisplayBridgeListener.onNativeDisplaysLoaded()
    /// ```
    ///
    /// - Parameter cleverTap: A `CleverTap` instance (passed as `Any?` to avoid compile dependency).
    /// - Returns: `true` if the fetch event was sent, `false` otherwise.
    @discardableResult
    public func fetchNativeDisplays(_ cleverTap: Any?) -> Bool {
        guard let ct = cleverTap as? NSObject else {
            print("[NativeDisplayBridge] fetchNativeDisplays() called with nil or non-NSObject")
            return false
        }

        let recordEventSelector = NSSelectorFromString("recordEvent:withProps:")
        guard ct.responds(to: recordEventSelector) else {
            print("[NativeDisplayBridge] CleverTap instance does not support recordEvent:withProps:")
            return false
        }

        let props: [String: Any] = ["t": NativeDisplayBridge.fetchTypeNativeDisplay]
        ct.perform(recordEventSelector, with: NativeDisplayBridge.wzrkFetch, with: props)

        print("[NativeDisplayBridge] Sent wzrk_fetch request for Native Display (type=\(NativeDisplayBridge.fetchTypeNativeDisplay))")
        return true
    }

    // MARK: - Manual Mode: Process JSON

    /// Process multiple display unit JSON strings. Replaces the entire cache.
    /// - Parameter displayUnitJsonStrings: Array of raw JSON strings from display unit payloads.
    public func processDisplayUnits(_ displayUnitJsonStrings: [String]) {
        var newCache: [String: NativeDisplayUnit] = [:]

        for jsonString in displayUnitJsonStrings {
            if let unit = parser.tryParse(jsonString) {
                newCache[unit.unitId] = unit
            }
        }

        let units: [NativeDisplayUnit]
        lock.lock()
        cache = newCache
        units = Array(cache.values)
        lock.unlock()

        notifyListeners(units)
    }

    /// Process a single display unit JSON string. Adds or updates the unit in cache.
    /// - Parameter displayUnitJsonString: Raw JSON string from a display unit payload.
    public func processDisplayUnit(_ displayUnitJsonString: String) {
        guard let unit = parser.tryParse(displayUnitJsonString) else {
            return
        }

        let allUnits: [NativeDisplayUnit]
        lock.lock()
        cache[unit.unitId] = unit
        allUnits = Array(cache.values)
        lock.unlock()

        notifyListeners(allUnits)
    }

    /// Process multiple display unit JSON data objects. Replaces the entire cache.
    /// - Parameter data: Array of raw JSON data from display unit payloads.
    public func processDisplayUnits(data: [Data]) {
        var newCache: [String: NativeDisplayUnit] = [:]

        for jsonData in data {
            let rawJson = String(data: jsonData, encoding: .utf8)
            if let unit = parser.tryParse(data: jsonData, rawJson: rawJson) {
                newCache[unit.unitId] = unit
            }
        }

        let units: [NativeDisplayUnit]
        lock.lock()
        cache = newCache
        units = Array(cache.values)
        lock.unlock()

        notifyListeners(units)
    }

    // MARK: - Pull API

    /// Get all currently cached native display units.
    /// - Returns: Array of all parsed native display units.
    public func getAllNativeDisplays() -> [NativeDisplayUnit] {
        lock.lock()
        defer { lock.unlock() }
        return Array(cache.values)
    }

    /// Get a specific native display unit by its ID.
    /// - Parameter unitId: The `wzrk_id` of the display unit.
    /// - Returns: The matching `NativeDisplayUnit`, or `nil` if not found.
    public func getNativeDisplayForId(_ unitId: String) -> NativeDisplayUnit? {
        lock.lock()
        defer { lock.unlock() }
        return cache[unitId]
    }

    // MARK: - Push API (Listeners)

    /// Add a listener to receive native display unit updates.
    /// Listeners are held as weak references — no need to remove on deallocation.
    /// - Parameter listener: The listener to add.
    public func addListener(_ listener: NativeDisplayBridgeListener) {
        lock.lock()
        defer { lock.unlock() }
        listeners.add(listener)
    }

    /// Remove a previously added listener.
    /// - Parameter listener: The listener to remove.
    public func removeListener(_ listener: NativeDisplayBridgeListener) {
        lock.lock()
        defer { lock.unlock() }
        listeners.remove(listener)
    }

    // MARK: - Attribution Push Methods

    /// Push a display unit viewed event to the CleverTap Core SDK.
    ///
    /// Calls `pushDisplayUnitViewedEventForID:` via performSelector to avoid
    /// a compile-time dependency on the CleverTap SDK.
    ///
    /// - Parameter unitId: The `wzrk_id` of the display unit that was viewed.
    /// - Returns: `true` if the event was sent, `false` if no CleverTap instance is available.
    @discardableResult
    public func pushViewedEvent(unitId: String) -> Bool {
        guard let ct = cleverTapInstance else { return false }
        let sel = NSSelectorFromString("pushDisplayUnitViewedEventForID:")
        guard ct.responds(to: sel) else { return false }
        ct.perform(sel, with: unitId)
        return true
    }

    /// Push a display unit clicked event to the CleverTap Core SDK.
    ///
    /// Calls `pushDisplayUnitClickedEventForID:` via performSelector to avoid
    /// a compile-time dependency on the CleverTap SDK.
    ///
    /// - Parameter unitId: The `wzrk_id` of the display unit that was clicked.
    /// - Returns: `true` if the event was sent, `false` if no CleverTap instance is available.
    @discardableResult
    public func pushClickedEvent(unitId: String) -> Bool {
        guard let ct = cleverTapInstance else { return false }
        let sel = NSSelectorFromString("pushDisplayUnitClickedEventForID:")
        guard ct.responds(to: sel) else { return false }
        ct.perform(sel, with: unitId)
        return true
    }

    /// Create an action listener that automatically forwards viewed/clicked events to
    /// the CleverTap Core SDK via `pushDisplayUnitViewedEventForID:` /
    /// `pushDisplayUnitClickedEventForID:`.
    ///
    /// Pass the returned listener as `actionListener` to `NativeDisplayView` or
    /// `NativeDisplaySlot`. All other callbacks are forwarded to the optional `base` listener.
    ///
    /// ```swift
    /// let listener = NativeDisplayBridge.shared.createEventForwardingListener(base: self)
    /// NativeDisplayView(config: config, actionListener: listener)
    /// ```
    ///
    /// - Parameter base: An existing action listener whose callbacks should be preserved.
    /// - Returns: A new listener that forwards attribution events to CleverTap Core SDK.
    public func createEventForwardingListener(
        base: NativeDisplayActionListener? = nil
    ) -> NativeDisplayActionListener {
        return NativeDisplayEventForwardingListener(bridge: self, base: base)
    }

    // MARK: - Clear

    /// Clear all cached display units, tear down auto-wire, and reset state.
    public func clear() {
        lock.lock()
        cache.removeAll()
        listeners.removeAllObjects()
        isInitialized = false
        lock.unlock()

        CleverTapAutoWire.tearDown()
        print("[NativeDisplayBridge] Cleared all cached units and listeners")
    }

    // MARK: - Private

    /// Notify all registered listeners on the main thread.
    private func notifyListeners(_ units: [NativeDisplayUnit]) {
        lock.lock()
        let currentListeners = listeners.allObjects.compactMap { $0 as? NativeDisplayBridgeListener }
        lock.unlock()

        if currentListeners.isEmpty { return }

        DispatchQueue.main.async {
            for listener in currentListeners {
                listener.onNativeDisplaysLoaded(units)
            }
        }
    }
}

// MARK: - Event Forwarding Listener

/// Concrete `NativeDisplayActionListener` that forwards `onDisplayUnitViewed` and
/// `onDisplayUnitClicked` callbacks to the CleverTap Core SDK via
/// `NativeDisplayBridge.pushViewedEvent` / `pushClickedEvent`.
///
/// All other callbacks are forwarded to the optional `base` listener unchanged.
/// Inherits from `NSObject` because `NativeDisplayActionListener` is an `@objc` protocol.
private class NativeDisplayEventForwardingListener: NSObject, NativeDisplayActionListener {
    private weak var bridge: NativeDisplayBridge?
    private weak var base: NativeDisplayActionListener?

    init(bridge: NativeDisplayBridge, base: NativeDisplayActionListener?) {
        self.bridge = bridge
        self.base = base
    }

    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool {
        return base?.onOpenUrl(url: url, openInBrowser: openInBrowser) ?? false
    }

    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {
        base?.onCustomAction(key: key, value: value, metadata: metadata)
    }

    func onNavigate(destination: String, params: [String: String]?) {
        base?.onNavigate(destination: destination, params: params)
    }

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        base?.onTrackEvent(eventName: eventName, properties: properties)
    }

    func onDisplayUnitViewed(unitId: String) {
        base?.onDisplayUnitViewed?(unitId: unitId)
        bridge?.pushViewedEvent(unitId: unitId)
    }

    func onDisplayUnitClicked(unitId: String) {
        base?.onDisplayUnitClicked?(unitId: unitId)
        bridge?.pushClickedEvent(unitId: unitId)
    }
}
