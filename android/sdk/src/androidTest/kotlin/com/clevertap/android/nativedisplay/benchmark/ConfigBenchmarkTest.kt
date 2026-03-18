package com.clevertap.android.nativedisplay.benchmark

import android.util.Log
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.serialization.json.Json
import org.junit.Before
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Instrumented benchmark tests that measure JSON parsing and style resolution
 * performance for configs of varying complexity.
 *
 * These tests are measurement-only: they log timing results via Log.d
 * without asserting thresholds. Use the output to detect regressions manually.
 *
 * NOTE: JSON parsing is measured here for regression tracking, but in production
 * this SDK receives pre-parsed ResolvedConfig objects. The calling SDK is
 * responsible for parsing JSON on a background thread before passing the
 * resolved config to NativeDisplayView.
 *
 * Run with: ./gradlew :sdk:connectedDebugAndroidTest --tests "*.benchmark.*"
 *
 * Filter logs: adb logcat -s "SDUI:Benchmark"
 */
@RunWith(AndroidJUnit4::class)
class ConfigBenchmarkTest {

    companion object {
        private const val TAG = "SDUI:Benchmark"
        private const val TOTAL_ITERATIONS = 55
        private const val WARMUP_ITERATIONS = 5
    }

    private val json = Json {
        ignoreUnknownKeys = true
        isLenient = true
    }

    private val benchmarkFiles = listOf(
        "benchmark_minimal.json",
        "benchmark_simple.json",
        "benchmark_medium.json",
        "benchmark_gallery.json",
        "benchmark_stress.json",
        "benchmark_extreme.json",
    )

    private val jsonContents = mutableMapOf<String, String>()

    @Before
    fun setUp() {
        val context = InstrumentationRegistry.getInstrumentation().context
        for (file in benchmarkFiles) {
            jsonContents[file] = context.assets.open(file).bufferedReader().use { it.readText() }
        }
        Log.d(TAG, "Loaded ${jsonContents.size} benchmark configs from androidTest assets")
    }

    // -------------------------------------------------------------------------
    // JSON Parsing Benchmarks
    // -------------------------------------------------------------------------

    @Test
    fun parse_benchmarkMinimal() {
        measureParsing("benchmark_minimal.json")
    }

    @Test
    fun parse_benchmarkSimple() {
        measureParsing("benchmark_simple.json")
    }

    @Test
    fun parse_benchmarkMedium() {
        measureParsing("benchmark_medium.json")
    }

    @Test
    fun parse_benchmarkGallery() {
        measureParsing("benchmark_gallery.json")
    }

    @Test
    fun parse_benchmarkStress() {
        measureParsing("benchmark_stress.json")
    }

    @Test
    fun parse_benchmarkExtreme() {
        measureParsing("benchmark_extreme.json")
    }

    // -------------------------------------------------------------------------
    // Style Resolution Benchmarks
    // -------------------------------------------------------------------------

    @Test
    fun resolveStyles_benchmarkMinimal() {
        measureStyleResolution("benchmark_minimal.json")
    }

    @Test
    fun resolveStyles_benchmarkStress() {
        measureStyleResolution("benchmark_stress.json")
    }

    @Test
    fun resolveStyles_benchmarkExtreme() {
        measureStyleResolution("benchmark_extreme.json")
    }

    // -------------------------------------------------------------------------
    // Full Pipeline Benchmarks (parse + resolve)
    // -------------------------------------------------------------------------

    @Test
    fun fullPipeline_benchmarkMinimal() {
        measureFullPipeline("benchmark_minimal.json")
    }

    @Test
    fun fullPipeline_benchmarkStress() {
        measureFullPipeline("benchmark_stress.json")
    }

    @Test
    fun fullPipeline_benchmarkExtreme() {
        measureFullPipeline("benchmark_extreme.json")
    }

    // -------------------------------------------------------------------------
    // Measurement Helpers
    // -------------------------------------------------------------------------

    private fun measureParsing(fileName: String) {
        val jsonString = jsonContents[fileName]
            ?: error("Missing benchmark file: $fileName")
        val label = fileName.removeSuffix(".json")

        val timingsNs = LongArray(TOTAL_ITERATIONS)
        for (i in 0 until TOTAL_ITERATIONS) {
            val startNs = System.nanoTime()
            json.decodeFromString<ResolvedConfig>(jsonString)
            timingsNs[i] = System.nanoTime() - startNs
        }

        logResults("parse", label, timingsNs)
    }

    private fun measureStyleResolution(fileName: String) {
        val jsonString = jsonContents[fileName]
            ?: error("Missing benchmark file: $fileName")
        val label = fileName.removeSuffix(".json")

        // Parse once upfront (not measured)
        val config = json.decodeFromString<ResolvedConfig>(jsonString)
        val root = config.root

        val timingsNs = LongArray(TOTAL_ITERATIONS)
        for (i in 0 until TOTAL_ITERATIONS) {
            val resolver = StyleResolver(
                theme = config.theme,
                styleClasses = config.styleClasses,
            )
            val startNs = System.nanoTime()
            resolver.resolveAll(root)
            timingsNs[i] = System.nanoTime() - startNs
        }

        logResults("resolveStyles", label, timingsNs)
    }

    private fun measureFullPipeline(fileName: String) {
        val jsonString = jsonContents[fileName]
            ?: error("Missing benchmark file: $fileName")
        val label = fileName.removeSuffix(".json")

        val timingsNs = LongArray(TOTAL_ITERATIONS)
        for (i in 0 until TOTAL_ITERATIONS) {
            val startNs = System.nanoTime()
            val config = json.decodeFromString<ResolvedConfig>(jsonString)
            val resolver = StyleResolver(
                theme = config.theme,
                styleClasses = config.styleClasses,
            )
            resolver.resolveAll(config.root)
            timingsNs[i] = System.nanoTime() - startNs
        }

        logResults("fullPipeline", label, timingsNs)
    }

    private fun logResults(phase: String, label: String, timingsNs: LongArray) {
        // Drop warmup iterations
        val measured = timingsNs.drop(WARMUP_ITERATIONS)
        val count = measured.size
        val sorted = measured.sorted()

        val avgMs = measured.average() / 1_000_000.0
        val minMs = sorted.first() / 1_000_000.0
        val maxMs = sorted.last() / 1_000_000.0
        val medianMs = sorted[count / 2] / 1_000_000.0
        val p95Ms = sorted[(count * 0.95).toInt().coerceAtMost(count - 1)] / 1_000_000.0

        val phaseName = when (phase) {
            "parse" -> "JSON Parsing"
            "resolveStyles" -> "Style Resolution"
            "fullPipeline" -> "Full Pipeline (Parse + Resolve)"
            else -> phase
        }
        val configName = label
            .removePrefix("benchmark_")
            .replaceFirstChar { it.uppercase() }

        Log.d(TAG, "")
        Log.d(TAG, "========================================")
        Log.d(TAG, " $phaseName — $configName Config")
        Log.d(TAG, "========================================")
        Log.d(TAG, "  Iterations : $count (after $WARMUP_ITERATIONS warmup)")
        Log.d(TAG, "  Average    : %.3f ms".format(avgMs))
        Log.d(TAG, "  Median     : %.3f ms".format(medianMs))
        Log.d(TAG, "  Min        : %.3f ms".format(minMs))
        Log.d(TAG, "  Max        : %.3f ms".format(maxMs))
        Log.d(TAG, "  P95        : %.3f ms".format(p95Ms))
        Log.d(TAG, "========================================")
    }
}