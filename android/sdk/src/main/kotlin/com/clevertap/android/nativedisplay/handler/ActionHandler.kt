package com.clevertap.android.nativedisplay.handler

import android.content.Context
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
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
 * @param componentListener Optional component interaction listener
 * @param unitId The CleverTap display unit ID (`wzrk_id`) for attribution events; null when
 *        the config did not come from a Core SDK display unit payload
 * @param pushViewedEvent Test seam invoked when "Notification Viewed" fires. Production
 *        default forwards to [NativeDisplayBridge.pushViewedEvent], which is a no-op when
 *        no CleverTap Core SDK is wired — making the auto-attribution path safe regardless
 *        of whether a client listener is supplied.
 * @param pushClickedEvent Test seam invoked when "Notification Clicked" fires. Production
 *        default forwards to [NativeDisplayBridge.pushClickedEvent], same no-op guarantee.
 */
internal class ActionHandler(
    private val context: Context,
    private val listener: NativeDisplayActionListener?,
    private val componentListener: NativeDisplayComponentListener? = null,
    private val unitId: String? = null,
    private val pushViewedEvent: (String) -> Unit = DEFAULT_PUSH_VIEWED,
    private val pushClickedEvent: (String, Map<String, Any?>?) -> Unit = DEFAULT_PUSH_CLICKED,
) {

    private val coroutineScope = CoroutineScope(Dispatchers.Main + SupervisorJob())
    private val firedSystemEvents = mutableSetOf<String>()

    companion object {
        private const val TAG = "ActionHandler"

        /**
         * Default attribution forwarders — invoke the singleton bridge so that
         * `pushDisplayUnitViewedEventForID` / `pushDisplayUnitClickedEventForID` (or its
         * element-aware successor) fire on the CleverTap Core SDK whenever it is wired,
         * regardless of whether the host app supplied a [NativeDisplayActionListener].
         *
         * When Core SDK is absent the bridge's push methods short-circuit (return false) —
         * the auto-wire path is a graceful no-op.
         *
         * Viewed is unit-level (no extras); Clicked carries action extras when the host's
         * Core SDK exposes the element-aware method, else falls back to unit-level click.
         */
        private val DEFAULT_PUSH_VIEWED: (String) -> Unit = { unitId ->
            NativeDisplayBridge.getInstance()?.pushViewedEvent(unitId)
        }
        private val DEFAULT_PUSH_CLICKED: (String, Map<String, Any?>?) -> Unit = { unitId, extras ->
            NativeDisplayBridge.getInstance()?.pushClickedEvent(unitId, extras)
        }
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
        interactionType: InteractionType = InteractionType.CLICK
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
     * Execute a lifecycle action (onAppear/onDisappear).
     * These bypass the component listener since they are not user interactions.
     *
     * @param action The action to execute
     * @param nodeId The ID of the node that triggered this action
     */
    fun handleLifecycleAction(
        action: Action,
        nodeId: String
    ) {
        coroutineScope.launch {
            try {
                Log.d(TAG, "Handling lifecycle action for node: $nodeId, action: ${action::class.simpleName}")
                when (action) {
                    is Action.OpenUrl -> handleOpenUrl(action, nodeId)
                    is Action.CustomAction -> handleCustomAction(action, nodeId)
                    is Action.Navigate -> handleNavigate(action, nodeId)
                    is Action.TrackEvent -> handleTrackEvent(action, nodeId)
                    is Action.CompositeAction -> handleCompositeAction(action, nodeId)
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error handling lifecycle action for node: $nodeId", e)
                listener?.onActionError(action, e)
            }
        }
    }

    /**
     * Fire a hardcoded system event through the action listener AND the CleverTap
     * Core SDK bridge (when wired).
     *
     * System events are SDK-level events that always fire (not server-driven).
     * Notification Viewed / Notification Clicked are also forwarded to the bridge
     * so attribution flows to Core SDK automatically whenever it is integrated —
     * the client does not have to opt in by attaching a listener.
     *
     * @param eventName The system event name (e.g., "Notification Viewed")
     * @param properties Optional event properties
     * @param deduplicate When true, skips firing if this event name was already fired
     *                    by this handler instance
     */
    fun fireSystemEvent(eventName: String, properties: Map<String, Any?>? = null, deduplicate: Boolean = false) {
        if (deduplicate && !firedSystemEvents.add(eventName)) {
            Log.d(TAG, "System event already fired, skipping: $eventName")
            return
        }
        coroutineScope.launch {
            try {
                Log.d(TAG, "Firing system event: $eventName")
                listener?.onTrackEvent(eventName, properties)
                if (unitId != null) {
                    when (eventName) {
                        "Notification Viewed" -> {
                            listener?.onDisplayUnitViewed(unitId)
                            pushViewedEvent(unitId)
                        }
                        "Notification Clicked" -> {
                            listener?.onDisplayUnitClicked(unitId)
                            pushClickedEvent(unitId, properties)
                        }
                    }
                }
            } catch (e: Exception) {
                Log.e(TAG, "Error firing system event: $eventName", e)
            }
        }
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

    private fun executeDefaultOpenUrl(action: Action.OpenUrl) {
        try {
            if (action.customTabsEnabled) {
                openInCustomTab(action.url)
                return
            }
            openUrl(action.url)
        } catch (_: Exception) {
            Log.d(TAG, "No activity found to open url: ${action.url}")
            listener?.onActionError(action, Exception("No activity found to open url: ${action.url}"))
        }
    }

    // Matches Core SDK InAppActionHandler.openUrl behavior exactly.
    private fun openUrl(url: String) {
        val uri = Uri.parse(url.replace("\n", "").replace("\r", ""))
        val queryBundle = Bundle()
        uri.queryParameterNames?.forEach { name ->
            queryBundle.putString(name, uri.getQueryParameter(name))
        }
        val intent = Intent(Intent.ACTION_VIEW, uri).apply {
            flags = Intent.FLAG_ACTIVITY_NEW_TASK
            if (!queryBundle.isEmpty) putExtras(queryBundle)
        }
        val appPackageName = context.packageName
        context.packageManager.queryIntentActivities(intent, 0).forEach { resolveInfo ->
            if (appPackageName == resolveInfo.activityInfo.packageName) {
                intent.setPackage(appPackageName)
                return@forEach
            }
        }
        context.startActivity(intent)
        Log.d(TAG, "Opened URL: $url")
    }

    private fun openInCustomTab(url: String) {
        openUrl(url)
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