// Run: cd android-sample && ./gradlew :app:campaignScreenshots
//
// Screenshots land in:
//   build/outputs/connected_android_test_additional_output/debugAndroidTest/connected/<device>/
// The campaignScreenshots Gradle task then copies them to ~/Desktop/campaign-screenshots/.

package com.clevertap.android.nativeui.sample

import android.graphics.Bitmap.CompressFormat
import android.util.Log
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performTextClearance
import androidx.compose.ui.test.performTextInput
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.filters.LargeTest
import androidx.test.platform.app.InstrumentationRegistry
import androidx.test.runner.screenshot.BasicScreenCaptureProcessor
import androidx.test.runner.screenshot.Screenshot
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@LargeTest
@RunWith(AndroidJUnit4::class)
class CampaignScreenshotTest {

    @get:Rule
    val rule = createAndroidComposeRule<MainActivity>()

    @Test
    fun fireEventsAndCaptureScreenshots() {
        val events = listOf(
            "header1", "header2", "header3", "header4", "header5",
            "footer1", "footer2", "footer3", "footer4", "footer5"
        )

        val instrumentation = InstrumentationRegistry.getInstrumentation()

        // Use additionalTestOutputDir when available — AGP pulls this automatically
        // after the test run and before app uninstall, solving all timing issues.
        val additionalOutputDir = InstrumentationRegistry.getArguments()
            .getString("additionalTestOutputDir")
        val outputDir: File = if (additionalOutputDir != null) {
            File(additionalOutputDir, "campaign-screenshots")
        } else {
            File(instrumentation.targetContext.filesDir, "campaign-screenshots")
        }
        outputDir.mkdirs()
        Log.d("CampaignScreenshot", "Output dir: ${outputDir.absolutePath}")

        // mDefaultScreenshotPath is protected — subclass to set it
        val processor = object : BasicScreenCaptureProcessor() {
            init { mDefaultScreenshotPath = outputDir }
        }

        for (eventName in events) {
            rule.onNodeWithTag("ct-event-input").performTextClearance()
            rule.onNodeWithTag("ct-event-input").performTextInput(eventName)
            rule.onNodeWithTag("ct-send-event-btn").performClick()

            // Wait 2 s for the campaign to arrive from the server
            Thread.sleep(2_000)

            Screenshot.capture().apply {
                name = eventName
                format = CompressFormat.PNG
            }.process(setOf(processor))

            Log.d("CampaignScreenshot", "Captured: $eventName.png")
        }

        Log.d("CampaignScreenshot", "Done — ${events.size} screenshots in ${outputDir.absolutePath}")
    }
}
