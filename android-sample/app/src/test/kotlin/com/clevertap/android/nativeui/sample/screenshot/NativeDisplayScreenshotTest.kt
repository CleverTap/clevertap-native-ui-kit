package com.clevertap.android.nativeui.sample.screenshot

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.clevertap.android.nativedisplay.renderer.LocalImageLoader
import com.clevertap.android.nativedisplay.renderer.LocalVideoPlayerFactory
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.nativeui.sample.JsonLoader
import com.github.takahirom.roborazzi.captureRoboGif
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.AfterClass
import org.junit.Before
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.util.Collections
import org.robolectric.annotation.Config
import org.robolectric.annotation.GraphicsMode
import org.robolectric.annotation.LooperMode

/**
 * Screenshot tests for Native Display SDK using Roborazzi.
 *
 * These tests capture screenshots for all test configurations to verify
 * visual correctness and enable visual regression testing.
 *
 * Test execution:
 * ```
 * ./gradlew :app:testDebugUnitTest --tests NativeDisplayScreenshotTest
 * ```
 *
 * Screenshots are saved to: `build/outputs/roborazzi/configs/`
 */
@RunWith(AndroidJUnit4::class)
@Config(
    sdk = [33],
    qualifiers = "w400dp-h700dp"
)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@LooperMode(LooperMode.Mode.PAUSED)
class NativeDisplayScreenshotTest {

    companion object {
        private var imageUrls: Set<String> = emptySet()
        private val failedConfigs: MutableList<Pair<String, String>> =
            Collections.synchronizedList(mutableListOf())

        @JvmStatic
        @AfterClass
        fun writeFailureReport() {
            if (failedConfigs.isEmpty()) {
                println("✅ All ${177} configs rendered successfully.")
                return
            }
            val lines = failedConfigs.map { (name, reason) -> "  $name  →  $reason" }
            val report = buildString {
                appendLine("Failed configs (${failedConfigs.size} / 177):")
                appendLine(lines.joinToString("\n"))
            }
            println("⚠️\n$report")

            // Write alongside screenshots so it's easy to compare with iOS results
            val reportFile = java.io.File("configs/FAILED_CONFIGS.txt")
            reportFile.parentFile?.mkdirs()
            reportFile.writeText(report)
            println("📄 Failure report saved to: ${reportFile.absolutePath}")
        }
    }

    @get:Rule
    val composeTestRule = createAndroidComposeRule<ComponentActivity>()

    @Before
    fun prewarmImages() {
        val context = ApplicationProvider.getApplicationContext<Context>()
        if (!ImagePrewarmCache.isInitialized) {
            imageUrls = collectImageUrlsFromAssets(context)
            ImagePrewarmCache.initialize(imageUrls)
        }
    }

    private fun captureConfig(filename: String) {
        val config = JsonLoader.loadFromAssets(
            ApplicationProvider.getApplicationContext(),
            "test-configs/$filename"
        )
        if (config == null) {
            failedConfigs.add(filename to "Failed to load — JsonLoader returned null")
            return
        }
        try {
            composeTestRule.setContent {
                CompositionLocalProvider(
                    LocalImageLoader provides { ctx -> buildPrewarmedImageLoader(ctx) },
                    LocalVideoPlayerFactory provides stubVideoPlayerFactory,
                ) {
                    NativeDisplayView(config = config, modifier = Modifier.fillMaxSize())
                }
            }
            composeTestRule.waitForIdle()
            composeTestRule.waitForIdle()  // second pump for Coil result propagation
            composeTestRule.onRoot().captureRoboImage(filePath = "configs/$filename.png")
        } catch (e: Exception) {
            failedConfigs.add(filename to "Render error — ${e.javaClass.simpleName}: ${e.message?.take(120)}")
        }
    }

    private fun captureConfigAsGif(filename: String) {
        val config = JsonLoader.loadFromAssets(
            ApplicationProvider.getApplicationContext(),
            "test-configs/$filename"
        )
        if (config == null) {
            failedConfigs.add(filename to "Failed to load — JsonLoader returned null")
            return
        }
        try {
            composeTestRule.setContent {
                CompositionLocalProvider(
                    LocalImageLoader provides { ctx -> buildPrewarmedImageLoader(ctx) },
                ) {
                    NativeDisplayView(config = config, modifier = Modifier.fillMaxSize())
                }
            }
            composeTestRule.onRoot().captureRoboGif(
                composeRule = composeTestRule,
                filePath = "configs/$filename.gif",
            ) {
                composeTestRule.mainClock.advanceTimeBy(500)
                composeTestRule.mainClock.advanceTimeBy(500)
                composeTestRule.mainClock.advanceTimeBy(1000)
            }
        } catch (e: Exception) {
            failedConfigs.add(filename to "Render error — ${e.javaClass.simpleName}: ${e.message?.take(120)}")
        }
    }

    // ============================================================================
    // Phase 1: Basic Containers (5 tests)
    // ============================================================================

    @Test fun test001VerticalSimple() = captureConfig("test-001-vertical-simple.json")
    @Test fun test002HorizontalSimple() = captureConfig("test-002-horizontal-simple.json")
    @Test fun test003BoxSimple() = captureConfig("test-003-box-simple.json")
    @Test fun test004StackSimple() = captureConfig("test-004-stack-simple.json")
    @Test fun test005GallerySimple() = captureConfig("test-005-gallery-simple.json")

    // ============================================================================
    // Phase 2: Child Count Variations (25 tests)
    // ============================================================================

    @Test fun test006VerticalEmpty() = captureConfig("test-006-vertical-empty.json")
    @Test fun test007VerticalSingleChild() = captureConfig("test-007-vertical-single-child.json")
    @Test fun test008Vertical3Children() = captureConfig("test-008-vertical-3-children.json")
    @Test fun test009Vertical5Children() = captureConfig("test-009-vertical-5-children.json")
    @Test fun test010Vertical10Children() = captureConfig("test-010-vertical-10-children.json")

    @Test fun test011HorizontalEmpty() = captureConfig("test-011-horizontal-empty.json")
    @Test fun test012HorizontalSingleChild() = captureConfig("test-012-horizontal-single-child.json")
    @Test fun test013Horizontal3Children() = captureConfig("test-013-horizontal-3-children.json")
    @Test fun test014Horizontal5Children() = captureConfig("test-014-horizontal-5-children.json")
    @Test fun test015Horizontal10Children() = captureConfig("test-015-horizontal-10-children.json")

    @Test fun test016BoxEmpty() = captureConfig("test-016-box-empty.json")
    @Test fun test017BoxSingleChild() = captureConfig("test-017-box-single-child.json")
    @Test fun test018Box3Children() = captureConfig("test-018-box-3-children.json")
    @Test fun test019Box5Children() = captureConfig("test-019-box-5-children.json")

    @Test fun test020StackEmpty() = captureConfig("test-020-stack-empty.json")
    @Test fun test021StackSingleChild() = captureConfig("test-021-stack-single-child.json")
    @Test fun test022Stack3Children() = captureConfig("test-022-stack-3-children.json")
    @Test fun test023Stack5Children() = captureConfig("test-023-stack-5-children.json")

    @Test fun test024GalleryEmpty() = captureConfig("test-024-gallery-empty.json")
    @Test fun test025GallerySingleChild() = captureConfig("test-025-gallery-single-child.json")
    @Test fun test026Gallery3ChildrenSnapping() = captureConfig("test-026-gallery-3-children-snapping.json")
    @Test fun test027Gallery5ChildrenSnapping() = captureConfig("test-027-gallery-5-children-snapping.json")
    @Test fun test028Gallery10ChildrenSnapping() = captureConfig("test-028-gallery-10-children-snapping.json")
    @Test fun test029Gallery3ChildrenFreeFlow() = captureConfig("test-029-gallery-3-children-free-flow.json")
    @Test fun test030Gallery3ChildrenFreeFlowGrid() = captureConfig("test-030-gallery-3-children-free-flow-grid.json")

    // ============================================================================
    // Phase 3: Layout & Spacing (20 tests)
    // ============================================================================

    @Test fun test031VerticalSpaced() = captureConfig("test-031-vertical-spaced.json")
    @Test fun test032VerticalSpaceBetween() = captureConfig("test-032-vertical-space-between.json")
    @Test fun test033VerticalSpaceEvenly() = captureConfig("test-033-vertical-space-evenly.json")
    @Test fun test034VerticalSpaceAround() = captureConfig("test-034-vertical-space-around.json")

    @Test fun test035HorizontalStart() = captureConfig("test-035-horizontal-start.json")
    @Test fun test036HorizontalCenter() = captureConfig("test-036-horizontal-center.json")
    @Test fun test037HorizontalEnd() = captureConfig("test-037-horizontal-end.json")

    @Test fun test038VerticalSpacing0() = captureConfig("test-038-vertical-spacing-0.json")
    @Test fun test039VerticalSpacing8() = captureConfig("test-039-vertical-spacing-8.json")
    @Test fun test040VerticalSpacing16() = captureConfig("test-040-vertical-spacing-16.json")
    @Test fun test041VerticalSpacing32() = captureConfig("test-041-vertical-spacing-32.json")

    @Test fun test042VerticalPaddingUniform() = captureConfig("test-042-vertical-padding-uniform.json")
    @Test fun test043VerticalPaddingIndividual() = captureConfig("test-043-vertical-padding-individual.json")
    @Test fun test044HorizontalPaddingAsymmetric() = captureConfig("test-044-horizontal-padding-asymmetric.json")
    @Test fun test045BoxPaddingLarge() = captureConfig("test-045-box-padding-large.json")

    @Test fun test046VerticalWrapContent() = captureConfig("test-046-vertical-wrap-content.json")
    @Test fun test047HorizontalPercentWidth() = captureConfig("test-047-horizontal-percent-width.json")
    @Test fun test048VerticalMixedUnits() = captureConfig("test-048-vertical-mixed-units.json")
    @Test fun test049NestedMixedArrangements() = captureConfig("test-049-nested-mixed-arrangements.json")
    @Test fun test050GallerySpacingVariations() = captureConfig("test-050-gallery-spacing-variations.json")

    // ============================================================================
    // Phase 4: Element Combinations (20 tests)
    // ============================================================================

    @Test fun test051AllTextElements() = captureConfig("test-051-all-text-elements.json")
    @Test fun test052AllImageElements() = captureConfig("test-052-all-image-elements.json")
    @Test fun test053AllButtonElements() = captureConfig("test-053-all-button-elements.json")
    @Test fun test054AllVideoElements() = captureConfigAsGif("test-054-all-video-elements.json")
    @Test fun test055AllSpacerElements() = captureConfig("test-055-all-spacer-elements.json")
    @Test fun test056AllDividerElements() = captureConfig("test-056-all-divider-elements.json")

    @Test fun test057ProductCard() = captureConfig("test-057-product-card.json")
    @Test fun test058LoginForm() = captureConfig("test-058-login-form.json")
    @Test fun test059ProfileHeader() = captureConfig("test-059-profile-header.json")
    @Test fun test060MediaPlayer() = captureConfig("test-060-media-player.json")
    @Test fun test061ArticleLayout() = captureConfig("test-061-article-layout.json")
    @Test fun test062ActionSheet() = captureConfig("test-062-action-sheet.json")
    @Test fun test063StatsCard() = captureConfig("test-063-stats-card.json")
    @Test fun test064GalleryItem() = captureConfig("test-064-gallery-item.json")
    @Test fun test065Notification() = captureConfig("test-065-notification.json")
    @Test fun test066PricingCard() = captureConfig("test-066-pricing-card.json")
    @Test fun test067HeroBanner() = captureConfig("test-067-hero-banner.json")
    @Test fun test068SocialPost() = captureConfig("test-068-social-post.json")
    @Test fun test069SettingsRow() = captureConfig("test-069-settings-row.json")
    @Test fun test070FeatureShowcase() = captureConfig("test-070-feature-showcase.json")

    // ============================================================================
    // Phase 5: Style Variations (20 tests)
    // ============================================================================

    @Test fun test071TextColors() = captureConfig("test-071-text-colors.json")
    @Test fun test072FontSizes() = captureConfig("test-072-font-sizes.json")
    @Test fun test073FontWeights() = captureConfig("test-073-font-weights.json")
    @Test fun test074TextAlignment() = captureConfig("test-074-text-alignment.json")
    @Test fun test075TextDecoration() = captureConfig("test-075-text-decoration.json")
    @Test fun test076LineHeight() = captureConfig("test-076-line-height.json")
    @Test fun test077FontFamilies() = captureConfig("test-077-font-families.json")

    @Test fun test078BorderRadius() = captureConfig("test-078-border-radius.json")
    @Test fun test079BorderWidthColor() = captureConfig("test-079-border-width-color.json")

    @Test fun test080ShadowsLight() = captureConfig("test-080-shadows-light.json")
    @Test fun test081ShadowsMedium() = captureConfig("test-081-shadows-medium.json")
    @Test fun test082ShadowsHeavy() = captureConfig("test-082-shadows-heavy.json")

    @Test fun test083OpacityVariations() = captureConfig("test-083-opacity-variations.json")
    @Test fun test084CombinedVisualStyles() = captureConfig("test-084-combined-visual-styles.json")

    @Test fun test085TextStyleInheritance() = captureConfig("test-085-text-style-inheritance.json")
    @Test fun test086StyleClassUsage() = captureConfig("test-086-style-class-usage.json")
    @Test fun test087InlineVsInherited() = captureConfig("test-087-inline-vs-inherited.json")
    @Test fun test088ThemeDefaultStyles() = captureConfig("test-088-theme-default-styles.json")

    @Test fun test089StyledProductCard() = captureConfig("test-089-styled-product-card.json")
    @Test fun test090StyledProfileCard() = captureConfig("test-090-styled-profile-card.json")

    // ============================================================================
    // Phase 6: Percentage Offset Tests (10 tests)
    // ============================================================================

    @Test fun test091OffsetPercentBoxBasic() = captureConfig("test-091-offset-percent-box-basic.json")
    @Test fun test092OffsetPercentStackLayers() = captureConfig("test-092-offset-percent-stack-layers.json")
    @Test fun test093OffsetPercentNegative() = captureConfig("test-093-offset-percent-negative.json")
    @Test fun test094OffsetPercentOverflow() = captureConfig("test-094-offset-percent-overflow.json")
    @Test fun test095OffsetPercentZero() = captureConfig("test-095-offset-percent-zero.json")
    @Test fun test096OffsetPercentResponsive() = captureConfig("test-096-offset-percent-responsive.json")
    @Test fun test097OffsetMixedUnits() = captureConfig("test-097-offset-mixed-units.json")
    @Test fun test098OffsetPercentNested() = captureConfig("test-098-offset-percent-nested.json")
    @Test fun test099OffsetPercentWithPadding() = captureConfig("test-099-offset-percent-with-padding.json")
    @Test fun test100OffsetPercentGalleryPeek() = captureConfig("test-100-offset-percent-gallery-peek.json")

    // ============================================================================
    // Phase 7: Aspect Ratio Tests (10 tests)
    // ============================================================================

    @Test fun test101AspectRatioSquareFixedWidth() = captureConfig("test-101-aspect-ratio-square-fixed-width.json")
    @Test fun test102AspectRatio16_9FixedWidth() = captureConfig("test-102-aspect-ratio-16-9-fixed-width.json")
    @Test fun test103AspectRatio4_3FixedWidth() = captureConfig("test-103-aspect-ratio-4-3-fixed-width.json")
    @Test fun test104AspectRatioFixedHeight() = captureConfig("test-104-aspect-ratio-fixed-height.json")
    @Test fun test105AspectRatioPercentWidth() = captureConfig("test-105-aspect-ratio-percent-width.json")
    @Test fun test106AspectRatioWrapContent() = captureConfig("test-106-aspect-ratio-wrap-content.json")
    @Test fun test107AspectRatioMatchParent() = captureConfig("test-107-aspect-ratio-match-parent.json")
    @Test fun test108AspectRatioExtremeWide() = captureConfig("test-108-aspect-ratio-extreme-wide.json")
    @Test fun test109AspectRatioExtremeTall() = captureConfig("test-109-aspect-ratio-extreme-tall.json")
    @Test fun test110AspectRatioMixedContainer() = captureConfig("test-110-aspect-ratio-mixed-container.json")

    // ============================================================================
    // Phase 8: Combined Scenarios (5 tests)
    // ============================================================================

    @Test fun test111CombinedAspectOffsetBox() = captureConfig("test-111-combined-aspect-offset-box.json")
    @Test fun test112CombinedNestedComplex() = captureConfig("test-112-combined-nested-complex.json")
    @Test fun test113CombinedGalleryAspectPeek() = captureConfig("test-113-combined-gallery-aspect-peek.json")
    @Test fun test114CombinedProductGrid() = captureConfig("test-114-combined-product-grid.json")
    @Test fun test115CombinedShowcaseAll() = captureConfig("test-115-combined-showcase-all.json")

    // ============================================================================
    // Phase 9: Special Dimensions Tests (5 tests)
    // ============================================================================

    @Test fun test116MatchParentComprehensive() = captureConfig("test-116-match-parent-comprehensive.json")
    @Test fun test117WrapContentComprehensive() = captureConfig("test-117-wrap-content-comprehensive.json")
    @Test fun test118MixedSpecialDimensions() = captureConfig("test-118-mixed-special-dimensions.json")
    @Test fun test119MatchParentStackBox() = captureConfig("test-119-match-parent-stack-box.json")
    @Test fun test120WrapContentConstraints() = captureConfig("test-120-wrap-content-constraints.json")

    // ============================================================================
    // Phase 10: Percentage BOX Container Test Suite (35 tests)
    // ============================================================================

    // Group 1: Aspect Ratio Showcases
    @Test fun test121HeroBannerImageTextButton() = captureConfig("test-121-16x9-ar-image-text-button.json")
    @Test fun test122SquareImageBadgeRounded() = captureConfig("test-122-1x1-ar-image-badge-rounded.json")
    @Test fun test123VideoCaption9x16() = captureConfig("test-123-9x16-ar-video-caption.json")
    @Test fun test124TextWeights4x3() = captureConfig("test-124-4x3-ar-text-weights.json")
    @Test fun test125ImageSplitButton2x1() = captureConfig("test-125-2x1-ar-image-split-button.json")

    // Group 2: TEXT Style Variations
    @Test fun test126TextFontWeights() = captureConfig("test-126-text-font-weights.json")
    @Test fun test127TextFontSizes() = captureConfig("test-127-text-font-sizes.json")
    @Test fun test128TextAlignment() = captureConfig("test-128-text-alignment.json")
    @Test fun test129TextDecorationItalic() = captureConfig("test-129-text-decoration-italic.json")
    @Test fun test130TextMaxlinesOverflow() = captureConfig("test-130-text-maxlines-overflow.json")
    @Test fun test131TextGradient() = captureConfig("test-131-text-gradient.json")

    // Group 3: IMAGE Variations
    @Test fun test132ImageFitCropContain() = captureConfig("test-132-image-fit-crop-contain.json")
    @Test fun test133ImageGifRounded() = captureConfig("test-133-image-gif-rounded.json")
    @Test fun test134ImageBorderRadius() = captureConfig("test-134-image-border-radius.json")
    @Test fun test135ImagesZOrder() = captureConfig("test-135-images-z-order.json")

    // Group 4: VIDEO Variations
    @Test fun test136VideoAutoplayMuted() = captureConfigAsGif("test-136-video-autoplay-muted.json")
    @Test fun test137VideoWithControls() = captureConfigAsGif("test-137-video-with-controls.json")
    @Test fun test138VideoButton9x16() = captureConfigAsGif("test-138-9x16-video-button.json")

    // Group 5: BUTTON Variations
    @Test fun test139ButtonCentered() = captureConfig("test-139-button-centered.json")
    @Test fun test140ButtonPrimarySecondary() = captureConfig("test-140-button-primary-secondary.json")
    @Test fun test141ButtonSizeVariants() = captureConfig("test-141-button-size-variants.json")
    @Test fun test142CtaCard() = captureConfig("test-142-cta-card.json")
    @Test fun test143ButtonRoundedText() = captureConfig("test-143-button-rounded-text.json")

    // Group 6: Rounded Corners
    @Test fun test144RoundedBoxText() = captureConfig("test-144-rounded-box-text.json")
    @Test fun test145NestedRoundedBoxes() = captureConfig("test-145-nested-rounded-boxes.json")
    @Test fun test146ImageOverlayRounded() = captureConfig("test-146-image-overlay-rounded.json")

    // Group 7: Complex Compositions
    @Test fun test147HeroBannerComplex() = captureConfig("test-147-hero-banner-complex.json")
    @Test fun test148ProductCardComplex() = captureConfig("test-148-product-card-complex.json")
    @Test fun test149NotificationCard() = captureConfig("test-149-notification-card.json")
    @Test fun test150DashboardWidget() = captureConfig("test-150-dashboard-widget.json")
    @Test fun test151VideoPlayerCard() = captureConfigAsGif("test-151-video-player-card.json")

    // Group 8: Edge Cases
    @Test fun test152TextCorners() = captureConfig("test-152-text-corners.json")
    @Test fun test153ImageClipped() = captureConfig("test-153-image-clipped.json")
    @Test fun test154NestedBoxDeep() = captureConfig("test-154-nested-box-deep.json")
    @Test fun test155AllElementTypes() = captureConfig("test-155-all-element-types.json")
    @Test fun test156ButtonBackgrounds() = captureConfig("test-156-button-backgrounds.json")

    // ============================================================================
    // Gallery Combination Tests (box-based, percentage sizing, all mode/indicator/nav combos)
    // ============================================================================

    // free_flow
    @Test fun test157GalleryBoxFreeflowIndicatorsNavbtns() = captureConfig("test-157-gallery-box-freeflow-indicators-navbtns.json")
    @Test fun test158GalleryBoxFreeflowIndicatorsOnly() = captureConfig("test-158-gallery-box-freeflow-indicators-only.json")
    @Test fun test159GalleryBoxFreeflowNavbtnsOnly() = captureConfig("test-159-gallery-box-freeflow-navbtns-only.json")
    @Test fun test160GalleryBoxFreeflowMinimal() = captureConfig("test-160-gallery-box-freeflow-minimal.json")
    @Test fun test161GalleryBoxFreeflowTallImages() = captureConfig("test-161-gallery-box-freeflow-tall-images.json")
    @Test fun test162GalleryBoxFreeflowVideoItems() = captureConfig("test-162-gallery-box-freeflow-video-items.json")
    @Test fun test163GalleryBoxFreeflowButtonItems() = captureConfig("test-163-gallery-box-freeflow-button-items.json")
    @Test fun test164GalleryBoxFreeflow5items() = captureConfig("test-164-gallery-box-freeflow-5items.json")

    // free_flow_grid
    @Test fun test165GalleryBoxGrid2colIndicatorsNavbtns() = captureConfig("test-165-gallery-box-grid2col-indicators-navbtns.json")
    @Test fun test166GalleryBoxGrid2colIndicatorsOnly() = captureConfig("test-166-gallery-box-grid2col-indicators-only.json")
    @Test fun test167GalleryBoxGrid2colNavbtnsOnly() = captureConfig("test-167-gallery-box-grid2col-navbtns-only.json")
    @Test fun test168GalleryBoxGrid2colMinimal() = captureConfig("test-168-gallery-box-grid2col-minimal.json")
    @Test fun test169GalleryBoxGrid3colIndicators() = captureConfig("test-169-gallery-box-grid3col-indicators.json")
    @Test fun test170GalleryBoxGrid3colNavbtns() = captureConfig("test-170-gallery-box-grid3col-navbtns.json")
    @Test fun test171GalleryBoxGrid2colVideo() = captureConfig("test-171-gallery-box-grid2col-video.json")
    @Test fun test172GalleryBoxGrid2colVertical() = captureConfig("test-172-gallery-box-grid2col-vertical.json")

    // snapping
    @Test fun test173GalleryBoxSnappingIndicatorsNavbtns() = captureConfig("test-173-gallery-box-snapping-indicators-navbtns.json")
    @Test fun test174GalleryBoxSnappingIndicatorsOnly() = captureConfig("test-174-gallery-box-snapping-indicators-only.json")
    @Test fun test175GalleryBoxSnappingNavbtnsOnly() = captureConfig("test-175-gallery-box-snapping-navbtns-only.json")
    @Test fun test176GalleryBoxSnappingMinimal() = captureConfig("test-176-gallery-box-snapping-minimal.json")

    // ============================================================================
    // HTML Element Tests
    // ============================================================================

    @Test fun test177HtmlInlineBasic() = captureConfig("test-177-html-inline-basic.json")
    @Test fun test178HtmlWithJavascript() = captureConfig("test-178-html-with-javascript.json")
    @Test fun test179HtmlTransparentBg() = captureConfig("test-179-html-transparent-bg.json")
    @Test fun test180HtmlScrollableContent() = captureConfig("test-180-html-scrollable-content.json")

    // ============================================================================
    // Verification Test
    // ============================================================================

    @Test fun testVerifyPercentageOffsetFix() = captureConfig("test-VERIFY-percentage-offset-fix.json")
}
