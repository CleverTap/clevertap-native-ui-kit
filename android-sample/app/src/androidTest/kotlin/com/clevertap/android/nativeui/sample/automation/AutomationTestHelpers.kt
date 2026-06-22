// Shared helpers for the events/slots screenshot automation suite.
//
// Used by EventsScreenshotsTest, SlotsScreenshotsTest, FetchSlotFlowTest.
// All tests fire a fixed sequence of CleverTap events on a target screen
// (Compose Events, Compose Slots, XML Events, XML Slots), and screenshot
// the canvas after each event so a human can scrub through and verify the
// rendered native-display campaigns visually.
//
// Output artifacts (screenshots + screen recordings) land in
// AGP's `additionalTestOutputDir`, which the `automationScreenshots`
// Gradle task pulls to ~/Desktop/nd-automation-output/android/.

package com.clevertap.android.nativeui.sample.automation

import android.graphics.Bitmap.CompressFormat
import android.os.ParcelFileDescriptor
import android.util.Log
import androidx.compose.ui.test.junit4.AndroidComposeTestRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.test.espresso.Espresso.onView
import androidx.test.espresso.NoMatchingViewException
import androidx.test.espresso.action.ViewActions.click
import androidx.test.espresso.matcher.ViewMatchers.isDisplayed
import androidx.test.espresso.matcher.ViewMatchers.withId
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.screenshot.BasicScreenCaptureProcessor
import androidx.test.runner.screenshot.Screenshot
import com.clevertap.android.nativeui.sample.R
import com.clevertap.android.sdk.CleverTapAPI
import java.io.File
import java.io.FileInputStream
import java.io.FileOutputStream

/**
 * Fixed event list the suite fires on each target screen.
 *
 * Order and casing matter — these are the exact event names provisioned on
 * the CleverTap dashboard for this sample app. The first ten (header1–5,
 * footer1–5) trigger inline native-display campaigns; the rest map to slots.
 */
val EVENTS_TO_FIRE: List<String> = listOf(
    "header1", "header2", "header3", "header4", "header5",
    "footer1", "footer2", "footer3", "footer4", "footer5",
    "nps", "topi", "kk", "mm", "ii", "iip", "ss", "cptest", "hi", "viewed", "html2", "home"
)

/**
 * CleverTap server response latency is the dominant source of test flake here.
 * 1.5s is the floor below which we see slots not yet populated by the time
 * the screenshot is taken. Bump to 2.5s if flaky.
 */
private const val EVENT_SETTLE_DELAY_MS = 1_500L

private const val TAG = "ndAutomation"

/**
 * Fires a CleverTap event via the default SDK instance and waits for the
 * server response to land so the on-screen UI has settled.
 *
 * Safe to call before the bridge has any listeners — pushEvent is async
 * and the server response drives the bridge listener registered by each
 * target screen.
 */
fun pushEvent(name: String) {
    val context = InstrumentationRegistry.getInstrumentation().targetContext
    val api = CleverTapAPI.getDefaultInstance(context.applicationContext)
    if (api == null) {
        Log.w(TAG, "CleverTapAPI default instance is null; skipping pushEvent($name)")
        return
    }
    api.pushEvent(name)
    Log.d(TAG, "Fired event: $name")
    Thread.sleep(EVENT_SETTLE_DELAY_MS)
}

/**
 * Taps the Compose "event-log-toggle" if currently visible/expanded, so the
 * log doesn't obscure the canvas in screenshots. Tap is a no-op effect-wise
 * if the log is already hidden — but if we tap when hidden we'd re-show it.
 * So we only tap when the log content node is currently displayed.
 *
 * Idempotent in the "log is hidden after this call" sense.
 */
fun <A : androidx.activity.ComponentActivity> hideEventLogCompose(
    rule: AndroidComposeTestRule<*, A>
) {
    try {
        // If the content is visible, the assertExists call succeeds and we tap.
        rule.onNodeWithTag("event-log-content").assertExists()
        rule.onNodeWithTag("event-log-toggle").performClick()
        // Settle one Compose frame so the screenshot reflects the hidden state.
        rule.waitForIdle()
    } catch (_: AssertionError) {
        // Content already hidden — nothing to do.
        Log.d(TAG, "Compose event log already hidden")
    } catch (_: Throwable) {
        // Toggle not present on this screen — also fine, swallow.
        Log.d(TAG, "Compose event log toggle not present")
    }
}

/**
 * Espresso equivalent of [hideEventLogCompose] for XML fragments.
 *
 * Tap rule: only tap when the content ScrollView (`R.id.event_log_content`)
 * is currently displayed. Otherwise the toggle would re-show it.
 */
fun hideEventLogXml() {
    val isVisible = try {
        onView(withId(R.id.event_log_content)).check { view, _ ->
            if (!view.isShown) throw AssertionError("hidden")
        }
        true
    } catch (_: Throwable) {
        false
    }
    if (isVisible) {
        try {
            onView(withId(R.id.event_log_toggle)).perform(click())
        } catch (e: NoMatchingViewException) {
            Log.d(TAG, "XML event log toggle not present", e)
        }
    } else {
        Log.d(TAG, "XML event log already hidden or content view not present")
    }
}

/**
 * Writes a screenshot of the current screen into AGP's `additionalTestOutputDir`,
 * which is pulled to the host machine automatically after the test run. Filename
 * pattern matches what the deleted `CampaignScreenshotTest` produced so existing
 * Desktop-pull tooling stays compatible.
 *
 * Filenames: `<label>.png` — callers pass `<testMethod>_<eventOrLabel>` so the
 * test method appears in the filename without us having to thread JUnit's
 * TestInfo through every call.
 */
fun captureScreenshot(label: String) {
    val outputDir = additionalOutputDir()
    outputDir.mkdirs()
    val processor = object : BasicScreenCaptureProcessor() {
        init { mDefaultScreenshotPath = outputDir }
    }
    Screenshot.capture().apply {
        name = label
        format = CompressFormat.PNG
    }.process(setOf(processor))
    Log.d(TAG, "Captured: ${File(outputDir, "$label.png").absolutePath}")
}

/**
 * Runs [body] while screen-recording the device into an MP4 attached to the
 * test output dir. Best-effort: if `screenrecord` fails (most emulators
 * don't support it, hardware-accelerated emulators sometimes do), we log
 * the failure and run the body without recording rather than failing the
 * test outright. The point of the suite is the screenshots; the videos
 * are a nice-to-have for human review.
 *
 * Implementation note: `screenrecord` is shell-side and only stops when:
 *   1. SIGINT is sent, OR
 *   2. The --time-limit (max 180s) elapses.
 * We rely on a generous time-limit and kill the process after the body
 * completes so the file is flushed.
 */
fun recordVideo(testName: String, body: () -> Unit) {
    val deviceMp4 = "/sdcard/$testName.mp4"
    val automation = InstrumentationRegistry.getInstrumentation().uiAutomation

    // Make sure no stale file is present from a previous run.
    try {
        automation.executeShellCommand("rm -f $deviceMp4").close()
    } catch (_: Throwable) { /* ignore */ }

    var recordingPfd: ParcelFileDescriptor? = null
    try {
        // Cap at the screenrecord 180s ceiling; we'll usually stop earlier.
        recordingPfd = try {
            automation.executeShellCommand("screenrecord --time-limit 180 $deviceMp4")
        } catch (t: Throwable) {
            Log.w(TAG, "screenrecord failed to start — running without video", t)
            null
        }
    } catch (t: Throwable) {
        Log.w(TAG, "screenrecord setup failed — running without video", t)
    }

    try {
        body()
    } finally {
        // Stop screenrecord by killing it. SIGINT lets it flush the MP4 trailer.
        if (recordingPfd != null) {
            try {
                automation.executeShellCommand("pkill -INT -f screenrecord").close()
            } catch (_: Throwable) { /* ignore */ }
            try { recordingPfd.close() } catch (_: Throwable) { /* ignore */ }

            // Give the encoder a moment to finalize the file.
            Thread.sleep(1_500)

            // Pull the file from /sdcard into additionalTestOutputDir.
            try {
                pullDeviceFile(deviceMp4, File(additionalOutputDir(), "$testName.mp4"))
                automation.executeShellCommand("rm -f $deviceMp4").close()
            } catch (t: Throwable) {
                Log.w(TAG, "Failed to pull screen recording", t)
            }
        }
    }
}

/**
 * Resolves the dir AGP pulls back to the host after the test run. Falls
 * back to the app's internal files dir if running outside AGP for some
 * reason (which never actually happens in our pipeline but keeps the code
 * defensible).
 */
private fun additionalOutputDir(): File {
    val arg = InstrumentationRegistry.getArguments().getString("additionalTestOutputDir")
    return if (arg != null) {
        File(arg)
    } else {
        File(
            InstrumentationRegistry.getInstrumentation().targetContext.filesDir,
            "automation-output"
        )
    }
}

/**
 * Reads [devicePath] (e.g. `/sdcard/foo.mp4`) via UiAutomation's shell
 * (since the test process can't read /sdcard directly on modern Android)
 * and writes it to [hostFile] under additionalTestOutputDir.
 */
private fun pullDeviceFile(devicePath: String, hostFile: File) {
    val automation = InstrumentationRegistry.getInstrumentation().uiAutomation
    automation.executeShellCommand("cat $devicePath").use { pfd ->
        FileInputStream(pfd.fileDescriptor).use { input ->
            hostFile.parentFile?.mkdirs()
            FileOutputStream(hostFile).use { output ->
                input.copyTo(output)
            }
        }
    }
    Log.d(TAG, "Pulled $devicePath -> ${hostFile.absolutePath}")
}
