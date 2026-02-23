import XCTest

/// UI Tests for Native Display configuration rendering.
///
/// Automatically discovers and tests all JSON configs displayed in the Test Configs browser.
/// Each config is loaded, rendered, verified for errors, and a screenshot is captured.
///
/// The test iterates through all "test-config-*" buttons visible in the app's Test Configs
/// screen, so adding a new JSON file to the bundle automatically includes it in testing.
final class NativeDisplayConfigTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false

        app = XCUIApplication()
        app.launch()

        // Tap the ellipsis menu button to open the demo menu sheet
        let menuButton = app.buttons["ellipsis.circle"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5),
                     "Ellipsis menu button should exist in the toolbar")
        menuButton.tap()

        // Tap "Test Configs" in the demo menu
        let testConfigsLink = app.staticTexts["Test Configs"]
        XCTAssertTrue(testConfigsLink.waitForExistence(timeout: 5),
                     "Test Configs menu item should exist in the demo menu")
        testConfigsLink.tap()

        // Wait for the Test Configs view to appear
        _ = app.navigationBars["🧪 Test Configs"].waitForExistence(timeout: 5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Data-Driven Test Runner

    /// Runs all test configurations found in the Test Configs browser.
    ///
    /// This single test method:
    /// 1. Queries the app for all buttons whose accessibility identifier matches "test-config-test-*"
    /// 2. Iterates through each, tapping to load and render
    /// 3. Verifies the NativeDisplayView appears (no decode/load failure)
    /// 4. Verifies no error message is shown
    /// 5. Captures a screenshot attachment per config for visual review
    ///
    /// To add a new test config, just add the JSON to the bundle — no test code changes needed.
    func testAllConfigs() throws {
        // Locate the config list scroll area (for targeted scrolling)
        // Use descendants(matching: .any) since SwiftUI may expose the identifier
        // under different element types (scrollView, other, group, etc.)
        let configListPredicate = NSPredicate(format: "identifier == %@", "test-config-list")
        let configList = app.descendants(matching: .any).matching(configListPredicate).firstMatch
        XCTAssertTrue(configList.waitForExistence(timeout: 5),
                     "Test config list should exist")

        // Discover all test-config buttons by their accessibility identifier.
        // Each TestConfigButton has identifier "test-config-test-XXX" (set in TestConfigBrowserView).
        let configButtonsPredicate = NSPredicate(format: "identifier BEGINSWITH %@", "test-config-test-")
        let configButtons = app.buttons.matching(configButtonsPredicate)

        let count = configButtons.count
        XCTAssertGreaterThan(count, 0, "At least one test config should exist")
        print("📋 Found \(count) test config(s) to run")

        // Collect all button identifiers first (the UI may change as we scroll/tap)
        var configIds: [String] = []
        for i in 0..<count {
            let identifier = configButtons.element(boundBy: i).identifier
            configIds.append(identifier)
        }
        configIds.sort()

        var passed = 0
        var failed: [String] = []

        for configId in configIds {
            // Extract the short id (e.g., "test-001") from "test-config-test-001"
            let shortId = String(configId.dropFirst("test-config-".count))

            print("▶️  Running: \(shortId)")

            // Find the button; scroll within the config list only (not the whole screen)
            let button = app.buttons[configId]
            if !button.isHittable {
                button.scrollToElement(within: configList)
            }

            guard button.waitForExistence(timeout: 5) else {
                XCTFail("Button '\(configId)' disappeared")
                failed.append(shortId)
                continue
            }
            button.tap()

            // Wait for the native display view to render
            let renderPredicate = NSPredicate(format: "identifier == %@", "native-display-view")
            let renderView = app.descendants(matching: .any).matching(renderPredicate).firstMatch
            let rendered = renderView.waitForExistence(timeout: 10)

            // Check for error view
            let errorView = app.staticTexts["Error Loading Config"]
            let hasError = errorView.exists

            if !rendered || hasError {
                let reason = hasError ? "Error Loading Config" : "Render view did not appear"
                print("  ❌ FAILED: \(shortId) — \(reason)")
                failed.append(shortId)

                // Still capture a screenshot of the failure state
                let screenshot = app.screenshot()
                let attachment = XCTAttachment(screenshot: screenshot)
                attachment.name = "FAIL-\(shortId)"
                attachment.lifetime = .keepAlways
                add(attachment)
                continue
            }

            // Capture screenshot for visual verification
            let screenshot = app.screenshot()
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = shortId
            attachment.lifetime = .keepAlways
            add(attachment)

            passed += 1
            print("  ✅ PASSED: \(shortId)")
        }

        // Summary
        print("\n" + String(repeating: "═", count: 50))
        print("📊 Results: \(passed)/\(configIds.count) passed")
        if !failed.isEmpty {
            print("❌ Failed configs: \(failed.joined(separator: ", "))")
        }
        print(String(repeating: "═", count: 50))

        // Fail the test if any config failed to render
        XCTAssertTrue(failed.isEmpty,
                     "The following configs failed to render: \(failed.joined(separator: ", "))")
    }
}

// MARK: - Scroll Helper

extension XCUIElement {
    /// Scrolls this element into view with small, incremental drags inside `container`.
    ///
    /// Uses a gentle drag (~one row height) instead of `swipeUp()` which overshoots
    /// in a small 200pt list. Each drag scrolls the container by roughly 70pt so
    /// buttons are revealed one at a time without jumping past any.
    func scrollToElement(within container: XCUIElement) {
        var attempts = 0
        while !isHittable && attempts < 10 {
            let start = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4))
            let end   = container.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3))
            start.press(forDuration: 0.03, thenDragTo: end)
            attempts += 1
        }
    }
}
