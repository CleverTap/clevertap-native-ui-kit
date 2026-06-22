import XCTest
import Foundation

// MARK: - Shared constants

/// Canonical event list fired by every automation test, in exact order and casing.
/// Mirrors the dashboard campaign trigger set. Do not reorder — tests rely on it
/// matching screenshot filenames already documented in the QA workflow.
let EventsToFire: [String] = [
    "header1", "header2", "header3", "header4", "header5",
    "footer1", "footer2", "footer3", "footer4", "footer5",
    "nps", "topi", "kk", "mm", "ii", "iip", "ss", "cptest",
    "hi", "viewed", "html2", "home",
]

/// Per-event wait, in seconds. The Native Display server is asynchronous —
/// we need to give it time to push the unit back to the SDK before we
/// screenshot. Bump if tests flake.
let PerEventWaitSeconds: TimeInterval = 1.5

/// Wait after tapping "Fetch Slot Data" before screenshotting.
let FetchSlotWaitSeconds: TimeInterval = 3.0

// MARK: - Tab navigation

/// Tab labels in the order they appear in `RootTabBarController`.
/// Preferring labels over indices so the tests don't break if the bar shrinks
/// to a "More" overflow on smaller devices (UITabBarController will still
/// expose the items as buttons in the tab bar accessibility tree).
enum AutomationTab: String {
    case events       = "Events"
    case slots        = "Slots"
    case uiKitEvents  = "UIKit"
    case uiKitSlots   = "UIKit Slots"
}

/// Switch to a tab by its visible label. No-op if the tab is already selected.
/// Falls back to a `.firstMatch` against `tabBars.buttons[label]` — works on
/// both phone and pad layouts.
func switchToTab(_ app: XCUIApplication, _ tab: AutomationTab) {
    let button = app.tabBars.buttons[tab.rawValue]
    if button.waitForExistence(timeout: 5) {
        button.tap()
    } else {
        XCTFail("Tab button '\(tab.rawValue)' not found in tab bar")
    }
}

// MARK: - Event log

/// Tap the eye-toggle to collapse the events log. Idempotent — if the
/// button isn't visible (e.g. wrong tab, or already hidden and off-screen)
/// the call is a silent no-op. The log defaults to *visible* on every fresh
/// launch, so callers should invoke this once per Events screen visit before
/// screenshotting.
func hideEventLog(_ app: XCUIApplication) {
    let toggle = app.buttons["event-log-toggle"]
    if toggle.waitForExistence(timeout: 2) {
        toggle.tap()
        // Give SwiftUI / UIKit a moment to animate the collapse before the
        // caller grabs a screenshot.
        Thread.sleep(forTimeInterval: 0.3)
    }
}

// MARK: - Event firing

/// Type `eventName` into `ct-event-input` and tap `ct-send-event-btn`.
/// Caller is responsible for being on the correct tab (Events or UIKit).
///
/// Both production screens now (a) clear the input after a successful send
/// and (b) resign first responder on send, so the loop doesn't need to
/// manually clear text or dismiss the keyboard. Defensive keyboard-dismiss
/// fallback below catches any future regression without flaking the suite.
func fireEventThroughEventsScreen(_ app: XCUIApplication, eventName: String) {
    let field = app.textFields["ct-event-input"]
    XCTAssertTrue(field.waitForExistence(timeout: 5),
                  "ct-event-input must exist on the active screen")

    field.tap()
    app.typeText(eventName)

    let sendButton = app.buttons["ct-send-event-btn"]
    XCTAssertTrue(sendButton.waitForExistence(timeout: 2),
                  "ct-send-event-btn must exist on the active screen")
    sendButton.tap()

    // Defensive fallback. If the production code stops dismissing the
    // keyboard on send for any reason, this prevents the next screenshot
    // from being obscured. Cheap when the keyboard is already gone.
    if app.keyboards.firstMatch.waitForExistence(timeout: 0.5) {
        let doneButton = app.keyboards.buttons["Done"]
        if doneButton.exists {
            doneButton.tap()
        } else {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.3)).tap()
        }
    }

    Thread.sleep(forTimeInterval: PerEventWaitSeconds)
}

// MARK: - Screenshotting

/// Capture the current app screen and attach it to the active test run.
/// Filename is `<label>.png`; XCResult adds the test method name as parent
/// scope, so files extracted with `xcparse` end up under the right test.
func captureScreenshot(_ app: XCUIApplication, label: String, in testCase: XCTestCase) {
    let screenshot = app.screenshot()
    let attachment = XCTAttachment(screenshot: screenshot)
    attachment.name = "\(label).png"
    attachment.lifetime = .keepAlways
    testCase.add(attachment)
}

// MARK: - Per-test video recording

/// Per-test wrapper that exists so call sites can opt into video recording
/// later without changing test bodies. Currently a thin pass-through: the
/// XCUITest runner executes inside the iOS sandbox where `Foundation.Process`
/// is unavailable, so we can't fork `xcrun simctl io booted recordVideo`
/// from within the test target.
///
/// Two practical ways to capture MP4s alongside these tests:
///   1. Wrap the `xcodebuild test ...` invocation in a shell script that
///      starts `xcrun simctl io booted recordVideo --codec=h264 <out>.mp4`
///      in the background, runs the tests, and stops the recorder.
///   2. Use Xcode's built-in scheme option **Test → Options → "Record system
///      screen recordings"** which automatically attaches an MP4 per failed
///      test (and optionally for all tests) to the xcresult bundle.
///
/// Keeping this helper here as the single seam — if a future iOS release
/// exposes process spawning, or we move to a UITest-runner-host approach,
/// the implementation drops in here without touching individual tests.
func recordVideo(label: String, in testCase: XCTestCase, body: () -> Void) {
    body()
}

// MARK: - App launch

/// Launch the sample app with environment flags consistent across all
/// automation tests. Returns the launched `XCUIApplication`.
func launchSampleApp() -> XCUIApplication {
    let app = XCUIApplication()
    app.launchEnvironment["XCUITEST"] = "1"
    app.launch()
    return app
}
