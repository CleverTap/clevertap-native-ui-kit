package com.clevertap.android.nativedisplay.models

/**
 * Constants for action trigger names used in the Native Display System.
 * These define when actions should be executed.
 */
object ActionTriggers {
    /**
     * Triggered when a component is clicked/tapped
     */
    const val ON_CLICK = "onClick"
    
    /**
     * Triggered when a component is long-pressed
     */
    const val ON_LONG_PRESS = "onLongPress"
    
    /**
     * Triggered when a component is double-tapped
     */
    const val ON_DOUBLE_TAP = "onDoubleTap"
    
    /**
     * Triggered when a component appears on screen
     */
    const val ON_APPEAR = "onAppear"
    
    /**
     * Triggered when a component disappears from screen
     */
    const val ON_DISAPPEAR = "onDisappear"
}