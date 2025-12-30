package com.clevertap.android.nativedisplay.handler

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.util.Log
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.models.ExecutionMode
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.cancel
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.double
import kotlinx.serialization.json.doubleOrNull
import kotlinx.serialization.json.int
import kotlinx.serialization.json.intOrNull
import kotlinx.serialization.json.long
import kotlinx.serialization.json.longOrNull
import androidx.core.net.toUri
import com.clevertap.android.nativedisplay.listener.InteractionType
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener

/**
 * Handles execution of actions triggered by Native Display components.
 * 
 * This class is responsible for:
 * - Routing actions to appropriate handlers
 * - Converting JSON data to usable Kotlin types
 * - Notifying the client listener
 * - Providing default implementations for certain actions (like opening URLs)
 * - Managing coroutine lifecycle for async operations
 * 
 * @param context Android context for starting intents, opening URLs, etc.
 * @param listener Client's callback interface for handling actions
 */
class ActionHandler(
    private val context: Context,
    private val listener: NativeDisplayActionListener?,
    private val componentListener: NativeDisplayComponentListener? = null
) {
    
    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    
    companion object {
        private const val TAG = "ActionHandler"
    }

    /**
     * Execute an action based on its type.
     * This is the main entry point for action execution.
     *
     * @param action The action to execute
     * @param nodeId The ID of the node that triggered this action (for debugging)
     * @param interactionType The type of interaction that triggered this action
     */
    fun handleAction(
        action: Action,
        nodeId: String,
        interactionType: InteractionType = InteractionType.CLICK  // ← ADD THIS PARAMETER
    ) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "Handling action for node: $nodeId, action: ${action::class.simpleName}")

                // Notify component listener first (if interested in this node)
                val shouldProceed = notifyComponentListener(
                    nodeId = nodeId,
                    interactionType = interactionType,
                    hasServerAction = true
                )

                // If component listener consumed the interaction, stop here
                if (!shouldProceed) {
                    Log.d(TAG, "Component listener consumed interaction for node: $nodeId")
                    return@launch
                }

                // Proceed with server action
                when (action) {
                    is Action.OpenUrl -> handleOpenUrl(action, nodeId)
                    is Action.CustomAction -> handleCustomAction(action, nodeId)
                    is Action.Navigate -> handleNavigate(action, nodeId)
                    is Action.TrackEvent -> handleTrackEvent(action, nodeId)
                    is Action.CompositeAction -> handleCompositeAction(action, nodeId)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling action for node: $nodeId", e)
                listener?.onActionError(action, e)
            }
        }
    }

    /**
     * Handle trigger for interactions where no server action is defined.
     * Still notifies component listener if they're interested.
     *
     * @param nodeId The ID of the component
     * @param interactionType The type of interaction
     */
    fun handleInteractionWithoutAction(
        nodeId: String,
        interactionType: InteractionType
    ) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "Handling interaction without action for node: $nodeId")
                notifyComponentListener(
                    nodeId = nodeId,
                    interactionType = interactionType,
                    hasServerAction = false
                )
            } catch (e: Exception) {
                Log.e(TAG, "Error handling interaction for node: $nodeId", e)
            }
        }
    }

    /**
     * Notify component listener about an interaction.
     *
     * @return true if should proceed with server action, false if consumed by listener
     */
    private suspend fun notifyComponentListener(
        nodeId: String,
        interactionType: InteractionType,
        hasServerAction: Boolean
    ): Boolean {
        return withContext(Dispatchers.Main) {
            componentListener?.let { listener ->
                // Check if listener is interested in this node
                val interestedNodeIds = listener.getInterestedNodeIds()
                val isInterested = interestedNodeIds == null || interestedNodeIds.contains(nodeId)

                if (isInterested) {
                    // Call listener and check if it consumed the interaction
                    val consumed = listener.onComponentInteraction(
                        nodeId = nodeId,
                        interactionType = interactionType,
                        hasServerAction = hasServerAction
                    )

                    if (consumed) {
                        Log.d(TAG, "Component listener consumed interaction for: $nodeId")
                        return@withContext false  // Don't proceed with server action
                    }
                }
            }

            return@withContext true  // Proceed with server action
        }
    }
    
    /**
     * Execute multiple actions for a given trigger (e.g., "onClick").
     * 
     * @param actions Map of trigger names to actions
     * @param trigger The trigger name (e.g., "onClick", "onLongPress")
     * @param nodeId The ID of the node that triggered this action
     */
    fun handleTrigger(
        actions: Map<String, Action>?,
        trigger: String,
        nodeId: String
    ) {
        val action = actions?.get(trigger) ?: return
        handleAction(action, nodeId)
    }
    
    /**
     * Handle OPEN_URL action.
     * First checks if client wants to handle it, then uses default behavior.
     */
    private suspend fun handleOpenUrl(action: Action.OpenUrl, nodeId: String) {
        withContext(Dispatchers.Main) {
            Log.d(TAG, "Opening URL: ${action.url} (openInBrowser: ${action.openInBrowser})")
            
            // Ask listener if they want to handle it
            val handled = listener?.onOpenUrl(
                action.url,
                action.openInBrowser
            ) ?: false
            
            // If listener didn't handle it, use default behavior
            if (!handled) {
                executeDefaultOpenUrl(action)
            }
        }
    }
    
    /**
     * Default implementation for opening URLs.
     * Tries Chrome Custom Tabs first, falls back to browser.
     */
    private fun executeDefaultOpenUrl(action: Action.OpenUrl) {
        try {
            val uri = Uri.parse(action.url)
            
            // Validate URL scheme (prevent javascript: etc.)
            if (!isValidUrlScheme(uri.scheme)) {
                Log.w(TAG, "Invalid URL scheme: ${uri.scheme}")
                return
            }
            
            when {
                // Open in external browser
                action.openInBrowser -> {
                    openInExternalBrowser(action.url)
                }
                // Open in Chrome Custom Tab
                action.customTabsEnabled -> {
                    openInCustomTab(action.url)
                }
                // Fallback to external browser
                else -> {
                    openInExternalBrowser(action.url)
                }
            }
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open URL: ${action.url}", e)
            listener?.onActionError(action, e)
        }
    }
    
    /**
     * Open URL in external browser app.
     */
    private fun openInExternalBrowser(url: String) {
        try {
            val intent = Intent(Intent.ACTION_VIEW, url.toUri()).apply {
                flags = Intent.FLAG_ACTIVITY_NEW_TASK
            }
            context.startActivity(intent)
            Log.d(TAG, "Opened URL in external browser: $url")
        } catch (e: Exception) {
            Log.e(TAG, "Failed to open external browser", e)
            throw e
        }
    }
    
    /**
     * Open URL in Chrome Custom Tab.
     * Provides in-app browser experience with better UX.
     */
    private fun openInCustomTab(url: String) {
        /*try {
            val builder = CustomTabsIntent.Builder()
            val customTabsIntent = builder.build()
            
            // Use FLAG_ACTIVITY_NEW_TASK since we might not have activity context
            customTabsIntent.intent.flags = Intent.FLAG_ACTIVITY_NEW_TASK
            
            customTabsIntent.launchUrl(context, Uri.parse(url))
            Log.d(TAG, "Opened URL in Chrome Custom Tab: $url")
        } catch (e: Exception) {
            Log.w(TAG, "Chrome Custom Tab failed, falling back to browser", e)
            // Fallback to external browser
            openInExternalBrowser(url)
        }*/
    }
    
    /**
     * Validate URL scheme for security.
     * Only allow http, https, and other safe schemes.
     */
    private fun isValidUrlScheme(scheme: String?): Boolean {
        return when (scheme?.lowercase()) {
            "http", "https", "tel", "mailto" -> true
            else -> false
        }
    }
    
    /**
     * Handle CUSTOM action.
     * Converts JSON value to Kotlin types and notifies listener.
     */
    private suspend fun handleCustomAction(action: Action.CustomAction, nodeId: String) {
        withContext(Dispatchers.Main) {
            Log.d(TAG, "Executing custom action: ${action.key}")
            
            val parsedValue = parseJsonValue(action.value)
            
            listener?.onCustomAction(
                key = action.key,
                value = parsedValue,
                metadata = action.metadata
            )
        }
    }
    
    /**
     * Handle NAVIGATE action.
     * Notifies listener to perform navigation.
     */
    private suspend fun handleNavigate(action: Action.Navigate, nodeId: String) {
        withContext(Dispatchers.Main) {
            Log.d(TAG, "Navigating to: ${action.destination}")
            
            listener?.onNavigate(
                destination = action.destination,
                params = action.params
            )
        }
    }
    
    /**
     * Handle TRACK_EVENT action.
     * Converts JSON properties to Kotlin types and notifies listener.
     */
    private suspend fun handleTrackEvent(action: Action.TrackEvent, nodeId: String) {
        withContext(Dispatchers.Main) {
            Log.d(TAG, "Tracking event: ${action.eventName}")
            
            val parsedProperties = action.properties?.mapValues { (_, value) ->
                parseJsonValue(value)
            }
            
            listener?.onTrackEvent(
                eventName = action.eventName,
                properties = parsedProperties
            )
        }
    }
    
    /**
     * Handle COMPOSITE action.
     * Executes multiple actions either sequentially or in parallel.
     */
    private suspend fun handleCompositeAction(action: Action.CompositeAction, nodeId: String) {
        Log.d(TAG, "Executing composite action with ${action.actions.size} sub-actions (${action.executionMode})")
        
        when (action.executionMode) {
            ExecutionMode.SEQUENTIAL -> {
                // Execute one after another
                action.actions.forEach { subAction ->
                    handleAction(subAction, "$nodeId-composite")
                }
            }
            ExecutionMode.PARALLEL -> {
                // Execute all at once
                action.actions.map { subAction ->
                    coroutineScope.async {
                        handleAction(subAction, "$nodeId-composite")
                    }
                }.awaitAll()
            }
        }
    }
    
    /**
     * Convert JsonElement to usable Kotlin types.
     * 
     * Conversions:
     * - JsonPrimitive (string) → String
     * - JsonPrimitive (number) → Int/Long/Double
     * - JsonPrimitive (boolean) → Boolean
     * - JsonObject → Map<String, Any?>
     * - JsonArray → List<Any?>
     * 
     * @param element The JSON element to parse
     * @return Parsed Kotlin value (String, Number, Boolean, Map, List, or null)
     */
    private fun parseJsonValue(element: JsonElement): Any? {
        return when (element) {
            is JsonPrimitive -> {
                when {
                    element.isString -> element.content
                    element.booleanOrNull != null -> element.boolean
                    element.intOrNull != null -> element.int
                    element.longOrNull != null -> element.long
                    element.doubleOrNull != null -> element.double
                    else -> element.content
                }
            }
            is JsonObject -> element.toMap()
            is JsonArray -> element.toList()
            else -> null
        }
    }
    
    /**
     * Convert JsonObject to Map<String, Any?>
     */
    private fun JsonObject.toMap(): Map<String, Any?> {
        return this.mapValues { (_, value) ->
            parseJsonValue(value)
        }
    }
    
    /**
     * Convert JsonArray to List<Any?>
     */
    private fun JsonArray.toList(): List<Any?> {
        return this.map { element ->
            parseJsonValue(element)
        }
    }
    
    /**
     * Clean up resources when ActionHandler is no longer needed.
     * Call this when the composable is disposed.
     */
    fun cleanup() {
        Log.d(TAG, "Cleaning up ActionHandler")
        coroutineScope.cancel()
    }
}