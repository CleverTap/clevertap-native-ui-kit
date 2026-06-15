package com.clevertap.android.nativedisplay.placement

import android.content.Context
import android.util.AttributeSet
import android.widget.FrameLayout
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import com.clevertap.android.nativedisplay.internal.NDLogger
import com.clevertap.android.nativeui.R
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.persistentMapOf

/**
 * Traditional Android View wrapper for slot-based Native Display content.
 *
 * This view wraps a [ComposeView] inside a [FrameLayout] and automatically
 * registers with [NativeDisplaySlotManager] to receive display units for
 * the configured slot.
 *
 * **Usage in XML:**
 * ```xml
 * <com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView
 *     android:id="@+id/slot_hero"
 *     android:layout_width="match_parent"
 *     android:layout_height="wrap_content"
 *     app:slotId="hero_banner" />
 * ```
 *
 * **Usage in code:**
 * ```kotlin
 * val slotView = NativeDisplaySlotView(context)
 * slotView.setSlotId("hero_banner")
 * slotView.setActionListener(myActionListener)
 * ```
 */
class NativeDisplaySlotView @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr), SlotObserver {

    companion object {
        private const val TAG = "NDSlotView"
    }

    // The actual ComposeView (wrapped, not inherited)
    private val composeView: ComposeView

    // Configuration state
    private var unitState = mutableStateOf<NativeDisplayUnit?>(null)
    private var actionListenerState = mutableStateOf<NativeDisplayActionListener?>(null)
    private var componentListenerState = mutableStateOf<NativeDisplayComponentListener?>(null)
    private var resolvedStylesState = mutableStateOf<PersistentMap<String, Style>>(persistentMapOf())

    // Slot state
    private var slotId: String? = null
    private var isRegistered = false

    init {
        // Read slotId from XML attributes if provided
        if (attrs != null) {
            val typedArray = context.obtainStyledAttributes(attrs, R.styleable.NativeDisplaySlotView)
            try {
                slotId = typedArray.getString(R.styleable.NativeDisplaySlotView_slotId)
            } finally {
                typedArray.recycle()
            }
        }

        // Create and configure the ComposeView
        composeView = ComposeView(context).apply {
            setViewCompositionStrategy(
                ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
            )

            setContent {
                val unit by remember { unitState }
                val actionListener by remember { actionListenerState }
                val componentListener by remember { componentListenerState }
                val resolvedStyles by remember { resolvedStylesState }

                unit?.let { currentUnit ->
                    MaterialTheme {
                        NativeDisplayView(
                            config = currentUnit.config,
                            resolvedStyles = resolvedStyles,
                            modifier = Modifier,
                            actionListener = actionListener,
                            componentListener = componentListener,
                            unitId = currentUnit.unitId,
                        )
                    }
                }
            }
        }

        // Add ComposeView to this FrameLayout
        addView(
            composeView,
            LayoutParams(
                LayoutParams.MATCH_PARENT,
                LayoutParams.WRAP_CONTENT
            )
        )
    }

    /**
     * Set the slot identifier for this view.
     *
     * If the view is already attached to the window, the previous slot registration
     * is removed and a new one is created for the new slot ID.
     *
     * @param id The slot identifier to observe
     */
    fun setSlotId(id: String) {
        if (slotId == id) return

        // Unregister from previous slot if attached
        if (isRegistered) {
            slotId?.let { oldId ->
                NativeDisplaySlotManager.getInstance().unregisterSlot(oldId, this)
            }
        }

        slotId = id

        // Register with new slot if attached
        if (isRegistered) {
            NativeDisplaySlotManager.getInstance().registerSlot(id, this)
        }
    }

    /**
     * Set the action listener for user interactions within the rendered content.
     *
     * @param listener The action listener, or null to clear
     */
    fun setActionListener(listener: NativeDisplayActionListener?) {
        actionListenerState.value = listener
    }

    /**
     * Set the component listener for component lifecycle events.
     *
     * @param listener The component listener, or null to clear
     */
    fun setComponentListener(listener: NativeDisplayComponentListener?) {
        componentListenerState.value = listener
    }

    // --- SlotObserver ---

    override fun onUnitAvailable(unit: NativeDisplayUnit) {
        NDLogger.d(TAG, "Unit available for slot: $slotId (unitId=${unit.unitId})")

        // Styles were pre-resolved off-main inside the bridge parser — just consume them.
        resolvedStylesState.value = unit.resolvedStyles
        unitState.value = unit
        requestLayout()
    }

    override fun onUnitCleared(slotId: String) {
        NDLogger.d(TAG, "Unit cleared for slot: $slotId")
        unitState.value = null
        resolvedStylesState.value = persistentMapOf()
    }

    // --- Lifecycle ---

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        slotId?.let { id ->
            if (!isRegistered) {
                NativeDisplaySlotManager.getInstance().registerSlot(id, this)
                isRegistered = true
                NDLogger.d(TAG, "Registered with slot manager: $id")
            }
        }
    }

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
        slotId?.let { id ->
            if (isRegistered) {
                NativeDisplaySlotManager.getInstance().unregisterSlot(id, this)
                isRegistered = false
                NDLogger.d(TAG, "Unregistered from slot manager: $id")
            }
        }
        // Clear state
        unitState.value = null
        actionListenerState.value = null
        componentListenerState.value = null
        resolvedStylesState.value = persistentMapOf()
    }

    // --- Measurement ---

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        composeView.measure(widthMeasureSpec, heightMeasureSpec)

        val width = composeView.measuredWidth
        var height = composeView.measuredHeight

        if (height == 0 && MeasureSpec.getMode(heightMeasureSpec) == MeasureSpec.AT_MOST) {
            height = (48 * context.resources.displayMetrics.density).toInt() // 48dp minimum
        }

        setMeasuredDimension(width, height)
    }
}
