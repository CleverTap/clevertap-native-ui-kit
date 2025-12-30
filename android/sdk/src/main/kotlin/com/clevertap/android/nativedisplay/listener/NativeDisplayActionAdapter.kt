package com.clevertap.android.nativedisplay.listener

/**
 * Adapter class that provides empty implementations of NativeDisplayActionListener.
 * Clients can extend this and override only the methods they need.
 * 
 * Example:
 * ```
 * val listener = object : NativeDisplayActionAdapter() {
 *     override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
 *         // Only handle custom actions, ignore others
 *         when (key) {
 *             "add_to_cart" -> handleAddToCart(value)
 *         }
 *     }
 * }
 * ```
 */
abstract class NativeDisplayActionAdapter : NativeDisplayActionListener {
    
    override fun onCustomAction(
        key: String,
        value: Any?,
        metadata: Map<String, String>?
    ) {
        // No-op by default
    }
    
    override fun onNavigate(
        destination: String,
        params: Map<String, String>?
    ) {
        // No-op by default
    }
    
    override fun onTrackEvent(
        eventName: String,
        properties: Map<String, Any?>?
    ) {
        // No-op by default
    }
}