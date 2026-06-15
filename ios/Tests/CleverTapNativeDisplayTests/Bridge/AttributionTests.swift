import XCTest
@testable import CleverTapNativeDisplay

// MARK: - Mock CleverTap Instance
//
// Minimal NSObject responding to the iOS Core SDK selectors via Swift's dynamic
// ObjC dispatch — no real CleverTap SDK is required. The bridge invokes these
// selectors via `performSelector` to avoid a compile-time CleverTap dependency.
//
// `MockCleverTapInstance` simulates a Core SDK build that exposes the NEW
// element-aware selector
// `-recordDisplayUnitElementClickedEventForID:additionalProperties:`
// AS WELL AS the legacy single-arg selectors. Used to verify the bridge prefers
// the new selector when present.

@objc private final class MockCleverTapInstance: NSObject {
    var viewedUnitIds: [String] = []
    var clickedUnitIds: [String] = []
    /// `(unitId, additionalProperties)` captured per new-selector call.
    var elementClicks: [(String, [String: Any])] = []

    @objc func recordDisplayUnitViewedEventForID(_ unitId: String) {
        viewedUnitIds.append(unitId)
    }

    @objc func recordDisplayUnitClickedEventForID(_ unitId: String) {
        clickedUnitIds.append(unitId)
    }

    @objc(recordDisplayUnitElementClickedEventForID:additionalProperties:)
    func recordDisplayUnitElementClickedEventForID(
        _ unitId: String,
        additionalProperties props: NSDictionary
    ) {
        elementClicks.append((unitId, props as? [String: Any] ?? [:]))
    }
}

/// Legacy CleverTap mock — responds only to the legacy single-arg selectors,
/// mirroring an older Core SDK version that has not yet shipped the
/// element-aware selector. Used to verify graceful fallback.
@objc private final class LegacyMockCleverTapInstance: NSObject {
    var viewedUnitIds: [String] = []
    var clickedUnitIds: [String] = []

    @objc func recordDisplayUnitViewedEventForID(_ unitId: String) {
        viewedUnitIds.append(unitId)
    }

    @objc func recordDisplayUnitClickedEventForID(_ unitId: String) {
        clickedUnitIds.append(unitId)
    }
}

/// Counts how often the bridge probes a specific selector via `responds(to:)`.
/// Otherwise behaves identically to `MockCleverTapInstance` — same selectors,
/// same captured state. Used to verify the bridge memoises the element-clicked
/// availability check across repeated clicks.
@objc private final class ProbeCountingCleverTapInstance: NSObject {
    var viewedUnitIds: [String] = []
    var clickedUnitIds: [String] = []
    var elementClicks: [(String, [String: Any])] = []

    /// Per-selector call count from `responds(to:)`. Read by tests.
    var respondsProbeCounts: [Selector: Int] = [:]

    @objc func recordDisplayUnitViewedEventForID(_ unitId: String) {
        viewedUnitIds.append(unitId)
    }

    @objc func recordDisplayUnitClickedEventForID(_ unitId: String) {
        clickedUnitIds.append(unitId)
    }

    @objc(recordDisplayUnitElementClickedEventForID:additionalProperties:)
    func recordDisplayUnitElementClickedEventForID(
        _ unitId: String,
        additionalProperties props: NSDictionary
    ) {
        elementClicks.append((unitId, props as? [String: Any] ?? [:]))
    }

    override func responds(to aSelector: Selector!) -> Bool {
        if let sel = aSelector {
            respondsProbeCounts[sel, default: 0] += 1
        }
        return super.responds(to: aSelector)
    }
}

// MARK: - Mock Action Listener
//
// Records `onDisplayUnitViewed` / `onDisplayUnitClicked` callbacks so tests
// can verify the listener path independently of the bridge push path.

@objc private final class MockActionListener: NSObject, NativeDisplayActionListener {
    var viewedUnitIds: [String] = []
    var clickedUnitIds: [String] = []
    var trackedEvents: [(name: String, props: [String: Any]?)] = []

    func onOpenUrl(url: String, openInBrowser: Bool) -> Bool { return false }
    func onCustomAction(key: String, value: Any?, metadata: [String: String]?) {}
    func onNavigate(destination: String, params: [String: String]?) {}

    func onTrackEvent(eventName: String, properties: [String: Any]?) {
        trackedEvents.append((eventName, properties))
    }

    func onDisplayUnitViewed(unitId: String) {
        viewedUnitIds.append(unitId)
    }

    func onDisplayUnitClicked(unitId: String) {
        clickedUnitIds.append(unitId)
    }
}

// MARK: - Tests

/// Covers the auto-attribution contract: `Notification Viewed` /
/// `Notification Clicked` system events fire to BOTH the optional client
/// `NativeDisplayActionListener` AND CleverTap Core SDK (via the bridge's
/// `pushViewedEvent` / `pushClickedEvent`) as soon as the bridge has a wired
/// `cleverTapInstance` — regardless of whether the client supplied a listener.
final class AttributionTests: XCTestCase {

    private var bridge: NativeDisplayBridge!

    override func setUp() {
        super.setUp()
        bridge = NativeDisplayBridge.shared
        // Singleton state hygiene — every test starts with no Core SDK wired.
        bridge.cleverTapInstance = nil
    }

    override func tearDown() {
        bridge.cleverTapInstance = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Drains the main actor by hopping to it once. `fireSystemEvent` schedules
    /// a `Task { @MainActor in ... }`; awaiting any main-actor work after it
    /// guarantees the scheduled task has run.
    private func waitForMainActor() async {
        await MainActor.run { /* no-op — barrier */ }
        // Two hops are needed because the Task body itself awaits MainActor
        // (it is created on whatever caller context invoked fireSystemEvent
        // and then transitions). A single hop is enough on iOS 15+ tasks but
        // we add a tiny RunLoop spin for safety on heavily-loaded CI hosts.
        await Task.yield()
        await MainActor.run { /* barrier 2 */ }
    }

    // MARK: - Listener present + bridge wired

    func test_viewed_firesBothListenerAndBridge_whenListenerPresentAndCleverTapWired() async {
        let mockCt = MockCleverTapInstance()
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: "unit_v_1"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed")
        await waitForMainActor()

        XCTAssertEqual(mockListener.viewedUnitIds, ["unit_v_1"], "Listener should receive viewed callback")
        XCTAssertEqual(mockCt.viewedUnitIds, ["unit_v_1"], "Bridge should forward to Core SDK")
        XCTAssertTrue(mockCt.clickedUnitIds.isEmpty)
        XCTAssertEqual(mockListener.trackedEvents.first?.name, "Notification Viewed")
    }

    func test_clicked_firesBothListenerAndBridge_whenListenerPresentAndCleverTapWired() async {
        let mockCt = MockCleverTapInstance()
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: "unit_c_1"
        )
        handler.fireSystemEvent(eventName: "Notification Clicked")
        await waitForMainActor()

        XCTAssertEqual(mockListener.clickedUnitIds, ["unit_c_1"])
        XCTAssertEqual(mockCt.clickedUnitIds, ["unit_c_1"])
        XCTAssertTrue(mockCt.viewedUnitIds.isEmpty)
    }

    // MARK: - Listener absent + bridge wired (the main motivation for Option A)

    func test_viewed_firesBridgeOnly_whenNoListenerButCleverTapWired() async {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: nil,
            componentListener: nil,
            unitId: "unit_v_2"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed")
        await waitForMainActor()

        XCTAssertEqual(
            mockCt.viewedUnitIds,
            ["unit_v_2"],
            "Bridge push must fire even when client supplied no NativeDisplayActionListener"
        )
    }

    func test_clicked_firesBridgeOnly_whenNoListenerButCleverTapWired() async {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: nil,
            componentListener: nil,
            unitId: "unit_c_2"
        )
        handler.fireSystemEvent(eventName: "Notification Clicked")
        await waitForMainActor()

        XCTAssertEqual(mockCt.clickedUnitIds, ["unit_c_2"])
    }

    // MARK: - Listener present + bridge NOT wired (standalone mode)

    func test_viewed_firesListenerOnly_whenCleverTapInstanceNil() async {
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = nil

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: "unit_v_3"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed")
        await waitForMainActor()

        XCTAssertEqual(
            mockListener.viewedUnitIds,
            ["unit_v_3"],
            "Listener path must still fire when Core SDK is absent"
        )
    }

    func test_clicked_firesListenerOnly_whenCleverTapInstanceNil() async {
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = nil

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: "unit_c_3"
        )
        handler.fireSystemEvent(eventName: "Notification Clicked")
        await waitForMainActor()

        XCTAssertEqual(mockListener.clickedUnitIds, ["unit_c_3"])
    }

    // MARK: - Listener absent + bridge NOT wired (full no-op)

    func test_viewed_isNoOp_whenNoListenerAndNoCleverTap() async {
        let mockCt = MockCleverTapInstance() // Created but NOT wired into bridge
        bridge.cleverTapInstance = nil

        let handler = ActionHandler(
            actionListener: nil,
            componentListener: nil,
            unitId: "unit_v_4"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed")
        await waitForMainActor()

        XCTAssertTrue(mockCt.viewedUnitIds.isEmpty, "Unwired Core SDK instance must never be invoked")
    }

    // MARK: - Dedup short-circuits BOTH paths

    func test_dedup_shortCircuitsListenerAndBridge_acrossViewedEvents() async {
        let mockCt = MockCleverTapInstance()
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: "unit_dd_1"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
        await waitForMainActor()
        handler.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
        await waitForMainActor()
        handler.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
        await waitForMainActor()

        XCTAssertEqual(mockListener.viewedUnitIds, ["unit_dd_1"], "Listener should only fire once with dedup")
        XCTAssertEqual(mockCt.viewedUnitIds, ["unit_dd_1"], "Bridge push should only fire once with dedup")
    }

    func test_dedup_independentBetweenViewedAndClicked() async {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: nil,
            componentListener: nil,
            unitId: "unit_dd_2"
        )
        handler.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
        handler.fireSystemEvent(eventName: "Notification Clicked", deduplicate: true)
        // Repeat — both should be deduped individually
        handler.fireSystemEvent(eventName: "Notification Viewed", deduplicate: true)
        handler.fireSystemEvent(eventName: "Notification Clicked", deduplicate: true)
        await waitForMainActor()

        XCTAssertEqual(mockCt.viewedUnitIds, ["unit_dd_2"])
        XCTAssertEqual(mockCt.clickedUnitIds, ["unit_dd_2"])
    }

    // MARK: - Element-aware selector (new Core SDK method)

    func test_clicked_prefersElementSelector_whenExtrasNonNilAndSelectorAvailable() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt
        let extras: [String: Any] = [
            "wzrk_element_id": "cta_buy",
            "action_type": "open_url",
            "action_url": "https://example.com"
        ]

        let ok = bridge.pushClickedEvent(unitId: "unit_x", extras: extras)

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.elementClicks.count, 1)
        // No legacy single-arg call when new selector handled it.
        XCTAssertTrue(mockCt.clickedUnitIds.isEmpty)

        let (unitId, props) = mockCt.elementClicks[0]
        XCTAssertEqual(unitId, "unit_x")
        // Attribution fields from BE metadata flow through additionalProperties directly.
        XCTAssertEqual(props["wzrk_element_id"] as? String, "cta_buy")
        XCTAssertEqual(props["action_type"] as? String, "open_url")
        XCTAssertEqual(props["action_url"] as? String, "https://example.com")
    }

    func test_clicked_fallsBackToLegacySelector_whenElementSelectorAbsent() {
        let legacyCt = LegacyMockCleverTapInstance()
        bridge.cleverTapInstance = legacyCt
        let extras: [String: Any] = ["wzrk_element_id": "cta_buy", "action_url": "https://x"]

        let ok = bridge.pushClickedEvent(unitId: "unit_legacy", extras: extras)

        XCTAssertTrue(ok, "Must still attribute the campaign click without per-element context")
        XCTAssertEqual(legacyCt.clickedUnitIds, ["unit_legacy"])
        // Graceful degradation — element id and action context are dropped.
    }

    func test_clicked_fallsBackToLegacySelector_whenExtrasNilOrEmpty() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        // nil extras → sanitize returns nil → legacy path
        let ok = bridge.pushClickedEvent(unitId: "unit_y", extras: nil)

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.clickedUnitIds, ["unit_y"])
        XCTAssertTrue(mockCt.elementClicks.isEmpty)
    }

    func test_clicked_singleArgPath_whenExtrasNil() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let ok = bridge.pushClickedEvent(unitId: "u_c", extras: nil)

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.clickedUnitIds, ["u_c"])
        XCTAssertTrue(mockCt.elementClicks.isEmpty, "Element selector must not be used when extras are nil")
    }

    // MARK: - Element-clicked selector availability cache

    func test_pushClickedEvent_probesElementSelectorOnceAcrossRepeatedClicks() {
        let mockCt = ProbeCountingCleverTapInstance()
        bridge.cleverTapInstance = mockCt
        let elementSel = NSSelectorFromString(
            "recordDisplayUnitElementClickedEventForID:additionalProperties:"
        )
        let extras: [String: Any] = ["wzrk_element_id": "cta_buy", "action_type": "open_url"]

        bridge.pushClickedEvent(unitId: "u1", extras: extras)
        bridge.pushClickedEvent(unitId: "u2", extras: extras)
        bridge.pushClickedEvent(unitId: "u3", extras: extras)

        XCTAssertEqual(mockCt.elementClicks.count, 3, "Each click should dispatch the new selector")
        XCTAssertEqual(
            mockCt.respondsProbeCounts[elementSel] ?? 0, 1,
            "Element-clicked selector availability should be probed at most once across N clicks"
        )
    }

    func test_rebindingCleverTapInstance_reprobesElementSelectorOnNextClick() {
        let firstCt = ProbeCountingCleverTapInstance()
        let secondCt = ProbeCountingCleverTapInstance()
        let elementSel = NSSelectorFromString(
            "recordDisplayUnitElementClickedEventForID:additionalProperties:"
        )
        let extras: [String: Any] = ["wzrk_element_id": "btn", "action_type": "open_url"]

        bridge.cleverTapInstance = firstCt
        bridge.pushClickedEvent(unitId: "u1", extras: extras)
        bridge.pushClickedEvent(unitId: "u2", extras: extras)
        XCTAssertEqual(firstCt.respondsProbeCounts[elementSel] ?? 0, 1)

        // Re-binding must invalidate the cache so the next click re-probes the new instance.
        bridge.cleverTapInstance = secondCt
        bridge.pushClickedEvent(unitId: "u3", extras: extras)
        bridge.pushClickedEvent(unitId: "u4", extras: extras)
        XCTAssertEqual(
            secondCt.respondsProbeCounts[elementSel] ?? 0, 1,
            "After rebinding the cache must be reset and the new instance probed exactly once"
        )
        XCTAssertEqual(secondCt.elementClicks.count, 2, "New instance receives the post-rebind clicks")
    }

    func test_nilUnitId_skipsBridgePushButStillFiresTrackEvent() async {
        let mockCt = MockCleverTapInstance()
        let mockListener = MockActionListener()
        bridge.cleverTapInstance = mockCt

        let handler = ActionHandler(
            actionListener: mockListener,
            componentListener: nil,
            unitId: nil // explicit
        )
        handler.fireSystemEvent(eventName: "Notification Viewed")
        handler.fireSystemEvent(eventName: "Notification Clicked")
        await waitForMainActor()

        // Track-event hook always fires (it's unconditional inside fireSystemEvent)
        XCTAssertEqual(mockListener.trackedEvents.count, 2)
        // But unit-id-specific callbacks and bridge pushes must NOT fire
        XCTAssertTrue(mockListener.viewedUnitIds.isEmpty)
        XCTAssertTrue(mockListener.clickedUnitIds.isEmpty)
        XCTAssertTrue(mockCt.viewedUnitIds.isEmpty)
        XCTAssertTrue(mockCt.clickedUnitIds.isEmpty)
    }
}
