// Drives the canonical EVENTS_TO_FIRE list against the Events tabs (Compose +
// XML) through each tab's *on-screen* event input UI. The point of these tests
// is the input UX itself — we want a human reviewer scrubbing the recording to
// see the EditText being typed into and the Send button being tapped. Firing
// events directly via CleverTapAPI.pushEvent() would skip past the very thing
// we're trying to demo.
//
// Each test wraps its body in recordVideo() so a full MP4 of the run is also
// pulled back to ~/Desktop/nd-automation-output/android/.
//
// Run via:
//   cd android-sample && ./gradlew :app:automationScreenshots

package com.clevertap.android.nativeui.sample.automation

import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.ComposeTimeoutException
import androidx.compose.ui.test.SemanticsNodeInteraction
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.action.ViewActions.replaceText
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import com.clevertap.android.nativeui.sample.MainActivity
import com.clevertap.android.nativeui.sample.R
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

@LargeTest
@RunWith(AndroidJUnit4::class)
class EventsScreenshotsTest {

    @get:Rule
    val rule = createAndroidComposeRule<MainActivity>()

    /**
     * Compose Events tab — `CleverTapIntegrationScreen`. The Events tab is the
     * default tab on launch (selectedTab=0), so we still tap it explicitly for
     * resilience against test ordering or `rememberSaveable` restoring a
     * different selection on rerun.
     *
     * For each event in [EVENTS_TO_FIRE]:
     *   1. Clear the input.
     *   2. Type the event name into `ct-event-input` (this also flips the
     *      Send button to enabled).
     *   3. Tap the `ct-send-event-btn`.
     *   4. Wait for server response.
     *   5. Screenshot.
     */
    @Test
    fun composeEventsScreen_fireAllEvents() {
        val testName = "composeEventsScreen_fireAllEvents"
        val context = InstrumentationRegistry.getInstrumentation().targetContext

        // Incremental asset-manifest automation: warm Coil's disk cache from the
        // URLs seen on previous runs BEFORE firing anything, and keep collecting
        // new URLs from this run's units. Together these remove the need to "run
        // the suite twice" for a warm capture.
        AssetManifestAutomation.warmCoilCache(context)
        val collector = AssetManifestAutomation.startCollecting(context)

        recordVideo(testName) {
            // Tabs are labeled by their visible text. "Events" is the Compose tab.
            rule.onNodeWithText("Events").performClick()
            rule.waitForIdle()

            // Hide the Compose event log so it doesn't cover the canvas.
            hideEventLogCompose(rule)

            for (eventName in EVENTS_TO_FIRE) {
                // DETERMINISTIC HANDSHAKE
                // -----------------------
                // Each screenshot must reflect the batch the *just-fired* event
                // produced, not a stale previous one. A fixed sleep can't
                // guarantee that: if the server is slower than the delay, the
                // canvas still shows the prior campaign.
                //
                // Instead we read the monotonically increasing batch counter
                // exposed by the screen as a zero-size "ct-units-count" node,
                // fire the event (which clears the canvas to "Waiting..."), then
                // block until the counter strictly increases — i.e. a brand new
                // batch has been delivered to the canvas.
                val before = readUnitsCount()

                val input = rule.onNodeWithTag("ct-event-input")
                // The text-field state persists between iterations; clear before
                // typing so we don't accumulate event names.
                input.performTextClearance()
                input.performTextInput(eventName)
                // Allow recomposition for the Send button's enabled state.
                rule.waitForIdle()

                rule.onNodeWithTag("ct-send-event-btn").performClick()

                // Block until a NEW batch lands (counter advances past `before`).
                // SCREENSHOT_SETTLE_DELAY_MS stays only as the upper-bound
                // fallback here. On timeout we proceed: the canvas was cleared on
                // send, so the capture shows the empty/"Waiting" state rather than
                // a stale campaign — still deterministic, just empty.
                try {
                    rule.waitUntil(timeoutMillis = HANDSHAKE_TIMEOUT_MS) {
                        readUnitsCount() > before
                    }
                } catch (e: ComposeTimeoutException) {
                    android.util.Log.w(
                        "ndAutomation",
                        "No new batch for '$eventName' within ${HANDSHAKE_TIMEOUT_MS}ms; " +
                            "capturing empty canvas",
                        e
                    )
                }

                // Brief settle so freshly-arrived images get a frame to paint
                // before the framebuffer grab.
                rule.waitForIdle()
                Thread.sleep(1_000)
                captureScreenshot("${testName}_$eventName")
            }
        }

        // Persist any newly-seen asset URLs for subsequent runs.
        AssetManifestAutomation.stopCollecting(context, collector)
    }

    /**
     * Reads the current value of the zero-size "ct-units-count" semantics node.
     * Returns -1 if the node or its text can't be read (treated as "older than
     * any real batch" so the handshake still waits for the first increment).
     */
    private fun readUnitsCount(): Int = try {
        val node: SemanticsNodeInteraction = rule.onNodeWithTag("ct-units-count")
        val text = node.fetchSemanticsNode()
            .config[SemanticsProperties.Text]
            .firstOrNull()
            ?.text
        text?.toIntOrNull() ?: -1
    } catch (_: Throwable) {
        -1
    }

    /**
     * XML Events tab — `XmlFeedScreen` hosting `XmlFeedFragment`. The fragment
     * uses Views, not Compose, so we tap the tab in Compose then operate on
     * the XML input/button via Espresso.
     *
     * Same loop as the Compose variant — clear, type, tap, wait, screenshot —
     * but driving the XML EditText (`R.id.eventNameInput`) and Button
     * (`R.id.sendEventButton`). The button's `enabled` flips on a TextWatcher
     * when the input is non-blank, so we type first.
     */
    @Test
    fun xmlEventsScreen_fireAllEvents() {
        val testName = "xmlEventsScreen_fireAllEvents"
        recordVideo(testName) {
            rule.onNodeWithText("XML Test").performClick()
            rule.waitForIdle()
            // Give the FragmentTransaction time to inflate.
            Thread.sleep(500)

            hideEventLogXml()

            for (eventName in EVENTS_TO_FIRE) {
                // replaceText() handles both clearing and typing in one shot;
                // it also drives the TextWatcher that flips the Send button
                // enabled state.
                onView(withId(R.id.eventNameInput)).perform(replaceText(eventName))
                onView(withId(R.id.sendEventButton)).perform(click())
                Thread.sleep(SCREENSHOT_SETTLE_DELAY_MS)
                rule.waitForIdle()
                captureScreenshot("${testName}_$eventName")
            }
        }
    }
}
