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

    /// In-memory store of parsed Native Display units. Owned by the cache
    /// impl so that storage and the Core-SDK-facing adapter share a single
    /// source of truth — no duplicate caching.
    private let cache = NativeDisplayUnitCacheImpl()

    /// Thread-safety lock for listener access.
    private let lock = NSLock()

    /// Weak listener references.
    private var listeners = NSHashTable<AnyObject>.weakObjects()

    /// Parser instance.
    private let parser = NativeDisplayConfigParser()

    /// Serial queue for off-main JSON parsing and cache writes.
    ///
    /// Why serial (not concurrent + lock): a serial queue gives FIFO ordering
    /// across rapid back-to-back `processDisplayUnits` calls. The cache's
    /// `NSLock` keeps the dictionary structurally consistent but does not
    /// preserve submission order between parse and cache-write work — a
    /// concurrent queue could silently re-order the final cache state when
    /// callers fire payloads in quick succession (e.g. Core SDK fan-out).
    private let parseQueue = DispatchQueue(
        label: "com.clevertap.nativedisplay.parse",
        qos: .userInitiated
    )

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

    private init() {
        cache.onServerUpdate = { [weak self] arr in
            self?.handleServerCacheUpdate(arr)
        }
    }

    /// Bridge-side handler invoked when Core SDK delivers a server response
    /// through the cache adapter's `updateDisplayUnits:` method. Parses the
    /// payload, replaces cache contents (via `replaceAll`) and notifies
    /// listeners — same pipeline as manual `processDisplayUnits(_:)`.
    ///
    /// Defers all serialization + parse work to the parse queue so we never
    /// block whatever thread Core SDK happened to call us from.
    private func handleServerCacheUpdate(_ displayUnits: NSArray) {
        guard let dicts = displayUnits as? [[String: Any]], !dicts.isEmpty else { return }
        parseQueue.async { [weak self] in
            guard let self else { return }
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            let jsonStrings: [String] = dicts.compactMap { dict in
                guard let data = try? JSONSerialization.data(withJSONObject: dict) else { return nil }
                return String(data: data, encoding: .utf8)
            }
            if jsonStrings.isEmpty { return }
            let parsed: [NativeDisplayUnit] = jsonStrings.compactMap { self.parser.tryParse($0) }
            self.cache.replaceAll(parsed)
            self.notifyListeners(parsed)
        }
    }

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
    ///
    /// Parsing (JSON deserialization, decoding into `ResolvedConfig`, and
    /// per-node style resolution) runs off the main thread on `parseQueue`.
    /// Listener notification then hops back to main via `notifyListeners`.
    /// The method is synchronous from the caller's POV — work is fire-and-forget;
    /// results are delivered through listeners.
    ///
    /// - Parameter displayUnitJsonStrings: Array of raw JSON strings from display unit payloads.
    public func processDisplayUnits(_ displayUnitJsonStrings: [String]) {
        parseQueue.async { [weak self] in
            guard let self else { return }
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            let parsed: [NativeDisplayUnit] = displayUnitJsonStrings.compactMap { self.parser.tryParse($0) }
            self.cache.replaceAll(parsed)
            self.notifyListeners(parsed)
        }
    }

    /// Process a single display unit JSON string. Adds or updates the unit in cache.
    ///
    /// Parses off-main on `parseQueue`; listener notification hops to main.
    /// - Parameter displayUnitJsonString: Raw JSON string from a display unit payload.
    public func processDisplayUnit(_ displayUnitJsonString: String) {
        parseQueue.async { [weak self] in
            guard let self else { return }
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            guard let unit = self.parser.tryParse(displayUnitJsonString) else { return }
            self.cache.put(unit)
            self.notifyListeners(self.cache.getAll())
        }
    }

    /// Process multiple display unit JSON data objects. Replaces the entire cache.
    ///
    /// Parses off-main on `parseQueue`; listener notification hops to main.
    /// - Parameter data: Array of raw JSON data from display unit payloads.
    public func processDisplayUnits(data: [Data]) {
        parseQueue.async { [weak self] in
            guard let self else { return }
            #if DEBUG
            dispatchPrecondition(condition: .notOnQueue(.main))
            #endif
            let parsed: [NativeDisplayUnit] = data.compactMap { jsonData in
                let rawJson = String(data: jsonData, encoding: .utf8)
                return self.parser.tryParse(data: jsonData, rawJson: rawJson)
            }
            self.cache.replaceAll(parsed)
            self.notifyListeners(parsed)
        }
    }

    // MARK: - Pull API

    /// Get all currently cached native display units.
    /// - Returns: Array of all parsed native display units.
    public func getAllNativeDisplays() -> [NativeDisplayUnit] {
        return cache.getAll()
    }

    /// Get a specific native display unit by its ID.
    /// - Parameter unitId: The `wzrk_id` of the display unit.
    /// - Returns: The matching `NativeDisplayUnit`, or `nil` if not found.
    public func getNativeDisplayForId(_ unitId: String) -> NativeDisplayUnit? {
        return cache.get(unitId)
    }

    // MARK: - Push API (Listeners)

    /// Add a listener to receive native display unit updates.
    /// Listeners are held as weak references — no need to remove on deallocation.
    /// - Parameter listener: The listener to add.
    public func addListener(_ listener: NativeDisplayBridgeListener) {
        lock.lock(); defer { lock.unlock() }
        listeners.add(listener)
    }

    /// Remove a previously added listener.
    /// - Parameter listener: The listener to remove.
    public func removeListener(_ listener: NativeDisplayBridgeListener) {
        lock.lock(); defer { lock.unlock() }
        listeners.remove(listener)
    }

    /// Internal accessor used by `CleverTapAutoWire` when binding to a
    /// CleverTap instance via `setDisplayUnitCache:`. Returns this bridge's
    /// own cache instance so storage and Core SDK share a single source of
    /// truth.
    internal var coreSdkCacheAdapter: NativeDisplayUnitCacheImpl { cache }

    // MARK: - Test-Only Helpers

    /// Test-only helper: blocks the caller until any in-flight parse work has
    /// finished. The serial parse queue's FIFO ordering means a sync barrier
    /// here drains every previously-submitted task. Used by unit tests that
    /// rely on synchronous cache observation immediately after submitting JSON.
    internal func _waitUntilIdle() {
        parseQueue.sync { /* drain */ }
    }

    /// Test-only helper: synchronously runs `block` on the parse queue and
    /// returns its result. Used by unit tests to inspect queue identity
    /// (label, main-thread-ness) without exposing the queue itself.
    internal func _runOnParseQueue<T>(_ block: () -> T) -> T {
        return parseQueue.sync(execute: block)
    }

    /// Test-only constant: the parse queue label. Must match the label used
    /// when constructing `parseQueue`.
    internal static let _parseQueueLabel = "com.clevertap.nativedisplay.parse"

    // MARK: - Attribution Push Methods

    /// Push a display unit viewed event to the CleverTap Core SDK.
    ///
    /// Invokes `-[CleverTap recordDisplayUnitViewedEventForID:]` via
    /// `performSelector` to avoid a compile-time dependency on the CleverTap SDK.
    /// (The iOS Core SDK names this `recordDisplayUnit…`; the Android Core SDK
    /// uses `pushDisplayUnit…`. The cross-platform ND-SDK method name stays
    /// `pushViewedEvent` so both platforms expose the same public API.)
    ///
    /// - Parameter unitId: The `wzrk_id` of the display unit that was viewed.
    /// - Returns: `true` if the event was sent, `false` if no CleverTap instance is available.
    @discardableResult
    public func pushViewedEvent(unitId: String) -> Bool {
        guard let ct = cleverTapInstance else { return false }
        seedIfNeeded(unitId: unitId, instance: ct)
        let sel = NSSelectorFromString("recordDisplayUnitViewedEventForID:")
        guard ct.responds(to: sel) else { return false }
        ct.perform(sel, with: unitId)
        return true
    }

    /// Push a display unit clicked event to the CleverTap Core SDK.
    ///
    /// Invokes `-[CleverTap recordDisplayUnitClickedEventForID:]` via
    /// `performSelector` to avoid a compile-time dependency on the CleverTap SDK.
    /// (See `pushViewedEvent` for the rationale behind the name asymmetry
    /// between the iOS / Android Core SDK selectors and the ND-SDK method.)
    ///
    /// - Parameter unitId: The `wzrk_id` of the display unit that was clicked.
    /// - Returns: `true` if the event was sent, `false` if no CleverTap instance is available.
    @discardableResult
    public func pushClickedEvent(unitId: String) -> Bool {
        guard let ct = cleverTapInstance else { return false }
        seedIfNeeded(unitId: unitId, instance: ct)
        let sel = NSSelectorFromString("recordDisplayUnitClickedEventForID:")
        guard ct.responds(to: sel) else { return false }
        ct.perform(sel, with: unitId)
        return true
    }

    /// Older-Core-SDK fallback: when the v7.x `setDisplayUnitCache:` attach
    /// API is unavailable (so `CleverTapAutoWire.attachCache` returned false),
    /// inject the unit's raw JSON directly into Core SDK's display-unit cache
    /// just before pushing the event so that `recordDisplayUnit*EventForID:`'s
    /// mandatory cache lookup succeeds.
    ///
    /// No-op when the cache is attached (the cache adapter already serves
    /// lookups).
    private func seedIfNeeded(unitId: String, instance ct: NSObject) {
        if CleverTapAutoWire.isCacheAttached { return }
        guard let raw = getNativeDisplayForId(unitId)?.rawJson,
              let data = raw.data(using: .utf8),
              let dict = (try? JSONSerialization.jsonObject(with: data)) as? [String: Any]
        else { return }
        ReflectionSeeder.seed(cleverTapInstance: ct, unitDicts: [dict])
    }

    // MARK: - Clear

    /// Clear all cached display units, tear down auto-wire, and reset state.
    ///
    /// Drains any in-flight parse work before clearing storage so that pending
    /// `cache.replaceAll`/`cache.put` writes from earlier `processDisplayUnit(s)`
    /// calls cannot land after the cache is cleared. `parseQueue.sync` blocks
    /// the caller until the queue is empty (FIFO drain).
    public func clear() {
        // Drain any outstanding parse work first so it cannot resurrect cache
        // state after we wipe it.
        parseQueue.sync { /* drain */ }
        cache.clearStorage()
        lock.lock()
        listeners.removeAllObjects()
        isInitialized = false
        lock.unlock()

        CleverTapAutoWire.tearDown()
        print("[NativeDisplayBridge] Cleared all cached units and listeners")
    }

    // MARK: - Private

    /// Notify all registered listeners on the main thread.
    ///
    /// Callers may invoke this from any queue (typically `parseQueue` after
    /// parsing finishes). The single `DispatchQueue.main.async` hop is the
    /// only main-thread transition in the entire process pipeline.
    private func notifyListeners(_ units: [NativeDisplayUnit]) {
        lock.lock()
        let currentListeners = listeners.allObjects.compactMap { $0 as? NativeDisplayBridgeListener }
        lock.unlock()

        if currentListeners.isEmpty { return }

        DispatchQueue.main.async {
            #if DEBUG
            dispatchPrecondition(condition: .onQueue(.main))
            #endif
            for listener in currentListeners {
                listener.onNativeDisplaysLoaded(units)
            }
        }
    }
}
