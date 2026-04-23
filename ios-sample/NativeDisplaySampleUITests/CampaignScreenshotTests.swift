import XCTest

// Run:
//   xcodebuild test -scheme NativeDisplaySample \
//     -destination 'platform=iOS Simulator,name=iPhone 16' \
//     -only-testing NativeDisplaySampleUITests/CampaignScreenshotTests/testFireEventsAndCaptureScreenshots
//
// Screenshots are saved as XCTAttachments in the .xcresult bundle.
// To also access saved PNGs from the simulator:
//   1. In Xcode → Window → Devices and Simulators → select your simulator
//   2. Or use: xcrun simctl get_app_container booted com.clevertap.ios.nativedisplay.sample data
//      Then navigate to Documents/campaign-screenshots/

final class CampaignScreenshotTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launch()

        // Wait for the Events tab text field to be ready.
        // Tab 0 ("Events") is selected by default — no navigation needed.
        let field = app.textFields["ct-event-input"]
        XCTAssertTrue(field.waitForExistence(timeout: 10),
                      "ct-event-input text field should exist on the Events tab")
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Campaign Screenshot Capture

    func testFireEventsAndCaptureScreenshots() throws {
        let events = [
            "header1", "header2", "header3", "header4", "header5",
            "footer1", "footer2", "footer3", "footer4", "footer5",
        ]

        // Save PNGs directly to ~/Desktop/campaign-screenshots/ on the host Mac.
        // SIMULATOR_HOST_HOME is set by the simulator runtime and points to the
        // current user's home directory on the host machine.
        let hostHome = ProcessInfo.processInfo.environment["SIMULATOR_HOST_HOME"]
            ?? NSTemporaryDirectory()
        let screenshotsDir = URL(fileURLWithPath: hostHome)
            .appendingPathComponent("Desktop/campaign-screenshots", isDirectory: true)
        try? FileManager.default.createDirectory(at: screenshotsDir,
                                                 withIntermediateDirectories: true)

        let sendButton = app.buttons["ct-send-event-btn"]
        XCTAssertTrue(sendButton.waitForExistence(timeout: 5),
                      "ct-send-event-btn must exist")

        for eventName in events {
            // -- 1. Clear the text field and type the event name --
            let field = app.textFields["ct-event-input"]
            XCTAssertTrue(field.waitForExistence(timeout: 5),
                          "ct-event-input must exist before typing '\(eventName)'")

            field.tap()
            field.press(forDuration: 1.0) // long-press to trigger edit menu
            if app.menuItems["Select All"].exists {
                app.menuItems["Select All"].tap()
            }
            app.typeText(eventName)

            // -- 2. Send the event --
            sendButton.tap()

            // -- 3. Dismiss the keyboard before capturing --
            if app.keyboards.firstMatch.waitForExistence(timeout: 1) {
                let doneButton = app.keyboards.buttons["Done"]
                if doneButton.exists {
                    doneButton.tap()
                } else {
                    app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
                }
            }

            // -- 4. Wait 2 s for the new campaign to arrive from the server --
            Thread.sleep(forTimeInterval: 2)

            // -- 5. Capture a full-app screenshot --
            let screenshot = app.screenshot()

            // -- 6. Attach to xcresult so it appears in Xcode / Report Navigator --
            let attachment = XCTAttachment(screenshot: screenshot)
            attachment.name = "campaign-\(eventName)"
            attachment.lifetime = .keepAlways
            add(attachment)

            // -- 7. Also persist the PNG to the simulator's Documents folder --
            let fileURL = screenshotsDir.appendingPathComponent("\(eventName).png")
            let pngData = screenshot.pngRepresentation
            do {
                try pngData.write(to: fileURL)
                print("Saved: \(fileURL.path)")
            } catch {
                print("Warning: could not save PNG for '\(eventName)': \(error)")
            }
        }
    }
}
