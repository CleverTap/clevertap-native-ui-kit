package com.clevertap.android.nativedisplay.renderer

import android.util.Log
import androidx.compose.foundation.layout.Column
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.SideEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.setValue
import androidx.compose.ui.test.junit4.createComposeRule
import com.clevertap.android.nativedisplay.models.ChildArrangement
import com.clevertap.android.nativedisplay.models.ContainerType
import com.clevertap.android.nativedisplay.models.Dimension
import com.clevertap.android.nativedisplay.models.ElementType
import com.clevertap.android.nativedisplay.models.Layout
import com.clevertap.android.nativedisplay.models.NativeDisplayContainer
import com.clevertap.android.nativedisplay.models.NativeDisplayElement
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.SpecialDimension
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.models.Theme
import org.junit.Rule
import org.junit.Test
import java.util.concurrent.atomic.AtomicInteger

/**
 * Instrumented tests that measure recomposition behavior of NativeDisplayView.
 *
 * Key scenario: a client app hosts NativeDisplayView inside their screen.
 * When the client's own state changes (counter, toggle, ViewModel update),
 * does the SDK's composable tree unnecessarily recompose and redo work
 * like style resolution, variable evaluation, or re-rendering nodes?
 *
 * These tests are measurement-only: they log recomposition counts via Log.d
 * without asserting thresholds.
 */
class RecompositionCountTest {

    @get:Rule
    val composeTestRule = createComposeRule()

    companion object {
        private const val TAG = "SDUI:Benchmark"
    }

    // -------------------------------------------------------------------------
    // Scenario 1: Parent recomposes, SDK config unchanged
    //
    // Simulates: client screen has a counter/toggle that changes frequently.
    // The SDK config stays the same. Does NativeDisplayView skip recomposition?
    // IDEAL: sduiRecompCount stays at 1 (initial only), parentRecompCount grows.
    // BAD: sduiRecompCount grows with parentRecompCount (unnecessary work).
    // -------------------------------------------------------------------------

    @Test
    fun parentRecomposition_sduiConfigUnchanged_simpleConfig() {
        val parentRecompCount = AtomicInteger(0)
        val sduiRecompCount = AtomicInteger(0)

        val config = buildSimpleConfig()
        var unrelatedCounter by mutableIntStateOf(0)

        composeTestRule.setContent {
            // Simulate a client screen that reads unrelated state
            Column {
                SideEffect { parentRecompCount.incrementAndGet() }

                // Client's own UI that changes
                Text("Counter: $unrelatedCounter")

                // SDK view — config never changes
                RecompositionTracker(sduiRecompCount) {
                    NativeDisplayView(config = config)
                }
            }
        }

        composeTestRule.waitForIdle()
        val initialParent = parentRecompCount.get()
        val initialSdui = sduiRecompCount.get()

        // Trigger 5 parent recompositions via unrelated state changes
        repeat(5) {
            unrelatedCounter++
            composeTestRule.waitForIdle()
        }

        val finalParent = parentRecompCount.get()
        val finalSdui = sduiRecompCount.get()

        Log.d(TAG, "")
        Log.d(TAG, "========================================")
        Log.d(TAG, " Parent Recomposition — Simple Config")
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, " Scenario: Client state changes 5 times,")
        Log.d(TAG, " SDK config stays the same.")
        Log.d(TAG, "========================================")
        Log.d(TAG, "  Parent recomps : $initialParent -> $finalParent (delta: ${finalParent - initialParent})")
        Log.d(TAG, "  SDUI recomps   : $initialSdui -> $finalSdui (delta: ${finalSdui - initialSdui})")
        Log.d(TAG, "  SDUI skipped?  : ${if (finalSdui == initialSdui) "YES — no unnecessary work" else "NO — SDK recomposed unnecessarily!"}")
        Log.d(TAG, "========================================")
    }

    @Test
    fun parentRecomposition_sduiConfigUnchanged_complexConfig() {
        val parentRecompCount = AtomicInteger(0)
        val sduiRecompCount = AtomicInteger(0)

        val config = buildComplexConfig()
        var unrelatedCounter by mutableIntStateOf(0)

        composeTestRule.setContent {
            Column {
                SideEffect { parentRecompCount.incrementAndGet() }
                Text("Counter: $unrelatedCounter")

                RecompositionTracker(sduiRecompCount) {
                    NativeDisplayView(config = config)
                }
            }
        }

        composeTestRule.waitForIdle()
        val initialParent = parentRecompCount.get()
        val initialSdui = sduiRecompCount.get()

        repeat(5) {
            unrelatedCounter++
            composeTestRule.waitForIdle()
        }

        val finalParent = parentRecompCount.get()
        val finalSdui = sduiRecompCount.get()

        Log.d(TAG, "")
        Log.d(TAG, "========================================")
        Log.d(TAG, " Parent Recomposition — Complex Config")
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, " Scenario: Client state changes 5 times,")
        Log.d(TAG, " SDK config stays the same.")
        Log.d(TAG, " Config: Nested VERTICAL+HORIZONTAL, 5 TEXT")
        Log.d(TAG, "========================================")
        Log.d(TAG, "  Parent recomps : $initialParent -> $finalParent (delta: ${finalParent - initialParent})")
        Log.d(TAG, "  SDUI recomps   : $initialSdui -> $finalSdui (delta: ${finalSdui - initialSdui})")
        Log.d(TAG, "  SDUI skipped?  : ${if (finalSdui == initialSdui) "YES — no unnecessary work" else "NO — SDK recomposed unnecessarily!"}")
        Log.d(TAG, "========================================")
    }

    // -------------------------------------------------------------------------
    // Scenario 2: Config actually changes — SDK SHOULD recompose
    //
    // Verifies that when the config changes, the SDK does pick it up.
    // IDEAL: sduiRecompCount increments by exactly 1 per config change.
    // -------------------------------------------------------------------------

    @Test
    fun configChange_sduiShouldRecompose() {
        val scopeRecompCount = AtomicInteger(0)
        val config1 = buildSimpleConfig()
        val config2 = buildComplexConfig()

        var useSecondConfig by mutableIntStateOf(0)

        composeTestRule.setContent {
            // SideEffect is in the same scope that reads `useSecondConfig`,
            // so it fires every time this scope recomposes (which includes
            // when the config reference changes).
            val config = if (useSecondConfig == 0) config1 else config2
            SideEffect { scopeRecompCount.incrementAndGet() }
            NativeDisplayView(config = config)
        }

        composeTestRule.waitForIdle()
        val initialCount = scopeRecompCount.get()

        // Swap to config2
        useSecondConfig = 1
        composeTestRule.waitForIdle()
        val afterSwapCount = scopeRecompCount.get()

        Log.d(TAG, "")
        Log.d(TAG, "========================================")
        Log.d(TAG, " Config Change — SDUI Should Recompose")
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, " Scenario: Config swapped from Simple")
        Log.d(TAG, " to Complex. The hosting scope should")
        Log.d(TAG, " recompose to pass the new config.")
        Log.d(TAG, "========================================")
        Log.d(TAG, "  Before swap    : $initialCount recompositions")
        Log.d(TAG, "  After swap     : $afterSwapCount recompositions")
        Log.d(TAG, "  Delta          : ${afterSwapCount - initialCount}")
        Log.d(TAG, "  Picked up?     : ${if (afterSwapCount > initialCount) "YES — config change detected" else "NO — scope did not recompose!"}")
        Log.d(TAG, "========================================")
    }

    // -------------------------------------------------------------------------
    // Scenario 3: Rapid parent state changes — stress test
    //
    // Simulates a busy screen (animations, timers, frequent state updates).
    // The SDK should remain completely unaffected.
    // -------------------------------------------------------------------------

    @Test
    fun rapidParentUpdates_sduiStaysStable() {
        val parentRecompCount = AtomicInteger(0)
        val sduiRecompCount = AtomicInteger(0)

        val config = buildComplexConfig()
        var animationTick by mutableIntStateOf(0)

        composeTestRule.setContent {
            Column {
                SideEffect { parentRecompCount.incrementAndGet() }
                Text("Tick: $animationTick")

                RecompositionTracker(sduiRecompCount) {
                    NativeDisplayView(config = config)
                }
            }
        }

        composeTestRule.waitForIdle()
        val initialSdui = sduiRecompCount.get()

        // Simulate 20 rapid state changes (like animation frames)
        repeat(20) {
            animationTick++
            composeTestRule.waitForIdle()
        }

        val finalParent = parentRecompCount.get()
        val finalSdui = sduiRecompCount.get()

        Log.d(TAG, "")
        Log.d(TAG, "========================================")
        Log.d(TAG, " Rapid Parent Updates — Stability Test")
        Log.d(TAG, "----------------------------------------")
        Log.d(TAG, " Scenario: 20 rapid parent state changes")
        Log.d(TAG, " (simulating animation/timer). SDK config")
        Log.d(TAG, " is unchanged throughout.")
        Log.d(TAG, "========================================")
        Log.d(TAG, "  Parent recomps : $finalParent total")
        Log.d(TAG, "  SDUI recomps   : $initialSdui -> $finalSdui (delta: ${finalSdui - initialSdui})")
        Log.d(TAG, "  SDUI skipped?  : ${if (finalSdui == initialSdui) "YES — zero unnecessary recompositions" else "NO — SDK recomposed ${finalSdui - initialSdui} times unnecessarily!"}")
        Log.d(TAG, "========================================")
    }

    // -------------------------------------------------------------------------
    // Helper: tracks recompositions of the composable content it wraps
    // -------------------------------------------------------------------------

    @Composable
    private fun RecompositionTracker(
        counter: AtomicInteger,
        content: @Composable () -> Unit,
    ) {
        SideEffect { counter.incrementAndGet() }
        content()
    }

    // -------------------------------------------------------------------------
    // Config builders
    // -------------------------------------------------------------------------

    private fun buildSimpleConfig(): ResolvedConfig {
        val textElement = NativeDisplayElement(
            id = "simple_text",
            elementType = ElementType.TEXT,
            bindings = mapOf("text" to "Hello World"),
            style = Style(fontSize = 16f, textColor = "#000000"),
        )

        val root = NativeDisplayContainer(
            id = "simple_root",
            containerType = ContainerType.VERTICAL,
            children = listOf(textElement),
            layout = Layout(
                width = Dimension(special = SpecialDimension.MATCH_PARENT),
            ),
            style = Style(backgroundColor = "#FFFFFF"),
        )

        return ResolvedConfig(
            theme = Theme(id = "default"),
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = root,
        )
    }

    private fun buildComplexConfig(): ResolvedConfig {
        val textElements = (1..5).map { i ->
            NativeDisplayElement(
                id = "text_$i",
                elementType = ElementType.TEXT,
                bindings = mapOf("text" to "Item $i"),
                style = Style(fontSize = 14f, textColor = "#333333"),
            )
        }

        val innerRow = NativeDisplayContainer(
            id = "inner_row",
            containerType = ContainerType.HORIZONTAL,
            children = textElements.take(2),
            layout = Layout(
                width = Dimension(special = SpecialDimension.MATCH_PARENT),
                arrangement = ChildArrangement(spacing = 8f),
            ),
        )

        val root = NativeDisplayContainer(
            id = "complex_root",
            containerType = ContainerType.VERTICAL,
            children = listOf(innerRow) + textElements.drop(2),
            layout = Layout(
                width = Dimension(special = SpecialDimension.MATCH_PARENT),
                arrangement = ChildArrangement(spacing = 12f),
            ),
            style = Style(backgroundColor = "#FFFFFF"),
        )

        return ResolvedConfig(
            theme = Theme(id = "default"),
            styleClasses = emptyList(),
            variables = emptyMap(),
            root = root,
        )
    }
}
