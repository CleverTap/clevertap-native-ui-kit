import XCTest
@testable import CleverTapNativeDisplay

/// Unit tests for `ActionAttributionExtras` — the pure helper that turns an `Action`
/// into a flat property bag for the Core SDK attribution overloads.
final class ActionAttributionExtrasTests: XCTestCase {

    // MARK: - nil action

    func test_from_withNilAction_returnsEmptyMap() {
        let extras = ActionAttributionExtras.from(action: nil)
        XCTAssertTrue(extras.isEmpty)
    }

    // MARK: - OpenUrl

    func test_from_openUrl_emitsUrlAndBrowserFlag() {
        let action = Action.openUrl(
            .init(url: "https://example.com", openInBrowser: true, customTabsEnabled: false)
        )
        let extras = ActionAttributionExtras.from(action: action)

        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "open_url")
        XCTAssertEqual(extras["action_url"] as? String, "https://example.com")
        XCTAssertEqual(extras["action_open_in_browser"] as? Bool, true)
        XCTAssertNil(extras["wzrk_btn_id"], "wzrk_btn_id transport marker must not be emitted")
    }

    // MARK: - CustomAction

    func test_from_customAction_spreadsDictionaryValueEntriesVerbatim() {
        let action = Action.custom(
            .init(
                key: "kv",
                value: AnyCodable(["sku": "SKU-123", "qty": 2] as [String: Any]),
                metadata: ["campaign": "summer_sale", "tier": "gold"]
            )
        )
        let extras = ActionAttributionExtras.from(action: action)

        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "custom")
        XCTAssertEqual(extras["action_key"] as? String, "kv")
        // Value entries land as first-class extras (no stringified action_value blob).
        XCTAssertNil(extras["action_value"], "action_value should not be set when value is a dictionary")
        XCTAssertEqual(extras["sku"] as? String, "SKU-123")
        XCTAssertEqual(extras["qty"] as? Int, 2)
        // metadata entries continue to spread verbatim alongside value entries
        XCTAssertEqual(extras["campaign"] as? String, "summer_sale")
        XCTAssertEqual(extras["tier"] as? String, "gold")
    }

    func test_from_customAction_scalarValueRoundTripsAsNativeType() {
        let action = Action.custom(.init(key: "k", value: AnyCodable(42), metadata: nil))
        let extras = ActionAttributionExtras.from(action: action)
        XCTAssertEqual(extras["action_value"] as? Int, 42)
    }

    func test_from_customAction_metadataWinsOnKeyCollisionWithValueEntries() {
        let action = Action.custom(
            .init(
                key: "kv",
                value: AnyCodable(["user_id": "from-value", "only_in_value": "v"] as [String: Any]),
                metadata: ["user_id": "from-meta", "only_in_meta": "m"]
            )
        )
        let extras = ActionAttributionExtras.from(action: action)

        // metadata is spread AFTER value entries -> last-write-wins on collision
        XCTAssertEqual(extras["user_id"] as? String, "from-meta")
        // non-colliding entries from both sides are preserved
        XCTAssertEqual(extras["only_in_value"] as? String, "v")
        XCTAssertEqual(extras["only_in_meta"] as? String, "m")
    }

    func test_from_customAction_emptyDictionaryValueEmitsNoSpreadEntries() {
        let action = Action.custom(
            .init(key: "kv", value: AnyCodable([String: Any]()), metadata: nil)
        )
        let extras = ActionAttributionExtras.from(action: action)

        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "custom")
        XCTAssertEqual(extras["action_key"] as? String, "kv")
        XCTAssertNil(extras["action_value"], "Empty dictionary value should not emit action_value")
        // Exactly the reserved keys, nothing else.
        XCTAssertEqual(
            Set(extras.keys),
            Set([ActionAttributionExtras.keyActionType, "action_key"])
        )
    }

    func test_from_customAction_metadataSpreadsBeInjectedWzrkAttributionFields() {
        let action = Action.custom(
            .init(
                key: "kv",
                value: AnyCodable([String: Any]()),
                metadata: [
                    "wzrk_element_id": "btn_hero",
                    "wzrk_btn_text": "Buy Now",
                    "wzrk_activity_type": "click"
                ]
            )
        )
        let extras = ActionAttributionExtras.from(action: action)

        // BE-injected wzrk_* fields arrive via metadata and flow through as-is
        XCTAssertEqual(extras["wzrk_element_id"] as? String, "btn_hero")
        XCTAssertEqual(extras["wzrk_btn_text"] as? String, "Buy Now")
        XCTAssertEqual(extras["wzrk_activity_type"] as? String, "click")
    }

    // MARK: - Navigate

    func test_from_navigate_emitsDestinationAndSpreadsParams() {
        let action = Action.navigate(
            .init(destination: "profile", params: ["user_id": "u-1"])
        )
        let extras = ActionAttributionExtras.from(action: action)
        XCTAssertEqual(extras[ActionAttributionExtras.keyActionType] as? String, "navigate")
        XCTAssertEqual(extras["action_destination"] as? String, "profile")
        XCTAssertEqual(extras["user_id"] as? String, "u-1")
        XCTAssertNil(extras["wzrk_btn_id"])
    }

    // MARK: - TrackEvent

    func test_from_trackEvent_emitsEventNameAndSpreadsProperties() {
        let action = Action.trackEvent(
            .init(
                eventName: "Banner Tapped",
                properties: ["position": AnyCodable(3), "is_hero": AnyCodable(true)]
            )
        )
        let extras = ActionAttributionExtras.from(action: action)
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
        let extras = ActionAttributionExtras.from(action: action)
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
