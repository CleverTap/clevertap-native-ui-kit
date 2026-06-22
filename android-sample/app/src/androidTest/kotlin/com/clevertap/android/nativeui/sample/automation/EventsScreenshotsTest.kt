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
        recordVideo(testName) {
            // Tabs are labeled by their visible text. "Events" is the Compose tab.
            rule.onNodeWithText("Events").performClick()
            rule.waitForIdle()

            // Hide the Compose event log so it doesn't cover the canvas.
            hideEventLogCompose(rule)

            for (eventName in EVENTS_TO_FIRE) {
                val input = rule.onNodeWithTag("ct-event-input")
                // The text-field state persists between iterations; clear before
                // typing so we don't accumulate event names.
                input.performTextClearance()
                input.performTextInput(eventName)
                // Allow recomposition for the Send button's enabled state.
                rule.waitForIdle()

                rule.onNodeWithTag("ct-send-event-btn").performClick()
                // Server latency is the dominant flake source; match the floor
                // used by pushEvent() in AutomationTestHelpers.
                Thread.sleep(1_500L)
                rule.waitForIdle()
                captureScreenshot("${testName}_$eventName")
            }
        }
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
                Thread.sleep(1_500L)
                rule.waitForIdle()
                captureScreenshot("${testName}_$eventName")
            }
        }
    }
}
