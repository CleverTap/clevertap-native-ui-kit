package com.clevertap.android.nativeui.sample

import androidx.lifecycle.ViewModel
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.update
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

/**
 * ViewModel for CleverTapIntegrationScreen.
 *
 * Holds [receivedUnits] and [logMessages] in StateFlows so they survive
 * Activity recreation on configuration changes (e.g. rotation).
 */
class CleverTapIntegrationViewModel : ViewModel() {

    private val _receivedUnits = MutableStateFlow<List<NativeDisplayUnit>>(emptyList())
    val receivedUnits: StateFlow<List<NativeDisplayUnit>> = _receivedUnits.asStateFlow()

    /**
     * Monotonically increasing count of display-unit batches delivered to the
     * canvas. Incremented every time [onUnitsLoaded] fires (i.e. each server
     * response that reaches the bridge listener).
     *
     * The screenshot automation reads this through a zero-size semantics node
     * ("ct-units-count") to detect when a *new* batch has arrived after firing
     * an event, instead of relying on a fixed sleep. This makes each capture
     * deterministic: the screenshot reflects the response to the event just
     * fired, not a stale previous one.
     */
    private val _batchCount = MutableStateFlow(0)
    val batchCount: StateFlow<Int> = _batchCount.asStateFlow()

    private val _logMessages = MutableStateFlow<List<String>>(emptyList())
    val logMessages: StateFlow<List<String>> = _logMessages.asStateFlow()

    private val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.US)

    fun onUnitsLoaded(units: List<NativeDisplayUnit>) {
        _receivedUnits.value = units
        // Bump the batch counter at the exact point the canvas state updates, so
        // the test's handshake observes the increment only once the new units
        // are actually in the tree.
        _batchCount.update { it + 1 }
    }

    /**
     * Clears the canvas back to its empty/"Waiting" state. Called when an event
     * is fired so the canvas does not keep showing the previous event's campaign
     * while the new server response is in flight. Does not touch [batchCount] —
     * the next real batch is what advances it and unblocks the test handshake.
     */
    fun clearUnits() {
        _receivedUnits.value = emptyList()
    }

    fun log(message: String) {
        val timestamp = timeFormat.format(Date())
        val entry = "[$timestamp] $message"
        _logMessages.update { it + entry }
    }

    fun clearLog() {
        _logMessages.value = emptyList()
    }
}
