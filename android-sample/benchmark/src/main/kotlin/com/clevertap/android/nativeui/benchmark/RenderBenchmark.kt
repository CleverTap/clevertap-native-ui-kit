package com.clevertap.android.nativeui.benchmark

import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.FrameTimingMetric
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.TraceSectionMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.uiautomator.By
import androidx.test.uiautomator.Direction
import androidx.test.uiautomator.Until
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Measures rendering performance for Native Display SDK components.
 *
 * Captures:
 * - Frame timing (p50/p90/p95/p99) for gallery scroll
 * - Trace section durations for JSON parsing, style resolution, and rendering
 *
 * Results are measurement-only — no thresholds or assertions.
 * Run with: ./gradlew :benchmark:connectedBenchmarkAndroidTest
 */
@RunWith(AndroidJUnit4::class)
class RenderBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    companion object {
        private const val PACKAGE_NAME = "com.clevertap.android.nativeui.sample"
        private const val TIMEOUT_MS = 10_000L
    }

    /**
     * Measure frame timing during gallery scroll interaction.
     * Reports p50/p90/p95/p99 frame durations.
     */
    @Test
    fun galleryScroll_frameTimingMetric() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(FrameTimingMetric()),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()

            // Wait for the app content to be ready
            device.wait(Until.hasObject(By.textContains("Gallery")), TIMEOUT_MS)

            // Try to find and tap a gallery demo entry
            val galleryItem = device.findObject(By.textContains("Gallery"))
            galleryItem?.click()
            device.waitForIdle()

            // Scroll horizontally in the gallery
            val scrollable = device.findObject(By.scrollable(true))
            if (scrollable != null) {
                repeat(3) {
                    scrollable.fling(Direction.RIGHT)
                    device.waitForIdle()
                }
                repeat(3) {
                    scrollable.fling(Direction.LEFT)
                    device.waitForIdle()
                }
            }
        }
    }

    /**
     * Measure JSON parse time via trace section.
     */
    @Test
    fun parseConfig_traceSectionMetric() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(TraceSectionMetric("SDUI:parseConfig")),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()

            // Navigate to trigger config loading
            device.wait(Until.hasObject(By.textContains("Gallery")), TIMEOUT_MS)
            val item = device.findObject(By.textContains("Gallery"))
            item?.click()
            device.waitForIdle()
        }
    }

    /**
     * Measure style resolution time via trace section.
     */
    @Test
    fun resolveStyles_traceSectionMetric() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(TraceSectionMetric("SDUI:resolveStyles")),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()

            device.wait(Until.hasObject(By.textContains("Gallery")), TIMEOUT_MS)
            val item = device.findObject(By.textContains("Gallery"))
            item?.click()
            device.waitForIdle()
        }
    }

    /**
     * Measure NativeDisplayView render time via trace section.
     */
    @Test
    fun nativeDisplayView_traceSectionMetric() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(TraceSectionMetric("SDUI:NativeDisplayView")),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()

            device.wait(Until.hasObject(By.textContains("Gallery")), TIMEOUT_MS)
            val item = device.findObject(By.textContains("Gallery"))
            item?.click()
            device.waitForIdle()
        }
    }

    /**
     * Measure gallery container rendering time via trace section.
     */
    @Test
    fun galleryContainer_traceSectionMetric() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(TraceSectionMetric("SDUI:Container:GALLERY")),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()

            device.wait(Until.hasObject(By.textContains("Gallery")), TIMEOUT_MS)
            val item = device.findObject(By.textContains("Gallery"))
            item?.click()
            device.waitForIdle()
        }
    }
}
