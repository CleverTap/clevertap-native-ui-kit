import XCTest

/// One test per Slots tab — each stays on its Slots tab the entire time.
/// Flow:
///   1. Open the Slots tab
///   2. Tap the on-screen "Fetch Slot Data" button (fires the canonical
///      event sequence internally; see `SlotDemoView.swift` and
///      `UIKitSlotDemoViewController.swift`)
///   3. Wait `FetchSlotWaitSeconds` for slots to populate
///   4. Screenshot `after_fetch`
///   5. Scroll fast to the bottom of the feed, screenshot `at_bottom`
///   6. Scroll fast back to the top, screenshot `back_at_top`
///
/// We deliberately do NOT switch to the Events tab between fires — the
/// previous "bounce to Events for every event" flow was the "weird
/// behaviour" the user called out.
final class SlotsScreenshotsTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = launchSampleApp()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - SwiftUI Slots (Tab 1)

    func test_swiftUISlotsScreen_fetchAndScroll() {
        recordVideo(label: "swiftUISlotsScreen", in: self) {
            switchToTab(app, .slots)

            // Two "Fetch Slot Data" buttons live on this screen — the inline
            // one in the header (under test) and a toolbar one. `.firstMatch`
            // resolves to the inline button because SwiftUI declares it
            // before the `.toolbar` modifier.
            let fetchButton = app.buttons["Fetch Slot Data"].firstMatch
            XCTAssertTrue(fetchButton.waitForExistence(timeout: 10),
                          "'Fetch Slot Data' button must exist on SwiftUI Slots tab")

            performFetchAndScrollSequence(
                fetchButton: fetchButton,
                feed: app.scrollViews.firstMatch,
                labelPrefix: "swiftui-slots"
            )
        }
    }

    // MARK: - UIKit Slots (Tab 3)

    func test_uiKitSlotsScreen_fetchAndScroll() {
        recordVideo(label: "uiKitSlotsScreen", in: self) {
            switchToTab(app, .uiKitSlots)

            let fetchButton = app.buttons["Fetch Slot Data"].firstMatch
            XCTAssertTrue(fetchButton.waitForExistence(timeout: 10),
                          "'Fetch Slot Data' button must exist on UIKit Slots tab")

            performFetchAndScrollSequence(
                fetchButton: fetchButton,
                feed: app.tables.firstMatch,
                labelPrefix: "uikit-slots"
            )
        }
    }

    // MARK: - Shared sequence

    /// Tap fetch → wait → screenshot → swipe-up fast → screenshot → swipe-down fast → screenshot.
    /// `feed` is the scrollable container (ScrollView on SwiftUI, UITableView on UIKit).
    /// Both respond identically to `swipeUp` / `swipeDown` from a XCUITest perspective.
    private func performFetchAndScrollSequence(
        fetchButton: XCUIElement,
        feed: XCUIElement,
        labelPrefix: String
    ) {
        fetchButton.tap()
        Thread.sleep(forTimeInterval: FetchSlotWaitSeconds)
        captureScreenshot(app, label: "\(labelPrefix)-after_fetch", in: self)

        XCTAssertTrue(feed.waitForExistence(timeout: 5),
                      "Feed scrollable container must exist on \(labelPrefix) tab")

        // Scroll to bottom — three fast swipes are enough to clear the
        // ~20-row feed on an iPhone 16 Pro at normal density.
        for _ in 0..<3 {
            feed.swipeUp(velocity: .fast)
        }
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(app, label: "\(labelPrefix)-at_bottom", in: self)

        // Scroll back to top.
        for _ in 0..<3 {
            feed.swipeDown(velocity: .fast)
        }
        Thread.sleep(forTimeInterval: 0.5)
        captureScreenshot(app, label: "\(labelPrefix)-back_at_top", in: self)
    }
}
