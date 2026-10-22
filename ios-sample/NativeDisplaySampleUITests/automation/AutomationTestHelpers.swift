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

/// Upper bound, in seconds, on how long the handshake waits for a new
/// display-units batch after firing an event. The Native Display server is
/// asynchronous; `fireEventThroughEventsScreen` polls the `ct-units-count`
/// probe until it increments (deterministic) and only falls back to this bound
/// if the batch never arrives. Bump if the backend gets slower.
let PerEventWaitSeconds: TimeInterval = 10.0

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

/// Type `eventName` into `ct-event-input` and tap `ct-send-event-btn`, then
/// wait — deterministically — until the display-units batch for *this* event
/// has been delivered to the canvas before returning.
///
/// Caller is responsible for being on the correct tab (Events or UIKit).
///
/// Handshake contract (shared across the Flutter / Android / iOS suites):
///   1. Read `before` = the `ct-units-count` probe value.
///   2. Fire the event. The production Send action clears the canvas and
///      records the event; a new batch increments the probe when it lands.
///   3. Poll the probe until it exceeds `before` (new batch delivered), up to
///      `PerEventWaitSeconds`. On timeout, proceed anyway — the canvas is in
///      its empty "Waiting" state (cleared on send), which is a truthful
///      screenshot rather than a stale previous campaign.
///   4. Brief settle so images paint, then return; the caller screenshots.
///
/// On screens without the probe (e.g. the UIKit screen), `before`/`after` both
/// read 0, so the poll simply times out and falls back to the bound — matching
/// the prior fixed-wait behaviour there.
func fireEventThroughEventsScreen(_ app: XCUIApplication, eventName: String) {
    let field = app.textFields["ct-event-input"]
    XCTAssertTrue(field.waitForExistence(timeout: 5),
                  "ct-event-input must exist on the active screen")

    let before = currentUnitsCount(app)

    // Focus the field and type into the element itself (not app.typeText).
    // The previous event's send clears the input and dismisses the keyboard, so
    // on the next iteration a bare `field.tap(); app.typeText(...)` can race —
    // the tap returns before first-responder/keyboard is ready and typeText
    // fails with "Neither element nor any descendant has keyboard focus".
    // Tapping, waiting for the keyboard, then typing into `field` is robust.
    field.tap()
    _ = app.keyboards.firstMatch.waitForExistence(timeout: 3)
    field.typeText(eventName)

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

    // Poll the batch counter until a new batch arrives, bounded by
    // PerEventWaitSeconds. Short interval keeps latency low without busy-waiting.
    let deadline = Date().addingTimeInterval(PerEventWaitSeconds)
    while Date() < deadline {
        if currentUnitsCount(app) > before { break }
        Thread.sleep(forTimeInterval: 0.2)
    }

    // Brief settle for image paint before the caller grabs the screenshot.
    Thread.sleep(forTimeInterval: 1.0)
}

/// Read the `ct-units-count` probe as an Int. Returns 0 when the probe is
/// absent (screen has no counter) or its label isn't numeric, which makes the
/// handshake degrade gracefully to a plain timeout on those screens.
private func currentUnitsCount(_ app: XCUIApplication) -> Int {
    let probe = app.staticTexts["ct-units-count"]
    guard probe.exists else { return 0 }
    return Int(probe.label) ?? 0
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
