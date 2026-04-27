package com.clevertap.android.nativedisplay.listener

/**
 * Listener interface for receiving component interaction callbacks.
 * This allows clients to observe or intercept user interactions with components,
 * regardless of whether the server has defined actions for them.
 * 
 * Use cases:
 * - Analytics tracking for all component interactions
 * - Client-side validation before server actions
 * - Easter eggs / hidden features
 * - A/B testing
 */
interface NativeDisplayComponentListener {
    
    /**
     * Return the set of node IDs you want to receive callbacks for.
     * 
     * - Return null: Listen to ALL components (may have performance impact)
     * - Return empty set: Don't listen to any components
     * - Return specific IDs: Only listen to those components (recommended)
     * 
     * Example:
     * ```
     * override fun getInterestedNodeIds(): Set<String>? {
     *     return setOf("product_image", "product_title", "hidden_button")
     * }
     * ```
     */
    fun getInterestedNodeIds(): Set<String>? = null
    
    /**
     * Called when a user interacts with a component you're interested in.
     * This is called BEFORE any server-defined action is executed.
     * 
     * @param nodeId The ID of the component that was interacted with
     * @param interactionType The type of interaction (CLICK, LONG_PRESS, DOUBLE_TAP)
     * @param hasServerAction Whether the server defined an action for this interaction
     * @return true to consume the interaction (prevent server action from executing),
     *         false to allow server action to proceed
     * 
     * Example:
     * ```
     * override fun onComponentInteraction(
     *     nodeId: String,
     *     interactionType: InteractionType,
     *     hasServerAction: Boolean
     * ): Boolean {
     *     // Track all interactions
     *     analytics.track("component_clicked", mapOf("node_id" to nodeId))
     *     
     *     // Intercept specific interactions
     *     if (nodeId == "secret_button" && interactionType == InteractionType.DOUBLE_TAP) {
     *         showEasterEgg()
     *         return true  // Consume, don't execute server action
     *     }
     *     
     *     return false  // Let server action proceed
     * }
     * ```
     */
    fun onComponentInteraction(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Boolean
    ): Boolean
}

/**
 * Types of interactions that can occur on components.
 */
enum class InteractionType {
    /**
     * Single tap/click
     */
    CLICK,
    
    /**
     * Long press and hold
     */
    LONG_PRESS,
    
    /**
     * Double tap
     */
    DOUBLE_TAP
}