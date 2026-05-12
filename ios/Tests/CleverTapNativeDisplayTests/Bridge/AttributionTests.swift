import XCTest
@testable import CleverTapNativeDisplay

// MARK: - Mock CleverTap Instance
//
// A minimal NSObject that responds to the iOS Core SDK selectors
// `recordDisplayUnitViewedEventForID:` and `recordDisplayUnitClickedEventForID:`
// (declared on `CleverTap (DisplayUnit)` in CleverTapSDK). The bridge invokes
// these via `performSelector` to avoid a compile-time CleverTap dependency, so
// Swift's dynamic ObjC dispatch on `@objc` methods of an `NSObject` subclass
// is enough — no real CleverTap SDK is required.

@objc private final class MockCleverTapInstance: NSObject {
    var viewedUnitIds: [String] = []
    var clickedUnitIds: [String] = []
    var viewedExtras: [[String: Any]] = []
    var clickedExtras: [[String: Any]] = []

    @objc func recordDisplayUnitViewedEventForID(_ unitId: String) {
        viewedUnitIds.append(unitId)
    }

    @objc func recordDisplayUnitClickedEventForID(_ unitId: String) {
        clickedUnitIds.append(unitId)
    }

    @objc func recordDisplayUnitViewedEventForID(_ unitId: String, additionalProperties props: NSDictionary) {
        viewedUnitIds.append(unitId)
        viewedExtras.append(props as? [String: Any] ?? [:])
    }

    @objc func recordDisplayUnitClickedEventForID(_ unitId: String, additionalProperties props: NSDictionary) {
        clickedUnitIds.append(unitId)
        clickedExtras.append(props as? [String: Any] ?? [:])
    }
}

/// Legacy CleverTap mock — responds only to the single-arg selectors, mirroring an
/// older Core SDK version that has not yet shipped the `additionalProperties:` overloads.
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

    // MARK: - additionalProperties overload (Core SDK PR #538 contract)

    func test_clicked_prefersTwoArgSelector_whenExtrasProvidedAndOverloadAvailable() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt
        let extras: [String: Any] = [
            "wzrk_btn_id": "cta_buy",
            "wzrk_action_type": "open_url",
            "action_url": "https://example.com"
        ]

        let ok = bridge.pushClickedEvent(unitId: "unit_x", extras: extras)

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.clickedUnitIds, ["unit_x"])
        XCTAssertEqual(mockCt.clickedExtras.count, 1)
        XCTAssertEqual(mockCt.clickedExtras.first?["wzrk_btn_id"] as? String, "cta_buy")
        XCTAssertEqual(mockCt.clickedExtras.first?["action_url"] as? String, "https://example.com")
    }

    func test_clicked_fallsBackToSingleArgSelector_whenOverloadAbsent() {
        let legacyCt = LegacyMockCleverTapInstance()
        bridge.cleverTapInstance = legacyCt
        let extras: [String: Any] = ["wzrk_btn_id": "cta_buy"]

        let ok = bridge.pushClickedEvent(unitId: "unit_legacy", extras: extras)

        XCTAssertTrue(ok, "Must still attribute the click on Core SDK without the new overload")
        XCTAssertEqual(legacyCt.clickedUnitIds, ["unit_legacy"])
    }

    func test_viewed_prefersTwoArgSelector_whenExtrasProvided() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let ok = bridge.pushViewedEvent(unitId: "u_v", extras: ["custom": "abc"])

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.viewedUnitIds, ["u_v"])
        XCTAssertEqual(mockCt.viewedExtras.first?["custom"] as? String, "abc")
    }

    func test_clicked_singleArgPath_whenExtrasNil() {
        let mockCt = MockCleverTapInstance()
        bridge.cleverTapInstance = mockCt

        let ok = bridge.pushClickedEvent(unitId: "u_c", extras: nil)

        XCTAssertTrue(ok)
        XCTAssertEqual(mockCt.clickedUnitIds, ["u_c"])
        XCTAssertTrue(mockCt.clickedExtras.isEmpty, "Two-arg selector must not be used when extras are nil")
    }

    // MARK: - nil unitId skips bridge push

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
