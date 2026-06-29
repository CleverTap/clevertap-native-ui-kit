// Drives the Slots tabs (Compose + XML) by tapping the on-screen "Fetch Slot
// Data" button, waiting for the slot views to populate, then fast-scrolling
// the feed top → bottom → top. Each phase produces one screenshot so a human
// reviewer can confirm:
//   1. Slots populate after the fetch (`after_fetch`).
//   2. The bottom rows render correctly (`at_bottom`).
//   3. The top rows still look right after scroll-back (`back_at_top`).
//
// We intentionally do NOT jump to the Events tab and fire individual events
// from these tests — the in-app "Fetch Slot Data" button fires the canonical
// slot-trigger event sequence (Footer1, Footer5, Header1, Header2, Header4,
// lalit) all at once, which is the realistic user flow on the Slots tab.
// Event-level coverage lives in `EventsScreenshotsTest`.
//
// Run via:
//   cd android-sample && ./gradlew :app:automationScreenshots

package com.clevertap.android.nativeui.sample.automation

import android.view.View
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollToIndex
import androidx.recyclerview.widget.RecyclerView
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.UiController
import androidx.test.espresso.ViewAction
import androidx.test.espresso.action.ViewActions
import androidx.test.espresso.matcher.ViewMatchers
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.espresso.matcher.ViewMatchers.withText
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import com.clevertap.android.nativeui.sample.MainActivity
import com.clevertap.android.nativeui.sample.R
import org.hamcrest.Matcher
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class SlotsScreenshotsTest {

    @get:Rule
    val rule = createAndroidComposeRule<MainActivity>()

    /**
     * Compose Slots tab — `SlotDemoScreen`. LazyColumn structure:
     *   - item 0: header (title + description + "Fetch Slot Data" button)
     *   - items 1..19: 4 slot placeholders interleaved with 15 app content cards
     *
     * `performScrollToIndex` snaps the LazyColumn straight to the target item
     * without any animation lerp, which is exactly what we want — no fluff.
     */
    @Test
    fun composeSlotsScreen_fetchAndScroll() {
        val testName = "composeSlotsScreen_fetchAndScroll"
        recordVideo(testName) {
            rule.onNodeWithText("Slots").performClick()
            rule.waitForIdle()

            // The in-app button fires the canonical 6-event slot-trigger sequence.
            rule.onNodeWithText("Fetch Slot Data").performClick()
            // Allow the slowest server response to land before screenshotting;
            // matches the dwell time used by the legacy FetchSlotFlowTest.
            Thread.sleep(3_000)
            rule.waitForIdle()
            captureScreenshot("${testName}_after_fetch")

            // SlotDemoScreen builds 1 header + 19 feed items -> index 19 is last.
            val feed = rule.onNodeWithTag("slot-demo-feed")
            feed.performScrollToIndex(19)
            rule.waitForIdle()
            // Brief settle for image loading on the freshly-bound cards.
            Thread.sleep(500)
            captureScreenshot("${testName}_at_bottom")

            feed.performScrollToIndex(0)
            rule.waitForIdle()
            Thread.sleep(500)
            captureScreenshot("${testName}_back_at_top")
        }
    }

    /**
     * XML Slots tab — `XmlSlotsScreen` hosting `XmlSlotsFragment`. The whole
     * fragment is a single RecyclerView (`R.id.slotRecycler`) backed by
     * `SlotFeedAdapter` with the same 1 header + 19 feed items shape as the
     * Compose variant.
     *
     * Uses an inline [scrollRecyclerToPosition] ViewAction (defined below)
     * that just calls `RecyclerView.scrollToPosition()` — no animation lerp,
     * the bottom row is rendered on the next layout pass.
     */
    @Test
    fun xmlSlotsScreen_fetchAndScroll() {
        val testName = "xmlSlotsScreen_fetchAndScroll"
        recordVideo(testName) {
            rule.onNodeWithText("XML Slots").performClick()
            rule.waitForIdle()
            Thread.sleep(500) // Fragment inflation.

            // The "Fetch Slot Data" MaterialButton lives in row 0 of the
            // RecyclerView (the header view holder). It's a real View, so
            // Espresso clicks it.
            onView(withText("Fetch Slot Data")).perform(ViewActions.click())
            Thread.sleep(3_000)
            rule.waitForIdle()
            captureScreenshot("${testName}_after_fetch")

            // 1 header + 19 feed items -> position 19 is last.
            onView(withId(R.id.slotRecycler)).perform(scrollRecyclerToPosition(19))
            rule.waitForIdle()
            Thread.sleep(500)
            captureScreenshot("${testName}_at_bottom")

            onView(withId(R.id.slotRecycler)).perform(scrollRecyclerToPosition(0))
            rule.waitForIdle()
            Thread.sleep(500)
            captureScreenshot("${testName}_back_at_top")
        }
    }

    /**
     * Tiny custom [ViewAction] equivalent of
     * `RecyclerViewActions.scrollToPosition` — kept inline to avoid pulling in
     * the espresso-contrib artifact (which would also drag in older hamcrest
     * and conflict with the compose-test classpath).
     *
     * Calls `scrollToPosition()` (no animation) so the target row is laid out
     * by the next frame; we still sleep briefly afterwards in the caller to
     * let Coil's image loader settle on the freshly-bound slot views.
     */
    private fun scrollRecyclerToPosition(position: Int): ViewAction = object : ViewAction {
        override fun getConstraints(): Matcher<View> =
            ViewMatchers.isAssignableFrom(RecyclerView::class.java)

        override fun getDescription(): String = "scroll RecyclerView to position $position"

        override fun perform(uiController: UiController, view: View) {
            (view as RecyclerView).scrollToPosition(position)
            uiController.loopMainThreadUntilIdle()
        }
    }
}
