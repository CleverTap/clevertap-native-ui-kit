import XCTest
@testable import CleverTapNativeDisplay

final class NativeDisplayConfigParserTests: XCTestCase {

    private var parser: NativeDisplayConfigParser!

    override func setUp() {
        super.setUp()
        parser = NativeDisplayConfigParser()
    }

    override func tearDown() {
        parser = nil
        super.tearDown()
    }

    // MARK: - Helpers

    /// Minimal valid ResolvedConfig JSON.
    private static let minimalConfigJson = """
    {
        "root": {
            "type": "element",
            "elementType": "text",
            "bindings": { "text": "Hello" },
            "layout": {
                "width": { "special": "match_parent" },
                "height": { "special": "wrap_content" }
            }
        }
    }
    """

    /// Wraps a ResolvedConfig JSON inside a display unit envelope with `native_display_config`.
    private static func displayUnitJson(
        unitId: String = "test_unit_1",
        slotId: String? = nil,
        config: String = minimalConfigJson,
        customKV: String? = "{ \"key1\": \"value1\" }"
    ) -> String {
        var parts: [String] = []
        parts.append("\"wzrk_id\": \"\(unitId)\"")
        if let slot = slotId {
            parts.append("\"slot_id\": \"\(slot)\"")
        }
        parts.append("\"type\": \"native_display\"")
        parts.append("\"native_display_config\": \(config)")
        if let kv = customKV {
            parts.append("\"custom_kv\": \(kv)")
        }
        return "{ \(parts.joined(separator: ", ")) }"
    }

    // MARK: - Strategy 1: native_display_config key

    func testParseNativeDisplayConfigKey() {
        let json = Self.displayUnitJson(slotId: "hero_banner")

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit, "Should parse a valid display unit with native_display_config")
        XCTAssertEqual(unit?.unitId, "test_unit_1")
        XCTAssertEqual(unit?.slotId, "hero_banner")
        XCTAssertEqual(unit?.customExtras["key1"], "value1")

        // Verify the config root is a text element
        if case .element(let element) = unit?.config.root {
            XCTAssertEqual(element.elementType, .text)
            XCTAssertEqual(element.bindings["text"], "Hello")
        } else {
            XCTFail("Expected element node in parsed config root")
        }
    }

    // MARK: - Root-level slot_id

    func testParseWithoutSlotIdLeavesNil() {
        let json = Self.displayUnitJson()

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit)
        XCTAssertNil(unit?.slotId, "Missing slot_id should leave the field nil")
    }

    func testParseEmptySlotIdNormalisedToNil() {
        let json = Self.displayUnitJson(slotId: "")

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit)
        XCTAssertNil(unit?.slotId, "Empty slot_id should be normalised to nil")
    }

    func testParseIgnoresSlotIdNestedUnderCustomKV() {
        // Old contract — slot_id used to live under custom_kv. New contract puts it at the root.
        let json = """
        {
            "wzrk_id": "unit_legacy_slot",
            "native_display_config": \(Self.minimalConfigJson),
            "custom_kv": { "slot_id": "legacy_slot" }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit)
        XCTAssertNil(unit?.slotId, "slot_id under custom_kv must not populate the slot field")
    }

    // MARK: - Strategy 2: custom_kv.nd_config fallback

    func testParseCustomKVFallback() {
        // The nd_config value is a JSON *string* inside custom_kv
        let escapedConfig = Self.minimalConfigJson
            .replacingOccurrences(of: "\\", with: "\\\\")
            .replacingOccurrences(of: "\"", with: "\\\"")
            .replacingOccurrences(of: "\n", with: "\\n")

        let json = """
        {
            "wzrk_id": "unit_kv",
            "custom_kv": {
                "nd_config": "\(escapedConfig)",
                "extra_key": "extra_value"
            }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit, "Should parse via custom_kv.nd_config fallback")
        XCTAssertEqual(unit?.unitId, "unit_kv")
        // nd_config should be excluded from customExtras
        XCTAssertNil(unit?.customExtras["nd_config"])
        XCTAssertEqual(unit?.customExtras["extra_key"], "extra_value")
    }

    // MARK: - Strategy 3: root key fallback

    func testParseRootKeyFallback() {
        // JSON that IS a ResolvedConfig but also has wzrk_id
        let json = """
        {
            "wzrk_id": "unit_root",
            "root": {
                "type": "element",
                "elementType": "text",
                "bindings": { "text": "Direct" },
                "layout": {
                    "width": { "special": "match_parent" },
                    "height": { "special": "wrap_content" }
                }
            }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit, "Should parse when root key is present directly")
        XCTAssertEqual(unit?.unitId, "unit_root")
    }

    // MARK: - Non-ND unit

    func testNonNDUnitReturnsNil() {
        let json = """
        {
            "wzrk_id": "banner_123",
            "type": "banner",
            "title": "Some banner"
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNil(unit, "Non-ND display unit should return nil")
    }

    // MARK: - Missing wzrk_id

    func testMissingWzrkIdReturnsNil() {
        // Valid ND config but no wzrk_id
        let json = """
        {
            "native_display_config": \(Self.minimalConfigJson)
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNil(unit, "Missing wzrk_id should return nil")
    }

    // MARK: - Malformed JSON

    func testMalformedJsonReturnsNil() {
        let unit = parser.tryParse("{ this is not valid json }")

        XCTAssertNil(unit, "Malformed JSON should return nil without crashing")
    }

    func testEmptyStringReturnsNil() {
        let unit = parser.tryParse("")

        XCTAssertNil(unit, "Empty string should return nil")
    }

    // MARK: - Missing root in native_display_config

    func testMissingRootReturnsNil() {
        let json = """
        {
            "wzrk_id": "unit_no_root",
            "native_display_config": {
                "theme": { "id": "default", "defaultStyle": {} }
            }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNil(unit, "native_display_config without root should return nil")
    }

    func testNullRootReturnsNil() {
        let json = """
        {
            "wzrk_id": "unit_null_root",
            "native_display_config": {
                "root": null
            }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNil(unit, "native_display_config with null root should return nil")
    }

    // MARK: - Data-based parsing

    func testParseFromData() {
        let json = Self.displayUnitJson()
        let data = json.data(using: .utf8)!

        let unit = parser.tryParse(data: data)

        XCTAssertNotNil(unit)
        XCTAssertEqual(unit?.unitId, "test_unit_1")
    }

    // MARK: - Custom extras extraction

    func testCustomExtrasWithNumericValues() {
        let json = """
        {
            "wzrk_id": "unit_extras",
            "native_display_config": \(Self.minimalConfigJson),
            "custom_kv": {
                "str_key": "str_value",
                "num_key": 42,
                "bool_key": true
            }
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit)
        XCTAssertEqual(unit?.customExtras["str_key"], "str_value")
        // Numeric values should be converted to strings
        XCTAssertEqual(unit?.customExtras["num_key"], "42")
    }

    func testNoCustomKVReturnsEmptyExtras() {
        let json = """
        {
            "wzrk_id": "unit_no_kv",
            "native_display_config": \(Self.minimalConfigJson)
        }
        """

        let unit = parser.tryParse(json)

        XCTAssertNotNil(unit)
        XCTAssertTrue(unit?.customExtras.isEmpty == true)
    }
}
