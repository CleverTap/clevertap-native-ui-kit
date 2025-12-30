package com.clevertap.android.nativedisplay.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import kotlinx.serialization.json.JsonElement

/**
 * Represents different types of actions that can be triggered by user interactions
 * in the Native Display System.
 */
@Serializable
sealed class Action {
    
    /**
     * Opens a URL in browser or custom tab.
     * 
     * @property url The URL to open
     * @property openInBrowser If true, opens in external browser. If false, uses Chrome Custom Tab
     * @property customTabsEnabled If true and openInBrowser is false, uses Chrome Custom Tabs
     */
    @Serializable
    @SerialName("open_url")
    data class OpenUrl(
        val url: String,
        val openInBrowser: Boolean = false,
        val customTabsEnabled: Boolean = true
    ) : Action()
    
    /**
     * Executes a custom action defined by the client application.
     * The key identifies the action type, and value contains the action data.
     * 
     * @property key Identifier for the custom action (e.g., "add_to_cart", "share")
     * @property value The data associated with this action (can be any JSON type)
     * @property metadata Optional additional metadata for the action
     */
    @Serializable
    @SerialName("custom")
    data class CustomAction(
        val key: String,
        val value: JsonElement,
        val metadata: Map<String, String>? = null
    ) : Action()
    
    /**
     * Navigates to a different screen/destination in the app.
     * 
     * @property destination The navigation destination identifier
     * @property params Optional navigation parameters
     */
    @Serializable
    @SerialName("navigate")
    data class Navigate(
        val destination: String,
        val params: Map<String, String>? = null
    ) : Action()
    
    /**
     * Tracks an analytics event.
     * 
     * @property eventName The name of the event to track
     * @property properties Optional event properties
     */
    @Serializable
    @SerialName("event")
    data class TrackEvent(
        val eventName: String,
        val properties: Map<String, JsonElement>? = null
    ) : Action()
    
    /**
     * Executes multiple actions either sequentially or in parallel.
     * 
     * @property actions List of actions to execute
     * @property executionMode Whether to execute actions sequentially or in parallel
     */
    @Serializable
    @SerialName("composite")
    data class CompositeAction(
        val actions: List<Action>,
        val executionMode: ExecutionMode = ExecutionMode.SEQUENTIAL
    ) : Action()
}

/**
 * Defines how multiple actions in a CompositeAction should be executed.
 */
@Serializable
enum class ExecutionMode {
    /**
     * Execute actions one after another, waiting for each to complete
     */
    @SerialName("sequential")
    SEQUENTIAL,
    
    /**
     * Execute all actions simultaneously
     */
    @SerialName("parallel")
    PARALLEL
}