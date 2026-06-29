import XCTest

/// One test per Events tab — each stays on its tab the whole time and fires
/// every event in `EventsToFire` through the on-screen input UI (text field
/// + Send/Fire button), capturing a screenshot after each.
///
/// The events log is collapsed once per test via the `event-log-toggle` so
/// the screenshot canvas isn't obscured.
///
/// Run a single method:
///   xcodebuild test -scheme NativeDisplaySample \
///     -destination 'platform=iOS Simulator,name=iPhone 16' \
///     -only-testing NativeDisplaySampleUITests/EventsScreenshotsTests/test_swiftUIEventsScreen_fireAllEvents
final class EventsScreenshotsTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchSampleApp()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - SwiftUI Events screen (Tab 0)

    func test_swiftUIEventsScreen_fireAllEvents() {
        recordVideo(label: "swiftUIEventsScreen", in: self) {
            switchToTab(app, .events)

            let field = app.textFields["ct-event-input"]
            XCTAssertTrue(field.waitForExistence(timeout: 10),
                          "ct-event-input must exist on the SwiftUI Events tab")

            hideEventLog(app)

            for eventName in EventsToFire {
                fireEventThroughEventsScreen(app, eventName: eventName)
                captureScreenshot(app, label: "swiftui-events-\(eventName)", in: self)
            }
        }
    }

    // MARK: - UIKit Events screen (Tab 2)

    func test_uiKitEventsScreen_fireAllEvents() {
        recordVideo(label: "uiKitEventsScreen", in: self) {
            switchToTab(app, .uiKitEvents)

            let field = app.textFields["ct-event-input"]
            XCTAssertTrue(field.waitForExistence(timeout: 10),
                          "ct-event-input must exist on the UIKit Events tab")

            hideEventLog(app)

            for eventName in EventsToFire {
                fireEventThroughEventsScreen(app, eventName: eventName)
                captureScreenshot(app, label: "uikit-events-\(eventName)", in: self)
            }
        }
    }
}
