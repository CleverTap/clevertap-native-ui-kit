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

    /// Weak reference to the bound CleverTap instance (for fetch calls).
    private weak var cleverTapInstance: NSObject?

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

        if let ctInstance = CleverTapAutoWire.tryAutoWire(bridge: self) {
            cleverTapInstance = ctInstance
        }
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
        cleverTapInstance = instance
        return CleverTapAutoWire.bindToInstance(instance, bridge: self, clientHandler: clientHandler)
    }

    /// Request the CleverTap server to fetch Native Display units.
    ///
    /// Sends a `wzrk_fetch` event with fetch type `9` (Native Display) via the
    /// bound CleverTap instance. The server will respond with display units
    /// through the normal `adUnit_notifs` pipeline, which the bridge listener
    /// will pick up automatically.
    ///
    /// Requires a prior call to `bind()` or `initialize()`. Returns `false` if no
    /// CleverTap instance is available.
    ///
    /// ```swift
    /// NativeDisplayBridge.shared.fetchNativeDisplays()
    /// // Response arrives via NativeDisplayBridgeListener.onNativeDisplaysLoaded()
    /// ```
    ///
    /// - Returns: `true` if the fetch event was sent, `false` if no CleverTap instance is bound.
    @discardableResult
    public func fetchNativeDisplays() -> Bool {
        guard let ct = cleverTapInstance else {
            print("[NativeDisplayBridge] fetchNativeDisplays() called but no CleverTap instance is bound. Call bind() first.")
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
