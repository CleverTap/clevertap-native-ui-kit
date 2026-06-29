package com.clevertap.android.nativeui.sample.xmlfeed

import androidx.lifecycle.ViewModel
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

class XmlFeedViewModel : ViewModel() {

    private val _receivedUnits = MutableStateFlow<List<NativeDisplayUnit>>(emptyList())
    val receivedUnits: StateFlow<List<NativeDisplayUnit>> = _receivedUnits.asStateFlow()

    private val _logEntries = MutableStateFlow<List<String>>(emptyList())
    val logEntries: StateFlow<List<String>> = _logEntries.asStateFlow()

    private val timeFormat = SimpleDateFormat("HH:mm:ss", Locale.US)

    fun setUnits(units: List<NativeDisplayUnit>) {
        _receivedUnits.value = units
    }

    fun log(message: String) {
        val timestamp = timeFormat.format(Date())
        val entry = "[$timestamp] $message"
        _logEntries.value = _logEntries.value + entry
    }

    fun clearLog() {
        _logEntries.value = emptyList()
    }
}
