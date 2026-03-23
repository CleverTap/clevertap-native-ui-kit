import XCTest
@testable import CleverTapNativeDisplay

// MARK: - Mock Listener

private class MockBridgeListener: NSObject, NativeDisplayBridgeListener {
    var loadedUnits: [NativeDisplayUnit] = []
    var loadedCallCount = 0
    var onLoaded: (() -> Void)?

    func onNativeDisplaysLoaded(_ units: [NativeDisplayUnit]) {
        loadedUnits = units
        loadedCallCount += 1
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

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 2)
        XCTAssertNotNil(bridge.getNativeDisplayForId("a1"))
        XCTAssertNotNil(bridge.getNativeDisplayForId("a2"))

        // Process list B -- should replace, not append
        let listB = [makeUnitJson(unitId: "b1")]
        bridge.processDisplayUnits(listB)

        let allUnits = bridge.getAllNativeDisplays()
        XCTAssertEqual(allUnits.count, 1, "processDisplayUnits should replace the entire cache")
        XCTAssertNotNil(bridge.getNativeDisplayForId("b1"))
        XCTAssertNil(bridge.getNativeDisplayForId("a1"), "Old units should be gone after replace")
        XCTAssertNil(bridge.getNativeDisplayForId("a2"), "Old units should be gone after replace")
    }

    // MARK: - processDisplayUnit adds to cache

    func testProcessDisplayUnitAddsToCacheIncrementally() {
        bridge.processDisplayUnit(makeUnitJson(unitId: "single_1"))

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1)
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_1"))

        bridge.processDisplayUnit(makeUnitJson(unitId: "single_2"))

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 2, "processDisplayUnit should add, not replace")
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_1"))
        XCTAssertNotNil(bridge.getNativeDisplayForId("single_2"))
    }

    func testProcessDisplayUnitUpdatesSameId() {
        bridge.processDisplayUnit(makeUnitJson(unitId: "dup", text: "Version1"))
        bridge.processDisplayUnit(makeUnitJson(unitId: "dup", text: "Version2"))

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1, "Same unitId should update, not duplicate")
    }

    // MARK: - getNativeDisplayForId

    func testGetNativeDisplayForId() {
        bridge.processDisplayUnits([
            makeUnitJson(unitId: "find_me"),
            makeUnitJson(unitId: "other")
        ])

        let found = bridge.getNativeDisplayForId("find_me")
        XCTAssertNotNil(found)
        XCTAssertEqual(found?.unitId, "find_me")
    }

    func testGetNativeDisplayForIdReturnsNilForUnknown() {
        bridge.processDisplayUnits([makeUnitJson(unitId: "known")])

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

        XCTAssertEqual(bridge.getAllNativeDisplays().count, 1, "Only valid ND units should be cached")
        XCTAssertNotNil(bridge.getNativeDisplayForId("valid"))
        XCTAssertNil(bridge.getNativeDisplayForId("invalid"))
    }
}
