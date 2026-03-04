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

    // MARK: - Phase 10: Percentage BOX Container Test Suite (test-121 to test-155)

    // Group 1: Aspect Ratio Showcases
    func test121_16x9ArImageTextButton() throws {
        let configButton = app.buttons["test-config-test-121"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-121 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-121")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-121-16x9-ar-image-text-button"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test122_1x1ArImageBadgeRounded() throws {
        let configButton = app.buttons["test-config-test-122"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-122 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-122")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-122-1x1-ar-image-badge-rounded"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test123_9x16ArVideoCaption() throws {
        let configButton = app.buttons["test-config-test-123"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-123 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-123")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-123-9x16-ar-video-caption"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test124_4x3ArTextWeights() throws {
        let configButton = app.buttons["test-config-test-124"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-124 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-124")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-124-4x3-ar-text-weights"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test125_2x1ArImageSplitButton() throws {
        let configButton = app.buttons["test-config-test-125"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-125 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-125")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-125-2x1-ar-image-split-button"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 2: TEXT Style Variations
    func test126_TextFontWeights() throws {
        let configButton = app.buttons["test-config-test-126"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-126 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-126")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-126-text-font-weights"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test127_TextFontSizes() throws {
        let configButton = app.buttons["test-config-test-127"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-127 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-127")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-127-text-font-sizes"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test128_TextAlignment() throws {
        let configButton = app.buttons["test-config-test-128"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-128 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-128")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-128-text-alignment"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test129_TextDecorationItalic() throws {
        let configButton = app.buttons["test-config-test-129"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-129 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-129")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-129-text-decoration-italic"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test130_TextMaxlinesOverflow() throws {
        let configButton = app.buttons["test-config-test-130"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-130 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-130")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-130-text-maxlines-overflow"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test131_TextGradient() throws {
        let configButton = app.buttons["test-config-test-131"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-131 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-131")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-131-text-gradient"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 3: IMAGE Variations
    func test132_ImageFitCropContain() throws {
        let configButton = app.buttons["test-config-test-132"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-132 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-132")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-132-image-fit-crop-contain"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test133_ImageGifRounded() throws {
        let configButton = app.buttons["test-config-test-133"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-133 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-133")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-133-image-gif-rounded"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test134_ImageBorderRadius() throws {
        let configButton = app.buttons["test-config-test-134"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-134 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-134")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-134-image-border-radius"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test135_ImagesZOrder() throws {
        let configButton = app.buttons["test-config-test-135"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-135 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-135")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-135-images-z-order"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 4: VIDEO Variations
    func test136_VideoAutoplayMuted() throws {
        let configButton = app.buttons["test-config-test-136"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-136 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-136")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-136-video-autoplay-muted"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test137_VideoWithControls() throws {
        let configButton = app.buttons["test-config-test-137"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-137 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-137")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-137-video-with-controls"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test138_VideoButton9x16() throws {
        let configButton = app.buttons["test-config-test-138"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-138 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-138")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-138-9x16-video-button"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 5: BUTTON Variations
    func test139_ButtonCentered() throws {
        let configButton = app.buttons["test-config-test-139"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-139 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-139")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-139-button-centered"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test140_ButtonPrimarySecondary() throws {
        let configButton = app.buttons["test-config-test-140"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-140 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-140")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-140-button-primary-secondary"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test141_ButtonSizeVariants() throws {
        let configButton = app.buttons["test-config-test-141"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-141 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-141")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-141-button-size-variants"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test142_CtaCard() throws {
        let configButton = app.buttons["test-config-test-142"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-142 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-142")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-142-cta-card"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test143_ButtonRoundedText() throws {
        let configButton = app.buttons["test-config-test-143"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-143 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-143")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-143-button-rounded-text"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 6: Rounded Corners
    func test144_RoundedBoxText() throws {
        let configButton = app.buttons["test-config-test-144"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-144 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-144")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-144-rounded-box-text"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test145_NestedRoundedBoxes() throws {
        let configButton = app.buttons["test-config-test-145"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-145 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-145")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-145-nested-rounded-boxes"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test146_ImageOverlayRounded() throws {
        let configButton = app.buttons["test-config-test-146"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-146 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-146")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-146-image-overlay-rounded"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 7: Complex Compositions
    func test147_HeroBannerComplex() throws {
        let configButton = app.buttons["test-config-test-147"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-147 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-147")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-147-hero-banner-complex"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test148_ProductCardComplex() throws {
        let configButton = app.buttons["test-config-test-148"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-148 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-148")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-148-product-card-complex"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test149_NotificationCard() throws {
        let configButton = app.buttons["test-config-test-149"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-149 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-149")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-149-notification-card"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test150_DashboardWidget() throws {
        let configButton = app.buttons["test-config-test-150"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-150 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-150")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-150-dashboard-widget"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test151_VideoPlayerCard() throws {
        let configButton = app.buttons["test-config-test-151"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-151 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-151")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-151-video-player-card"; attachment.lifetime = .keepAlways; add(attachment)
    }

    // Group 8: Edge Cases
    func test152_TextCorners() throws {
        let configButton = app.buttons["test-config-test-152"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-152 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-152")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-152-text-corners"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test153_ImageClipped() throws {
        let configButton = app.buttons["test-config-test-153"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-153 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-153")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-153-image-clipped"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test154_NestedBoxDeep() throws {
        let configButton = app.buttons["test-config-test-154"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-154 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-154")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-154-nested-box-deep"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test155_AllElementTypes() throws {
        let configButton = app.buttons["test-config-test-155"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-155 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-155")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-155-all-element-types"; attachment.lifetime = .keepAlways; add(attachment)
    }

    func test156_ButtonBackgrounds() throws {
        let configButton = app.buttons["test-config-test-156"]
        XCTAssertTrue(configButton.waitForExistence(timeout: 5), "test-156 button should exist")
        configButton.tap()
        let renderView = app.otherElements["native-display-view"]
        XCTAssertTrue(renderView.waitForExistence(timeout: 10), "Should render test-156")
        XCTAssertFalse(app.staticTexts["Error Loading Config"].exists, "Should not show error")
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "test-156-button-backgrounds"; attachment.lifetime = .keepAlways; add(attachment)
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
