package com.clevertap.android.nativeui.sample

import androidx.lifecycle.ViewModel
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow

/**
 * ViewModel for BridgeIntegrationScreen.
 *
 * Holds the [bridge] instance and all mutable screen state in StateFlows so they
 * survive Activity recreation on configuration changes (e.g. rotation).
 *
 * The bridge itself is created here (not in a composable `remember`) so it is
 * retained across recompositions and configuration changes. [onCleared] clears it
 * when the ViewModel is permanently destroyed.
 */
class BridgeIntegrationViewModel : ViewModel() {

    /** Bridge held in the ViewModel so it is not recreated on rotation. */
    val bridge: NativeDisplayBridge = NativeDisplayBridge.create()

    private val _receivedUnits = MutableStateFlow<List<NativeDisplayUnit>>(emptyList())
    val receivedUnits: StateFlow<List<NativeDisplayUnit>> = _receivedUnits.asStateFlow()

    private val _logMessages = MutableStateFlow<List<String>>(emptyList())
    val logMessages: StateFlow<List<String>> = _logMessages.asStateFlow()

    private val _listenerRegistered = MutableStateFlow(false)
    val listenerRegistered: StateFlow<Boolean> = _listenerRegistered.asStateFlow()

    private val _dataProcessed = MutableStateFlow(false)
    val dataProcessed: StateFlow<Boolean> = _dataProcessed.asStateFlow()

    fun onUnitsLoaded(units: List<NativeDisplayUnit>) {
        _receivedUnits.value = units
    }

    fun log(message: String) {
        _logMessages.value = _logMessages.value + message
    }

    fun markListenerRegistered() {
        _listenerRegistered.value = true
    }

    fun markDataProcessed() {
        _dataProcessed.value = true
    }

    override fun onCleared() {
        super.onCleared()
        bridge.clear()
    }
}
