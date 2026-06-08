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

    private val _logMessages = MutableStateFlow<List<String>>(emptyList())
    val logMessages: StateFlow<List<String>> = _logMessages.asStateFlow()

    private val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.US)

    fun onUnitsLoaded(units: List<NativeDisplayUnit>) {
        _receivedUnits.value = units
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
