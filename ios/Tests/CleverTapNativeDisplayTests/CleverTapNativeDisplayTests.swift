import XCTest
@testable import CleverTapNativeDisplay

final class CleverTapNativeDisplayTests: XCTestCase {
    
    // MARK: - JSON Parsing Tests
    
    func testParseSimpleConfig() throws {
        let json = """
        {
            "theme": {
                "id": "default",
                "defaultStyle": {
                    "textColor": "#000000",
                    "fontSize": 14
                },
                "colors": {}
            },
            "styleClasses": [],
            "variables": {},
            "root": {
                "type": "container",
                "id": "root",
                "containerType": "vertical",
                "children": []
            }
        }
        """
        
        let config = try ResolvedConfig.from(jsonString: json)
        
        XCTAssertEqual(config.theme.id, "default")
        XCTAssertEqual(config.theme.defaultStyle.textColor, "#000000")
        XCTAssertEqual(config.theme.defaultStyle.fontSize, 14)
    }
    
    func testParseConfigWithElement() throws {
        let json = """
        {
            "theme": {
                "id": "default",
                "defaultStyle": {},
                "colors": {}
            },
            "styleClasses": [],
            "variables": {
                "userName": "John"
            },
            "root": {
                "type": "element",
                "id": "title",
                "elementType": "text",
                "bindings": {
                    "text": "Hello {{userName}}"
                }
            }
        }
        """
        
        let config = try ResolvedConfig.from(jsonString: json)
        
        if case .element(let element) = config.root {
            XCTAssertEqual(element.id, "title")
            XCTAssertEqual(element.elementType, .text)
            XCTAssertEqual(element.bindings["text"], "Hello {{userName}}")
        } else {
            XCTFail("Expected element node")
        }
    }
    
    // MARK: - Variable Evaluation Tests
    
    func testSimpleVariableEvaluation() {
        let variables: [String: AnyCodable] = [
            "userName": AnyCodable("John"),
            "count": AnyCodable(5)
        ]
        let evaluator = VariableEvaluator(variables: variables)
        
        XCTAssertEqual(evaluator.evaluateString("Hello {{userName}}!"), "Hello John!")
        XCTAssertEqual(evaluator.evaluateString("You have {{count}} items"), "You have 5 items")
    }
    
    func testBooleanEvaluation() {
        let variables: [String: AnyCodable] = [
            "isActive": AnyCodable(true),
            "count": AnyCodable(5)
        ]
        let evaluator = VariableEvaluator(variables: variables)
        
        XCTAssertTrue(evaluator.evaluateBoolean("{{isActive}}"))
        XCTAssertTrue(evaluator.evaluateBoolean("{{count > 0}}"))
        XCTAssertFalse(evaluator.evaluateBoolean("{{count < 0}}"))
    }
    
    func testComparisonOperators() {
        let variables: [String: AnyCodable] = [
            "value": AnyCodable(10)
        ]
        let evaluator = VariableEvaluator(variables: variables)
        
        XCTAssertTrue(evaluator.evaluateBoolean("{{value > 5}}"))
        XCTAssertTrue(evaluator.evaluateBoolean("{{value >= 10}}"))
        XCTAssertFalse(evaluator.evaluateBoolean("{{value < 5}}"))
        XCTAssertTrue(evaluator.evaluateBoolean("{{value <= 10}}"))
        XCTAssertTrue(evaluator.evaluateBoolean("{{value == 10}}"))
        XCTAssertFalse(evaluator.evaluateBoolean("{{value != 10}}"))
    }
    
    // MARK: - Style Resolution Tests
    
    func testStyleResolution() {
        let theme = Theme(
            id: "test",
            defaultStyle: Style(textColor: "#000000", fontSize: 14),
            colors: ["primary": "#FF0000"]
        )
        
        let styleClasses = [
            StyleClass(name: "title", style: Style(fontSize: 24, fontWeight: .bold))
        ]
        
        let resolver = StyleResolver(theme: theme, styleClasses: styleClasses)
        
        let element = NativeDisplayElement(
            id: "test",
            elementType: .text,
            bindings: [:],
            styleClass: "title"
        )
        
        let resolvedStyle = resolver.resolve(node: .element(element))
        
        XCTAssertEqual(resolvedStyle.textColor, "#000000") // From theme
        XCTAssertEqual(resolvedStyle.fontSize, 24) // From style class
        XCTAssertEqual(resolvedStyle.fontWeight, .bold) // From style class
    }
    
    func testInlineStyleOverride() {
        let theme = Theme(
            id: "test",
            defaultStyle: Style(textColor: "#000000", fontSize: 14)
        )
        
        let resolver = StyleResolver(theme: theme, styleClasses: [])
        
        let element = NativeDisplayElement(
            id: "test",
            elementType: .text,
            bindings: [:],
            style: Style(textColor: "#FF0000") // Override
        )
        
        let resolvedStyle = resolver.resolve(node: .element(element))
        
        XCTAssertEqual(resolvedStyle.textColor, "#FF0000") // Inline override
        XCTAssertEqual(resolvedStyle.fontSize, 14) // From theme
    }
    
    // MARK: - Dimension Tests
    
    func testDimensionCreation() {
        let dpDimension = Dimension.dp(100)
        XCTAssertEqual(dpDimension.value, 100)
        XCTAssertEqual(dpDimension.unit, .dp)
        XCTAssertNil(dpDimension.special)
        
        let percentDimension = Dimension.percent(50)
        XCTAssertEqual(percentDimension.value, 50)
        XCTAssertEqual(percentDimension.unit, .percent)
        
        XCTAssertEqual(Dimension.matchParent.special, .matchParent)
        XCTAssertEqual(Dimension.wrapContent.special, .wrapContent)
    }
    
    // MARK: - Spacing Tests
    
    func testSpacingResolution() {
        let spacing = Spacing(all: 16)
        XCTAssertEqual(spacing.resolveTop(), 16)
        XCTAssertEqual(spacing.resolveBottom(), 16)
        XCTAssertEqual(spacing.resolveLeft(), 16)
        XCTAssertEqual(spacing.resolveRight(), 16)
        
        let asymmetricSpacing = Spacing(horizontal: 8, vertical: 16)
        XCTAssertEqual(asymmetricSpacing.resolveTop(), 16)
        XCTAssertEqual(asymmetricSpacing.resolveBottom(), 16)
        XCTAssertEqual(asymmetricSpacing.resolveLeft(), 8)
        XCTAssertEqual(asymmetricSpacing.resolveRight(), 8)
        
        let specificSpacing = Spacing(top: 1, bottom: 2, left: 3, right: 4)
        XCTAssertEqual(specificSpacing.resolveTop(), 1)
        XCTAssertEqual(specificSpacing.resolveBottom(), 2)
        XCTAssertEqual(specificSpacing.resolveLeft(), 3)
        XCTAssertEqual(specificSpacing.resolveRight(), 4)
    }
    
    // MARK: - Color Parser Tests
    
    func testColorParsing() {
        XCTAssertNotNil(ColorParser.parse("#FF0000"))
        XCTAssertNotNil(ColorParser.parse("#00FF00"))
        XCTAssertNotNil(ColorParser.parse("#0000FF"))
        XCTAssertNotNil(ColorParser.parse("#FF000080")) // With alpha
        XCTAssertNil(ColorParser.parse(nil))
        XCTAssertNil(ColorParser.parse("invalid"))
    }
    
    // MARK: - Gallery Config Tests
    
    func testGalleryConfigDefaults() {
        let config = GalleryConfig()
        
        XCTAssertEqual(config.mode, .snapping)
        XCTAssertEqual(config.orientation, .horizontal)
        XCTAssertEqual(config.snapBehavior, .center)
        XCTAssertEqual(config.peekPercentage, 0)
        XCTAssertEqual(config.itemsPerView, 1)
        XCTAssertEqual(config.spacing, 8)
        XCTAssertFalse(config.showIndicators)
        XCTAssertEqual(config.autoScrollInterval, 0)
        XCTAssertFalse(config.infiniteScroll)
    }
    
    // MARK: - Background Tests
    
    func testLinearGradientBackground() throws {
        let json = """
        {
            "type": "linear_gradient",
            "angle": 45,
            "colors": ["#FF0000", "#00FF00", "#0000FF"]
        }
        """
        
        let data = json.data(using: .utf8)!
        let background = try JSONDecoder().decode(Background.self, from: data)
        
        if case .linearGradient(let gradient) = background {
            XCTAssertEqual(gradient.angle, 45)
            XCTAssertEqual(gradient.colors.count, 3)
        } else {
            XCTFail("Expected linear gradient background")
        }
    }
}
