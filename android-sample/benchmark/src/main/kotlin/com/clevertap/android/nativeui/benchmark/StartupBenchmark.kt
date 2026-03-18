package com.clevertap.android.nativeui.benchmark

import androidx.benchmark.macro.CompilationMode
import androidx.benchmark.macro.StartupMode
import androidx.benchmark.macro.StartupTimingMetric
import androidx.benchmark.macro.junit4.MacrobenchmarkRule
import androidx.test.ext.junit.runners.AndroidJUnit4
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Measures startup timing for the Native Display sample app.
 *
 * Results are measurement-only — no thresholds or assertions.
 * Run with: ./gradlew :benchmark:connectedBenchmarkAndroidTest
 */
@RunWith(AndroidJUnit4::class)
class StartupBenchmark {

    @get:Rule
    val benchmarkRule = MacrobenchmarkRule()

    companion object {
        private const val PACKAGE_NAME = "com.clevertap.android.nativeui.sample"
    }

    @Test
    fun coldStartup() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(StartupTimingMetric()),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.COLD,
        ) {
            pressHome()
            startActivityAndWait()
        }
    }

    @Test
    fun warmStartup() {
        benchmarkRule.measureRepeated(
            packageName = PACKAGE_NAME,
            metrics = listOf(StartupTimingMetric()),
            compilationMode = CompilationMode.DEFAULT,
            iterations = 5,
            startupMode = StartupMode.WARM,
        ) {
            pressHome()
            startActivityAndWait()
        }
    }
}
