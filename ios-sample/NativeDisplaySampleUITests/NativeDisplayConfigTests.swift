import XCTest

/// Screenshot capture for all 178 Native Display test configurations.
///
/// A single test method navigates through every config sequentially using the
/// in-app "next" arrow — one app launch, one navigation, 178 screenshots.
///
/// Run:
///   xcodebuild test -scheme NativeDisplaySample \
///     -destination 'platform=iOS Simulator,name=iPhone 16' \
///     -only-testing NativeDisplaySampleUITests/NativeDisplayConfigTests/testAllConfigs_Sequential
///
/// Screenshots are saved as XCTAttachments inside the .xcresult bundle:
///   ~/Library/Developer/Xcode/DerivedData/<Project>-<hash>/Logs/Test/<run>.xcresult
///
/// To extract screenshots from the .xcresult:
///   xcrun xcresulttool get --path <run>.xcresult --format json   # explore structure
///   xcparse screenshots <run>.xcresult <output-dir>/             # extract (brew install chargepoint/xcparse/xcparse)
final class NativeDisplayConfigTests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()

        // Ask the app to pre-populate URLCache.shared with all image URLs before tests run.
        // ImagePreloader.swift downloads images in parallel and sets "images-preloaded"
        // when complete. Both AsyncImage and GIFImage benefit via URLCache.shared.
        app.launchEnvironment["PRELOAD_IMAGES"] = "1"
        app.launchEnvironment["XCUITEST"] = "1"
        app.launch()

        // Wait for image preloading to finish before navigating anywhere.
        // 30 s is a ceiling — on a typical connection this resolves in ~10 s.
        let preloaded = app.descendants(matching: .any)
            .matching(identifier: "images-preloaded").firstMatch
        _ = preloaded.waitForExistence(timeout: 30)

        // Tap the menu button (ellipsis) added in ContentView toolbar
        let menuButton = app.buttons["menu-button"]
        XCTAssertTrue(menuButton.waitForExistence(timeout: 5),
                      "Menu button should exist in the navigation bar")
        menuButton.tap()

        // Tap "Test Configs" in the demo menu list
        let testConfigsItem = app.staticTexts["Test Configs"]
        XCTAssertTrue(testConfigsItem.waitForExistence(timeout: 5),
                      "Test Configs menu item should exist")
        testConfigsItem.tap()

        // Confirm TestConfigBrowserView is showing
        let testBrowserTitle = app.staticTexts["Test Browser"]
        XCTAssertTrue(testBrowserTitle.waitForExistence(timeout: 5),
                      "Test Browser view should appear after tapping Test Configs")

        // Wait for onAppear to fire and the first config to settle.
        // "Test Browser" appears immediately on push, but onAppear fires asynchronously.
        // Without this wait, the first nextButton.tap() hits a disabled button and is ignored.
        let firstContent = app.descendants(matching: .any)
            .matching(identifier: "content-settled").firstMatch
        _ = firstContent.waitForExistence(timeout: 5)
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Single Sequential Run

    /// Captures screenshots for all 178 test configs in one pass.
    ///
    /// Uses the "nav-next" arrow button to advance through configs without relaunching
    /// the app. `native-display-view` is waited on before each screenshot so the
    /// 50 ms async load delay is correctly handled.
    func testAllConfigs_Sequential() throws {
        // Filenames in the same alphabetical order that TestConfigBrowserView produces.
        // "test-VERIFY-..." sorts last because 'V' (86) > any digit (48–57) in ASCII.
        let configs: [String] = [
            //"test-001-vertical-simple",
            "test-002-horizontal-simple",
            "test-003-box-simple",
            "test-004-stack-simple",
            "test-005-gallery-simple",
            "test-006-vertical-empty",
            "test-007-vertical-single-child",
            "test-008-vertical-3-children",
            "test-009-vertical-5-children",
            "test-010-vertical-10-children",
            "test-011-horizontal-empty",
            "test-012-horizontal-single-child",
            "test-013-horizontal-3-children",
            "test-014-horizontal-5-children",
            "test-015-horizontal-10-children",
            "test-016-box-empty",
            "test-017-box-single-child",
            "test-018-box-3-children",
            "test-019-box-5-children",
            "test-020-stack-empty",
            "test-021-stack-single-child",
            "test-022-stack-3-children",
            "test-023-stack-5-children",
            "test-024-gallery-empty",
            "test-025-gallery-single-child",
            "test-026-gallery-3-children-snapping",
            "test-027-gallery-5-children-snapping",
            "test-028-gallery-10-children-snapping",
            "test-029-gallery-3-children-free-flow",
            "test-030-gallery-3-children-free-flow-grid",
            "test-031-vertical-spaced",
            "test-032-vertical-space-between",
            "test-033-vertical-space-evenly",
            "test-034-vertical-space-around",
            "test-035-horizontal-start",
            "test-036-horizontal-center",
            "test-037-horizontal-end",
            "test-038-vertical-spacing-0",
            "test-039-vertical-spacing-8",
            "test-040-vertical-spacing-16",
            "test-041-vertical-spacing-32",
            "test-042-vertical-padding-uniform",
            "test-043-vertical-padding-individual",
            "test-044-horizontal-padding-asymmetric",
            "test-045-box-padding-large",
            "test-046-vertical-wrap-content",
            "test-047-horizontal-percent-width",
            "test-048-vertical-mixed-units",
            "test-049-nested-mixed-arrangements",
            "test-050-gallery-spacing-variations",
            "test-051-all-text-elements",
            "test-052-all-image-elements",
            "test-053-all-button-elements",
            "test-054-all-video-elements",
            "test-055-all-spacer-elements",
            "test-056-all-divider-elements",
            "test-057-product-card",
            "test-058-login-form",
            "test-059-profile-header",
            "test-060-media-player",
            "test-061-article-layout",
            "test-062-action-sheet",
            "test-063-stats-card",
            "test-064-gallery-item",
            "test-065-notification",
            "test-066-pricing-card",
            "test-067-hero-banner",
            "test-068-social-post",
            "test-069-settings-row",
            "test-070-feature-showcase",
            "test-071-text-colors",
            "test-072-font-sizes",
            "test-073-font-weights",
            "test-074-text-alignment",
            "test-075-text-decoration",
            "test-076-line-height",
            "test-077-font-families",
            "test-078-border-radius",
            "test-079-border-width-color",
            "test-080-shadows-light",
            "test-081-shadows-medium",
            "test-082-shadows-heavy",
            "test-083-opacity-variations",
            "test-084-combined-visual-styles",
            "test-085-text-style-inheritance",
            "test-086-style-class-usage",
            "test-087-inline-vs-inherited",
            "test-088-theme-default-styles",
            "test-089-styled-product-card",
            "test-090-styled-profile-card",
            "test-091-offset-percent-box-basic",
            "test-092-offset-percent-stack-layers",
            "test-093-offset-percent-negative",
            "test-094-offset-percent-overflow",
            "test-095-offset-percent-zero",
            "test-096-offset-percent-responsive",
            "test-097-offset-mixed-units",
            "test-098-offset-percent-nested",
            "test-099-offset-percent-with-padding",
            "test-100-offset-percent-gallery-peek",
            "test-101-aspect-ratio-square-fixed-width",
            "test-102-aspect-ratio-16-9-fixed-width",
            "test-103-aspect-ratio-4-3-fixed-width",
            "test-104-aspect-ratio-fixed-height",
            "test-105-aspect-ratio-percent-width",
            "test-106-aspect-ratio-wrap-content",
            "test-107-aspect-ratio-match-parent",
            "test-108-aspect-ratio-extreme-wide",
            "test-109-aspect-ratio-extreme-tall",
            "test-110-aspect-ratio-mixed-container",
            "test-111-combined-aspect-offset-box",
            "test-112-combined-nested-complex",
            "test-113-combined-gallery-aspect-peek",
            "test-114-combined-product-grid",
            "test-115-combined-showcase-all",
            "test-116-match-parent-comprehensive",
            "test-117-wrap-content-comprehensive",
            "test-118-mixed-special-dimensions",
            "test-119-match-parent-stack-box",
            "test-120-wrap-content-constraints",
            "test-121-16x9-ar-image-text-button",
            "test-122-1x1-ar-image-badge-rounded",
            "test-123-9x16-ar-video-caption",
            "test-124-4x3-ar-text-weights",
            "test-125-2x1-ar-image-split-button",
            "test-126-text-font-weights",
            "test-127-text-font-sizes",
            "test-128-text-alignment",
            "test-129-text-decoration-italic",
            "test-130-text-maxlines-overflow",
            "test-131-text-gradient",
            "test-132-image-fit-crop-contain",
            "test-133-image-gif-rounded",
            "test-134-image-border-radius",
            "test-135-images-z-order",
            "test-136-video-autoplay-muted",
            "test-137-video-with-controls",
            "test-138-9x16-video-button",
            "test-139-button-centered",
            "test-140-button-primary-secondary",
            "test-141-button-size-variants",
            "test-142-cta-card",
            "test-143-button-rounded-text",
            "test-144-rounded-box-text",
            "test-145-nested-rounded-boxes",
            "test-146-image-overlay-rounded",
            "test-147-hero-banner-complex",
            "test-148-product-card-complex",
            "test-149-notification-card",
            "test-150-dashboard-widget",
            "test-151-video-player-card",
            "test-152-text-corners",
            "test-153-image-clipped",
            "test-154-nested-box-deep",
            "test-155-all-element-types",
            "test-156-button-backgrounds",
            "test-157-gallery-box-freeflow-indicators-navbtns",
            "test-158-gallery-box-freeflow-indicators-only",
            "test-159-gallery-box-freeflow-navbtns-only",
            "test-160-gallery-box-freeflow-minimal",
            "test-161-gallery-box-freeflow-tall-images",
            "test-162-gallery-box-freeflow-video-items",
            "test-163-gallery-box-freeflow-button-items",
            "test-164-gallery-box-freeflow-5items",
            "test-165-gallery-box-grid2col-indicators-navbtns",
            "test-166-gallery-box-grid2col-indicators-only",
            "test-167-gallery-box-grid2col-navbtns-only",
            "test-168-gallery-box-grid2col-minimal",
            "test-169-gallery-box-grid3col-indicators",
            "test-170-gallery-box-grid3col-navbtns",
            "test-171-gallery-box-grid2col-video",
            "test-172-gallery-box-grid2col-vertical",
            "test-172-video-fullscreen-openurl",
            "test-173-gallery-box-snapping-indicators-navbtns",
            "test-174-gallery-box-snapping-indicators-only",
            "test-175-gallery-box-snapping-navbtns-only",
            "test-176-gallery-box-snapping-minimal",
            "test-VERIFY-percentage-offset-fix",
        ]

        // content-settled appears for BOTH success (native-display-view) and failure (error VStack).
        // Waiting on it resolves in ~100 ms either way — no more burning full timeout on failures.
        let contentSettled = app.descendants(matching: .any)
            .matching(identifier: "content-settled").firstMatch
        let renderView = app.descendants(matching: .any)
            .matching(identifier: "native-display-view").firstMatch
        let nextButton = app.buttons["nav-next"]
        let failedLoadPredicate = NSPredicate(format: "label BEGINSWITH 'Failed to load'")

        var failedConfigs: [(name: String, reason: String)] = []

        for (index, filename) in configs.enumerated() {
            // Wait for load to settle (success or failure both appear in ~100 ms).
            // Only falls back to the full 2 s if the view is in an unexpected state.
            _ = contentSettled.waitForExistence(timeout: 2)

            if !renderView.exists {
                let reason = app.staticTexts.matching(failedLoadPredicate).firstMatch.exists
                    ? "Failed to load"
                    : "Timed out — no render, no error message"
                failedConfigs.append((name: filename, reason: reason))
            }

            // Capture element-level screenshot of NativeDisplayView (no chrome, no padding)
            let renderView = app.descendants(matching: .any)
                .matching(identifier: "native-display-view").firstMatch
            let screenshot = XCTAttachment(screenshot: renderView.exists ? renderView.screenshot() : app.screenshot())
            screenshot.name = filename
            screenshot.lifetime = .keepAlways
            add(screenshot)

            guard index < configs.count - 1 else { break }
            nextButton.tap()
        }

        // ── Failure report ────────────────────────────────────────────────
        if !failedConfigs.isEmpty {
            let lines = failedConfigs.map { "  \($0.name)  →  \($0.reason)" }
            let report = "Failed configs (\(failedConfigs.count) / \(configs.count)):\n"
                + lines.joined(separator: "\n")

            // Attach as a text file so it appears in Report Navigator alongside screenshots
            let reportAttachment = XCTAttachment(string: report)
            reportAttachment.name = "FAILED_CONFIGS"
            reportAttachment.lifetime = .keepAlways
            add(reportAttachment)

            print("⚠️  \(report)")
        } else {
            print("✅  All \(configs.count) configs rendered successfully.")
        }
    }
}
