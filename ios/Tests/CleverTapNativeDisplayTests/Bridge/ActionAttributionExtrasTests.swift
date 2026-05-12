import XCTest
@testable import CleverTapNativeDisplay

/// Unit tests for `ActionAttributionExtras` — the pure helper that turns an `Action`
/// into a flat property bag for the Core SDK attribution overloads.
final class ActionAttributionExtrasTests: XCTestCase {

    // MARK: - nodeId only / nil action

    func test_from_withNilAction_emitsOnlyButtonId() {
        let extras = ActionAttributionExtras.from(action: nil, nodeId: "cta_buy")
        XCTAssertEqual(extras[ActionAttributionExtras.keyButtonId] as? String, "cta_buy")
        XCTAssertNil(extras[ActionAttributionExtras.keyActionType])
    }

    func test_from_withEmptyNodeId_skipsButtonId() {
        let extras = ActionAttributionExtras.from(action: nil, nodeId: "")
        XCTAssertNil(extras[ActionAttributionExtras.keyButtonId])
    }

    // MARK: - OpenUrl

    func test_from_openUrl_emitsUrlAndBrowserFlag() {
        let action = Action.openUrl(
            .init(url: "https://example.com", openInBrowser: true, customTabsEnabled: false)
        )
        let extras = ActionAttributionExtras.from(action: action, nodeId: "btn1")

        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "open_url")
        XCTAssertEqual(extras["action_url"] as? String, "https://example.com")
        XCTAssertEqual(extras["action_open_in_browser"] as? Bool, true)
        XCTAssertEqual(extras[ActionAttributionExtras.keyButtonId] as? String, "btn1")
    }

    // MARK: - CustomAction

    func test_from_customAction_spreadsMetadataAndStringifiesNestedValue() {
        let action = Action.custom(
            .init(
                key: "add_to_cart",
                value: AnyCodable(["sku": "SKU-123", "qty": 2] as [String: Any]),
                metadata: ["campaign": "summer_sale", "tier": "gold"]
            )
        )
        let extras = ActionAttributionExtras.from(action: action, nodeId: "btn2")

        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "custom")
        XCTAssertEqual(extras["action_key"] as? String, "add_to_cart")
        // Nested value lands as a JSON string so the dashboard captures the full payload.
        let serialized = extras["action_value"] as? String
        XCTAssertNotNil(serialized)
        XCTAssertTrue(serialized!.contains("\"sku\""), "value should serialize as JSON: \(serialized ?? "nil")")
        // metadata spreads verbatim
        XCTAssertEqual(extras["campaign"] as? String, "summer_sale")
        XCTAssertEqual(extras["tier"] as? String, "gold")
    }

    func test_from_customAction_scalarValueRoundTripsAsNativeType() {
        let action = Action.custom(.init(key: "k", value: AnyCodable(42), metadata: nil))
        let extras = ActionAttributionExtras.from(action: action, nodeId: "btn3")
        XCTAssertEqual(extras["action_value"] as? Int, 42)
    }

    // MARK: - Navigate

    func test_from_navigate_emitsDestinationAndSpreadsParams() {
        let action = Action.navigate(
            .init(destination: "profile", params: ["user_id": "u-1"])
        )
        let extras = ActionAttributionExtras.from(action: action, nodeId: nil)
        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "navigate")
        XCTAssertEqual(extras["action_destination"] as? String, "profile")
        XCTAssertEqual(extras["user_id"] as? String, "u-1")
    }

    // MARK: - TrackEvent

    func test_from_trackEvent_emitsEventNameAndSpreadsProperties() {
        let action = Action.trackEvent(
            .init(
                eventName: "Banner Tapped",
                properties: ["position": AnyCodable(3), "is_hero": AnyCodable(true)]
            )
        )
        let extras = ActionAttributionExtras.from(action: action, nodeId: "btn4")
        XCTAssertEqual(extras["action_event_name"] as? String, "Banner Tapped")
        XCTAssertEqual(extras["position"] as? Int, 3)
        XCTAssertEqual(extras["is_hero"] as? Bool, true)
    }

    // MARK: - Composite

    func test_from_composite_emitsCountAndMode() {
        let action = Action.composite(
            .init(
                actions: [
                    .openUrl(.init(url: "https://a.example", openInBrowser: false, customTabsEnabled: true)),
                    .navigate(.init(destination: "home", params: nil))
                ],
                executionMode: .parallel
            )
        )
        let extras = ActionAttributionExtras.from(action: action, nodeId: "btn5")
        XCTAssertEqual(extras["action_count"] as? Int, 2)
        XCTAssertEqual(extras["action_mode"] as? String, "parallel")
    }

    // MARK: - sanitize

    func test_sanitize_dropsEmptyAndNilStripsEmptyKeys() {
        let sanitized = ActionAttributionExtras.sanitize([:])
        XCTAssertNil(sanitized)
        XCTAssertNil(ActionAttributionExtras.sanitize(nil))
    }

    func test_sanitize_keepsScalarsAndCollections() {
        let input: [String: Any] = [
            "s": "x",
            "i": 1,
            "d": 1.5,
            "b": true,
            "arr": [1, 2, 3],
            "obj": ["k": "v"]
        ]
        let sanitized = ActionAttributionExtras.sanitize(input)
        XCTAssertEqual(sanitized?["s"] as? String, "x")
        XCTAssertEqual(sanitized?["i"] as? Int, 1)
        XCTAssertEqual(sanitized?["d"] as? Double, 1.5)
        XCTAssertEqual(sanitized?["b"] as? Bool, true)
        XCTAssertEqual((sanitized?["arr"] as? [Int]) ?? [], [1, 2, 3])
        XCTAssertEqual((sanitized?["obj"] as? [String: String])?["k"], "v")
    }

    func test_sanitize_dropsEmptyStringKeys() {
        let sanitized = ActionAttributionExtras.sanitize(["": "ignored", "k": "kept"])
        XCTAssertNil(sanitized?[""])
        XCTAssertEqual(sanitized?["k"] as? String, "kept")
    }
}
