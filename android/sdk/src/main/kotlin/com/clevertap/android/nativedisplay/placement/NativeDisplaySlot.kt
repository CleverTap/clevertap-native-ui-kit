package com.clevertap.android.nativedisplay.placement

import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

/**
 * Compose composable that renders a Native Display unit for a given slot.
 *
 * Automatically registers with [NativeDisplaySlotManager] to receive display units
 * that match the provided [slotId]. When a unit becomes available, it is rendered
 * using [NativeDisplayView]. While waiting for a unit, the [loading] composable
 * is displayed.
 *
 * **Usage:**
 * ```kotlin
 * NativeDisplaySlot(
 *     slotId = "hero_banner",
 *     modifier = Modifier.fillMaxWidth(),
 *     actionListener = myActionListener,
 *     loading = { CircularProgressIndicator() }
 * )
 * ```
 *
 * @param slotId The slot identifier to observe for display units
 * @param modifier Modifier applied to the rendered content
 * @param actionListener Optional listener for user actions within the rendered content
 * @param componentListener Optional listener for component lifecycle events
 * @param loading Composable displayed while no unit is available for the slot
 */
@Composable
fun NativeDisplaySlot(
    slotId: String,
    modifier: Modifier = Modifier,
    actionListener: NativeDisplayActionListener? = null,
    componentListener: NativeDisplayComponentListener? = null,
    loading: @Composable () -> Unit = {},
) {
    var unit by remember { mutableStateOf<NativeDisplayUnit?>(null) }

    DisposableEffect(slotId) {
        val observer = object : SlotObserver {
            override fun onUnitAvailable(availableUnit: NativeDisplayUnit) {
                unit = availableUnit
            }

            override fun onUnitCleared(clearedSlotId: String) {
                unit = null
            }
        }

        val manager = NativeDisplaySlotManager.getInstance()
        manager.registerSlot(slotId, observer)

        onDispose {
            manager.unregisterSlot(slotId, observer)
        }
    }

    val currentUnit = unit
    if (currentUnit != null) {
        NativeDisplayView(
            config = currentUnit.config,
            modifier = modifier,
            actionListener = actionListener,
<<<<<<< HEAD
            componentListener = componentListener,
            unitId = currentUnit.unitId
=======
            componentListener = componentListener
>>>>>>> origin/task/SDK-5399_ios
        )
    } else {
        loading()
    }
}
