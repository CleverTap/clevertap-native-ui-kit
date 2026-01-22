package com.clevertap.android.nativeui.sample.screenshot

import android.content.Context
import androidx.activity.ComponentActivity
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.ui.Modifier
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onRoot
import androidx.test.core.app.ApplicationProvider
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.clevertap.android.nativeui.sample.JsonLoader
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.github.takahirom.roborazzi.captureRoboImage
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
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
)
@GraphicsMode(GraphicsMode.Mode.NATIVE)
@LooperMode(LooperMode.Mode.PAUSED)
class NativeDisplayScreenshotTest {

    @get:Rule
    val composeTestRule = createAndroidComposeRule<ComponentActivity>()

    private fun captureConfig(filename: String) {
        val config = JsonLoader.loadFromAssets(
            ApplicationProvider.getApplicationContext(),
            "test-configs/$filename"
        )

        require(config != null) { "Failed to load $filename" }

        composeTestRule.setContent {
            NativeDisplayView(
                config = config,
                modifier = Modifier.fillMaxSize()
            )
        }

        composeTestRule.waitForIdle()

        composeTestRule.onRoot().captureRoboImage(
            filePath = "configs/$filename.png"
        )
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
    @Test fun test054AllVideoElements() = captureConfig("test-054-all-video-elements.json")
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
}
