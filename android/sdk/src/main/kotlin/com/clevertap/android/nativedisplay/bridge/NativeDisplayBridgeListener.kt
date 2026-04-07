package com.clevertap.android.nativedisplay.bridge

/**
 * Listener for Native Display units delivered through the bridge.
 *
 * Implement this to receive notifications when new display units are
 * available — either from CleverTap Core SDK (auto-wire mode) or from
 * manual JSON input.
 */
interface NativeDisplayBridgeListener {

    /**
     * Called when new Native Display units have been loaded and parsed.
     *
     * @param units The list of successfully parsed display units
     */
    fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>)
}
