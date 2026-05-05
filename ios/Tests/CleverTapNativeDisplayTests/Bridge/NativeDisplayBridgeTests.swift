import XCTest
@testable import CleverTapNativeDisplay

// MARK: - Mock Listener

private class MockBridgeListener: NSObject, NativeDisplayBridgeListener {
    var loadedUnits: [NativeDisplayUnit] = []
    var loadedCallCount = 0
    var onLoaded: (() -> Void)?
    /// Variant callback that receives the units argument — useful for FIFO tests.
    var onLoadedUnits: (([NativeDisplayUnit]) -> Void)?

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        loadedUnits = units
        loadedCallCount += 1
        onLoadedUnits?(units)
        onLoaded?()
    }
}

// MARK: - Tests

final class NativeDisplayBridgeTests: XCTestCase {

    private var bridge: NativeDisplayBridge!

    override func setUp() {
        super.setUp()
        bridge = NativeDisplayBridge.shared
    }

    override func tearDown() {
        bridge.clear()
        super.tearDown()
    }

    // MARK: - Helpers

    /// Build a minimal valid display unit JSON string.
    private func makeUnitJson(unitId: String, text: String = "Hello") -> String {
        return """
        {
            "wzrk_id": "\(unitId)",
            "native_display_config": {
                "root": {
                    "type": "element",
                    "elementType": "text",
                    "bindings": { "text": "\(text)" },
                    "layout": {
                        "width": { "special": "match_parent" },
                        "height": { "special": "wrap_content" }
                    }
                }
            }
        }
        """
    }

    // MARK: - Singleton

    func testSharedReturnsSameInstance() {
        let instance1 = NativeDisplayBridge.shared
        let instance2 = NativeDisplayBridge.shared
        XCTAssertTrue(instance1 === instance2, "shared should return the same instance")
    }

    // MARK: - processDisplayUnits replaces cache

    func testProcessDisplayUnitsReplacesCache() {
        let listA = [makeUnitJson(unitId: "a1"), makeUnitJson(unitId: "a2")]
        bridge.processDisplayUnits(listA)
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 2)
        XCTAssertNotNil(bridge.getNativeDisplayForId("a1"))
        XCTAssertNotNil(bridge.getNativeDisplayForId("a2"))

        // Process list B -- should replace, not append
        let listB = [makeUnitJson(unitId: "b1")]
        bridge.processDisplayUnits(listB)
        bridge._waitUntilIdle()

        let allUnits = bridge.getAllNativeDisplays()
        XCTAssertEqual(allUnits.count, 1, "processDisplayUnits should replace the entire cache")
        XCTAssertNotNil(bridge.getNativeDisplayForId("b1"))
        XCTAssertNil(bridge.getNativeDisplayForId("a1"), "Old units should be gone after replace")
        XCTAssertNil(bridge.getNativeDisplayForId("a2"), "Old units should be gone after replace")
    }

    // MARK: - processDisplayUnit adds to cache

    func testProcessDisplayUnitAddsToCacheIncrementally() {
        bridge.processDisplayUnit(makeUnitJson(unitId: "single_1"))
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1)
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_1"))

        bridge.processDisplayUnit(makeUnitJson(unitId: "single_2"))
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 2, "processDisplayUnit should add, not replace")
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_1"))
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_2"))
    }

    func testProcessDisplayUnitUpdatesSameId() {
        bridge.processDisplayUnit(makeUnitJson(unitId: "dup", text: "Version1"))
        bridge.processDisplayUnit(makeUnitJson(unitId: "dup", text: "Version2"))
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1, "Same unitId should update, not duplicate")
    }

    // MARK: - getNativeDisplayForId

    func testGetNativeDisplayForId() {
        bridge.processDisplayUnits([
            makeUnitJson(unitId: "find_me"),
            makeUnitJson(unitId: "other")
        ])
        bridge._waitUntilIdle()

        let found = bridge.getNativeDisplayForId("find_me")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.unitId, "find_me")
    }

    func testGetNativeDisplayForIdReturnsNilForUnknown() {
        bridge.processDisplayUnits([makeUnitJson(unitId: "known")])
        bridge._waitUntilIdle()

        XCTAssertNil(bridge.getNativeDisplayForId("unknown"), "Should return nil for unknown ID")
    }

    // MARK: - Listener notification

    func testListenerNotifiedOnProcessDisplayUnits() {
        let listener = MockBridgeListener()
        let expectation = expectation(description: "Listener should be notified")

        listener.onLoaded = {
            expectation.fulfill()
        }

        bridge.addListener(listener)
        bridge.processDisplayUnits([makeUnitJson(unitId: "notified_1")])

        waitForExpectations(timeout: 2)
        XCTAssertEqual(listener.loadedUnits.count, 1)
        XCTAssertEqual(listener.loadedCallCount, 1)
    }

    func testListenerNotifiedOnProcessSingleUnit() {
        let listener = MockBridgeListener()
        let expectation = expectation(description: "Listener should be notified for single unit")

        listener.onLoaded = {
            expectation.fulfill()
        }

        bridge.addListener(listener)
        bridge.processDisplayUnit(makeUnitJson(unitId: "single_notify"))

        waitForExpectations(timeout: 2)
        XCTAssertEqual(listener.loadedUnits.count, 1)
    }

    func testListenerNotifiedMultipleTimes() {
        let listener = MockBridgeListener()
        let expectation = expectation(description: "Listener notified twice")
        expectation.expectedFulfillmentCount = 2

        listener.onLoaded = {
            expectation.fulfill()
        }

        bridge.addListener(listener)
        bridge.processDisplayUnit(makeUnitJson(unitId: "multi_1"))
        bridge.processDisplayUnit(makeUnitJson(unitId: "multi_2"))

        waitForExpectations(timeout: 2)
        XCTAssertEqual(listener.loadedCallCount, 2)
        // After both calls, cache should have both units
        XCTAssertEqual(listener.loadedUnits.count, 2)
    }

    func testRemoveListenerStopsNotifications() {
        let listener = MockBridgeListener()

        bridge.addListener(listener)
        bridge.removeListener(listener)
        bridge.processDisplayUnits([makeUnitJson(unitId: "removed")])

        // Give the main queue time to dispatch (it should NOT call the listener)
        let expectation = expectation(description: "Wait for potential notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(listener.loadedCallCount, 0, "Removed listener should not be notified")
    }

    // MARK: - clear()

    func testClearEmptiesCache() {
        bridge.processDisplayUnits([
            makeUnitJson(unitId: "clear_1"),
            makeUnitJson(unitId: "clear_2")
        ])
        bridge._waitUntilIdle()
        XCTAssertEqual(bridge.getAllNativeDisplays().count, 2)

        bridge.clear()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 0, "Cache should be empty after clear()")
        XCTAssertNil(bridge.getNativeDisplayForId("clear_1"))
    }

    func testClearRemovesListeners() {
        let listener = MockBridgeListener()
        bridge.addListener(listener)
        bridge.clear()

        // Process after clear -- listener should not be notified
        bridge.processDisplayUnits([makeUnitJson(unitId: "post_clear")])

        let expectation = expectation(description: "Wait for potential notification")
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            expectation.fulfill()
        }
        waitForExpectations(timeout: 2)

        XCTAssertEqual(listener.loadedCallCount, 0, "Listeners should be removed after clear()")
    }

    // MARK: - processDisplayUnits(data:)

    func testProcessDisplayUnitsWithData() {
        let json = makeUnitJson(unitId: "data_unit")
        let data = json.data(using: .utf8)!

        bridge.processDisplayUnits(data: [data])
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1)
        XCTAssertNotNil(bridge.getNativeDisplayForId("data_unit"))
    }

    // MARK: - Invalid units are skipped

    func testInvalidUnitsSkippedInBatch() {
        let validJson = makeUnitJson(unitId: "valid")
        let invalidJson = """
        { "wzrk_id": "invalid", "type": "banner" }
        """

        bridge.processDisplayUnits([validJson, invalidJson])
        bridge._waitUntilIdle()

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1, "Only valid ND units should be cached")
        XCTAssertNotNil(bridge.getNativeDisplayForId("valid"))
        XCTAssertNil(bridge.getNativeDisplayForId("invalid"))
    }

    // MARK: - SDK-5770: Off-main parsing

    /// `processDisplayUnits(_:)` must hand parsing to the bridge's serial
    /// parse queue rather than blocking the main thread. We assert listener
    /// delivery on main and queue label/main-thread-ness via `_runOnParseQueue`.
    func testParsingHappensOffMainAndListenerDeliveryOnMain() {
        let listener = MockBridgeListener()
        let listenerOnMain = expectation(description: "Listener fires on main")
        listener.onLoaded = {
            XCTAssertTrue(Thread.isMainThread, "Listener should be delivered on main")
            let label = String(cString: __dispatch_queue_get_label(nil))
            XCTAssertEqual(label, "com.apple.main-thread")
            listenerOnMain.fulfill()
        }
        bridge.addListener(listener)

        XCTAssertTrue(Thread.isMainThread)
        bridge.processDisplayUnits([makeUnitJson(unitId: "offmain_1")])

        waitForExpectations(timeout: 2)
        XCTAssertEqual(listener.loadedCallCount, 1)
    }

    /// Parse work runs on the bridge's labelled serial queue, not on main.
    /// We assert this by hopping onto the parse queue ourselves and inspecting
    /// queue label + thread identity.
    func testParseQueueIsNonMainAndLabelled() {
        XCTAssertTrue(Thread.isMainThread, "test driver should start on main")

        let label: String = bridge._runOnParseQueue {
            String(cString: __dispatch_queue_get_label(nil))
        }
        let isMainOnQueue: Bool = bridge._runOnParseQueue { Thread.isMainThread }

        XCTAssertEqual(label, NativeDisplayBridge._parseQueueLabel,
                       "Parse queue label must match the documented identifier")
        XCTAssertNotEqual(label, "com.apple.main-thread")
        XCTAssertFalse(isMainOnQueue, "Work submitted to parseQueue must not run on main")
    }

    /// Submission ordering across rapid processDisplayUnits calls must be
    /// FIFO. Ten distinct payloads enqueued from main in a tight loop must
    /// arrive at the listener in the same order they were submitted.
    func testFifoOrderingAcrossRapidProcessDisplayUnitsCalls() {
        let listener = MockBridgeListener()
        let count = 10
        let allDelivered = expectation(description: "Listener fires \(count) times")
        allDelivered.expectedFulfillmentCount = count

        var observed: [String] = []
        listener.onLoadedUnits = { units in
            // Each batch is a single-element payload — capture the lone unit ID.
            if let id = units.first?.unitId { observed.append(id) }
            allDelivered.fulfill()
        }
        bridge.addListener(listener)

        // Submit 10 distinct payloads from main in a tight loop.
        let ids = (0..<count).map { "rapid_\($0)" }
        for id in ids {
            bridge.processDisplayUnits([makeUnitJson(unitId: id)])
        }

        waitForExpectations(timeout: 5)

        XCTAssertEqual(observed.count, count, "Listener should observe all \(count) batches")
        XCTAssertEqual(observed, ids, "FIFO ordering must be preserved")
    }

    // MARK: - SDK-5770: Pre-resolved styles on cached units

    /// Each cached unit must carry a pre-resolved style map populated by the
    /// parser at parse-time (off-main). This eliminates the on-main
    /// `StyleResolver.resolveAll` walk inside `NativeDisplayView.init`.
    func testCachedUnitCarriesPreResolvedStyles() {
        bridge.processDisplayUnits([makeUnitJson(unitId: "styled_1")])
        bridge._waitUntilIdle()

        guard let unit = bridge.getNativeDisplayForId("styled_1") else {
            XCTFail("Expected unit to be cached")
            return
        }
        XCTAssertNotNil(unit.resolvedStyles, "Bridge-cached units must include a pre-resolved style map")
        XCTAssertTrue(unit.resolvedStyles?.keys.contains(unit.config.root.id) ?? false,
                      "resolvedStyles must include the root node id")
    }
}
