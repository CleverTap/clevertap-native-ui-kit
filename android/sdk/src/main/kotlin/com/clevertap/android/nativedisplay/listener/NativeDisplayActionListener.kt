package com.clevertap.android.nativedisplay.listener

import com.clevertap.android.nativedisplay.models.Action

/**
 * Interface for handling actions triggered by Native Display components.
 * Client applications implement this to respond to user interactions.
 */
interface NativeDisplayActionListener {
    
    /**
     * Called when an OPEN_URL action is triggered.
     * 
     * @param url The URL to open
     * @param openInBrowser Whether to open in external browser
     * @return true if the client handled the action, false to use default behavior
     */
    fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean = false
    
    /**
     * Called when a CUSTOM action is triggered.
     * This is the most flexible action type - the client defines what happens.
     * 
     * @param key The action identifier (e.g., "add_to_cart", "share", "like")
     * @param value The action data (can be String, Number, Boolean, Map, List, or null)
     * @param metadata Optional additional metadata about the action
     * 
     * Example:
     * ```
     * override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
     *     when (key) {
     *         "add_to_cart" -> {
     *             val data = value as? Map<String, Any?>
     *             val productId = data?.get("productId") as? String
     *             cartManager.addItem(productId)
     *         }
     *     }
     * }
     * ```
     */
    fun onCustomAction(
        key: String,
        value: Any?,
        metadata: Map<String, String>?
    )
    
    /**
     * Called when a NAVIGATE action is triggered.
     * 
     * @param destination The navigation destination identifier
     * @param params Optional navigation parameters
     * 
     * Example:
     * ```
     * override fun onNavigate(destination: String, params: Map<String, String>?) {
     *     navController.navigate(destination) {
     *         params?.forEach { (key, value) ->
     *             putString(key, value)
     *         }
     *     }
     * }
     * ```
     */
    fun onNavigate(
        destination: String,
        params: Map<String, String>?
    )
    
    /**
     * Called when an EVENT action is triggered.
     * Used for analytics tracking.
     * 
     * @param eventName The name of the event to track
     * @param properties Optional event properties
     * 
     * Example:
     * ```
     * override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
     *     firebaseAnalytics.logEvent(eventName) {
     *         properties?.forEach { (key, value) ->
     *             param(key, value.toString())
     *         }
     *     }
     * }
     * ```
     */
    fun onTrackEvent(
        eventName: String,
        properties: Map<String, Any?>?
    )
    
    /**
     * Called when any action execution fails.
     * Override this to handle errors gracefully.
     *
     * @param action The action that failed
     * @param error The error that occurred
     */
    fun onActionError(action: Action, error: Throwable) {
        // Default: do nothing (client can override to log or show error)
    }

    /**
     * Called when a Native Display unit has been viewed (impression).
     *
     * **Do NOT call `pushDisplayUnitViewedEventForID` here** — the SDK already fires
     * the attribution event automatically. This callback is a notification only,
     * intended for custom analytics or UI updates (e.g. logging, badge counters).
     *
     * Default implementation is a no-op — existing implementors do not need to override.
     *
     * @param unitId The ID of the display unit that was viewed
     */
    fun onDisplayUnitViewed(unitId: String) {}

    /**
     * Called when a Native Display unit has been clicked.
     *
     * **Do NOT call `pushDisplayUnitClickedEventForID` here** — the SDK already fires
     * the attribution event automatically. This callback is a notification only,
     * intended for custom analytics or UI updates (e.g. logging, dismiss logic).
     *
     * Default implementation is a no-op — existing implementors do not need to override.
     *
     * @param unitId The ID of the display unit that was clicked
     */
    fun onDisplayUnitClicked(unitId: String) {}
}