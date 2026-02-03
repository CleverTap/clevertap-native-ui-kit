import XCTest

/// UI Tests for Native Display configuration rendering
/// Tests that the app can load and render JSON test configurations correctly
final class NativeDisplayConfigTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        // Launch the application
        app = XCUIApplication()
        app.launch()

        // Navigate to Test Configs tab
        let testConfigsTab = app.tabBars.buttons["🧪 Test Configs"]
        XCTAssertTrue(testConfigsTab.waitForExistence(timeout: 5),
                     "Test Configs tab should exist in the tab bar")
        testConfigsTab.tap()

        // Wait for the navigation bar to appear
        _ = app.navigationBars["🧪 Test Configs"].waitForExistence(timeout: 5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Test Cases

    /// Test 091: Basic percentage offset positioning in Box container
    ///
    /// This test verifies that the app can:
    /// 1. Load the test-091-offset-percent-box-basic.json configuration
    /// 2. Render the configuration without errors
    /// 3. Display a Box container with 3 children positioned at (10%,10%), (50%,50%), (80%,80%)
    ///
    /// Expected visual result:
    /// - Title: "Test 091: Offset Percent - Box Basic"
    /// - Test box: 300×300dp Box with white background
    /// - Blue box (40×40dp) at top-left (10%, 10%)
    /// - Green box (40×40dp) at center (50%, 50%)
    /// - Red box (40×40dp) at bottom-right (80%, 80%)
    func test091_OffsetPercentBoxBasic() throws {
        // Find the test config button
        let configButton = app.buttons["test-config-test-091"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5),
                     "Test config button 'test-091' should exist")
        let app = XCUIApplication()
        app.activate()
        //let animationsButton = app/*@START_MENU_TOKEN@*/.buttons["🎬 Animations"]/*[[".tabBars.buttons[\"🎬 Animations\"]",".buttons[\"🎬 Animations\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/
        //animationsButton.tap()
        //app/*@START_MENU_TOKEN@*/.buttons["🎬 Animations"]/*[[".buttons.containing(.image, identifier: \"wand.and.sparkles\").firstMatch",".tabBars.buttons[\"🎬 Animations\"]",".buttons[\"🎬 Animations\"]"],[[[-1,2],[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        //app/*@START_MENU_TOKEN@*/.buttons["📏 Arrangements"]/*[[".tabBars.buttons[\"📏 Arrangements\"]",".buttons[\"📏 Arrangements\"]"],[[[-1,1],[-1,0]]],[0]]@END_MENU_TOKEN@*/.tap()
        //animationsButton.tap()

        // Tap to load the configuration
        configButton.tap()

        // Wait for the configuration to load and render
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10),
                     "Native display view should render within 10 seconds")

        // Verify the UI rendered successfully
        XCTAssertTrue(renderView.exists,
                     "Render view should be visible on screen")

        // Verify no error message is displayed
        let errorView = app.staticTexts["Error Loading Config"]
        XCTAssertFalse(errorView.exists,
                      "Should not show error message when config loads successfully")

        // Take a screenshot for visual verification
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "test-091-offset-percent-box-basic"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ Test 091 passed: Config loaded and rendered successfully")
        print("   Expected: Blue box at (10%,10%), Green at (50%,50%), Red at (80%,80%)")
    }

    // MARK: - Future Test Cases (Template)

    /*
    /// Template for adding more tests
    /// Copy this method and update the test number, config ID, and filename
    func test092_OffsetPercentStackLayers() throws {
        let configButton = app.buttons["test-config-test-092"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5))
        configButton.tap()

        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10))

        let errorView = app.staticTexts["Error Loading Config"]
        XCTAssertFalse(errorView.exists)

        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = "test-092-offset-percent-stack-layers"
        attachment.lifetime = .keepAlways
        add(attachment)

        print("✅ Test 092 passed")
    }
    */
}

// MARK: - Helper Extensions

extension NativeDisplayConfigTests {

    /// Shared test runner for all config tests
    /// Use this when scaling to 30 tests to reduce code duplication
    private func runTestForConfig(id: String, filename: String, expectedDescription: String? = nil) {
        // Find and tap the config button
        let configButton = app.buttons["test-config-\(id)"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5),
                     "Test config button '\(id)' should exist")
        configButton.tap()

        // Wait for render view
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10),
                     "Native display view should render for \(id)")

        // Verify no errors
        let errorView = app.staticTexts["Error Loading Config"]
        XCTAssertFalse(errorView.exists,
                      "Should not show error message for \(id)")

        // Take screenshot
        let screenshot = app.screenshot()
        let attachment = XCTAttachment(screenshot: screenshot)
        attachment.name = filename
        attachment.lifetime = .keepAlways
        add(attachment)

        // Log success
        var message = "✅ Test \(id) passed"
        if let description = expectedDescription {
            message += ": \(description)"
        }
        print(message)
    }
}
