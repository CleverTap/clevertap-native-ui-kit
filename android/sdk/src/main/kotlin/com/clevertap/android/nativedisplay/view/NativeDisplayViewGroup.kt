package com.clevertap.android.nativedisplay.view

import android.content.Context
import android.os.Parcel
import android.os.Parcelable
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.FrameLayout
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.findViewTreeLifecycleOwner
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.models.Style
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.nativedisplay.style.StyleResolver
import kotlinx.collections.immutable.PersistentMap
import kotlinx.collections.immutable.persistentMapOf
import kotlin.math.abs

/**
 * Traditional Android View wrapper for Native Display SDUI content.
 *
 * This view wraps a ComposeView inside a FrameLayout, providing a clean
 * integration point for XML layouts and RecyclerView.
 *
 * **Why FrameLayout?**
 * - ComposeView is final and cannot be extended
 * - AbstractComposeView has final methods that cannot be overridden
 * - FrameLayout is flexible and allows us to intercept touch events
 *
 * **Usage in XML:**
 * ```xml
 * <com.clevertap.android.nativedisplay.view.NativeDisplayViewGroup
 *     android:id="@+id/sdui_view"
 *     android:layout_width="match_parent"
 *     android:layout_height="wrap_content" />
 * ```
 *
 * **Usage in code:**
 * ```kotlin
 * val sduiView = NativeDisplayViewGroup(context)
 * sduiView.setConfig(config, actionListener)
 * ```
 *
 * **Usage in RecyclerView:**
 * ```kotlin
 * class SDUIViewHolder(parent: ViewGroup) : RecyclerView.ViewHolder(
 *     NativeDisplayViewGroup(parent.context)
 * ) {
 *     private val sduiView = itemView as NativeDisplayViewGroup
 *
 *     fun bind(config: ResolvedConfig) {
 *         sduiView.setConfig(config)
 *     }
 *
 *     fun onRecycled() {
 *         sduiView.onRecycled()
 *     }
 *
 *     fun onAttached() {
 *         sduiView.onAttached()
 *     }
 * }
 * ```
 */
class NativeDisplayViewGroup @JvmOverloads constructor(
    context: Context,
    attrs: AttributeSet? = null,
    defStyleAttr: Int = 0
) : FrameLayout(context, attrs, defStyleAttr) {

    // The actual ComposeView (wrapped, not inherited)
    private val composeView: ComposeView

    // Configuration state
    private var configState = mutableStateOf<ResolvedConfig?>(null)
    private var actionListenerState = mutableStateOf<NativeDisplayActionListener?>(null)
    private var componentListenerState = mutableStateOf<NativeDisplayComponentListener?>(null)
    private var resolvedStylesState = mutableStateOf<PersistentMap<String, Style>>(persistentMapOf())
    private var unitIdState = mutableStateOf<String?>(null)

    // State tracking
    private var isRecycled = false

    // Touch handling for nested scroll
    private var initialX = 0f
    private var initialY = 0f
    private var activePointerId = -1
    private val touchSlop = ViewConfiguration.get(context).scaledTouchSlop
    private var scrollState = ScrollState.IDLE

    // Lifecycle management
    private var lifecycleObserver: DefaultLifecycleObserver? = null

    private enum class ScrollState {
        IDLE,
        HORIZONTAL,
        VERTICAL
    }

    init {
        // Enable nested scrolling for RecyclerView compatibility
        isNestedScrollingEnabled = true

        // Create and configure the ComposeView
        composeView = ComposeView(context).apply {
            // Set composition strategy for proper lifecycle
            setViewCompositionStrategy(
                ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
            )

            // Set up the Compose content
            setContent {
                val config by remember { configState }
                val actionListener by remember { actionListenerState }
                val componentListener by remember { componentListenerState }
                val resolvedStyles by remember { resolvedStylesState }
                val unitId by remember { unitIdState }

                config?.let { resolvedConfig ->
                    MaterialTheme {
                        NativeDisplayView(
                            config = resolvedConfig,
                            resolvedStyles = resolvedStyles,
                            modifier = Modifier,
                            actionListener = actionListener,
                            componentListener = componentListener,
                            unitId = unitId
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

        // Observe lifecycle for proper cleanup
        setupLifecycleObserver()
    }

    private fun setupLifecycleObserver() {
        post {
            findViewTreeLifecycleOwner()?.let { lifecycleOwner ->
                val observer = object : DefaultLifecycleObserver {
                    override fun onDestroy(owner: LifecycleOwner) {
                        // Final cleanup
                        configState.value = null
                        actionListenerState.value = null
                        componentListenerState.value = null
                        lifecycleObserver = null
                    }
                }

                lifecycleOwner.lifecycle.addObserver(observer)
                lifecycleObserver = observer
            }
        }
    }

    /**
     * Set the SDUI configuration to display.
     *
     * This method updates the Compose state, triggering a recomposition.
     *
     * @param config The resolved SDUI configuration
     * @param actionListener Optional listener for user actions
     * @param componentListener Optional listener for component lifecycle events
     */
    @JvmOverloads
    fun setConfig(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = null,
        componentListener: NativeDisplayComponentListener? = null,
        unitId: String? = null
    ) {
        // Direct-ResolvedConfig path: caller has no NativeDisplayUnit, so styles
        // were not pre-resolved by the bridge. Resolve them here. This is the
        // fallback for clients who construct configs locally (e.g. previews,
        // tests, RecyclerView binders that build configs in-process). The
        // bridge-driven path goes through [setUnit], which skips this work.
        val resolver = StyleResolver(config.theme, config.styleClasses)
        applyState(
            config = config,
            resolvedStyles = resolver.resolveAll(config.root),
            actionListener = actionListener,
            componentListener = componentListener,
            unitId = unitId
        )
    }

    /**
     * Set the SDUI configuration to display from a parsed [NativeDisplayUnit].
     *
     * Consumes the unit's pre-resolved style map directly, avoiding any
     * style-cascade work on the calling thread. Prefer this overload whenever
     * the source of truth is a [NativeDisplayUnit] from the bridge.
     */
    @JvmOverloads
    fun setUnit(
        unit: NativeDisplayUnit,
        actionListener: NativeDisplayActionListener? = null,
        componentListener: NativeDisplayComponentListener? = null,
    ) {
        applyState(
            config = unit.config,
            resolvedStyles = unit.resolvedStyles,
            actionListener = actionListener,
            componentListener = componentListener,
            unitId = unit.unitId
        )
    }

    private fun applyState(
        config: ResolvedConfig,
        resolvedStyles: PersistentMap<String, Style>,
        actionListener: NativeDisplayActionListener?,
        componentListener: NativeDisplayComponentListener?,
        unitId: String?
    ) {
        isRecycled = false
        resolvedStylesState.value = resolvedStyles
        configState.value = config
        actionListenerState.value = actionListener
        componentListenerState.value = componentListener
        unitIdState.value = unitId
        requestLayout()
    }

    /**
     * Clear the current configuration and remove all content.
     */
    fun clearConfig() {
        configState.value = null
        actionListenerState.value = null
        componentListenerState.value = null
        resolvedStylesState.value = persistentMapOf()
        unitIdState.value = null
    }

    /**
     * Call this when RecyclerView recycles the view.
     * Prepares the view for reuse and prevents memory leaks.
     */
    fun onRecycled() {
        isRecycled = true
        actionListenerState.value = null
        componentListenerState.value = null
        configState.value = null
        resolvedStylesState.value = persistentMapOf()
        unitIdState.value = null
    }

    /**
     * Call this when RecyclerView attaches the view to the window.
     * Prepares the view for display.
     */
    fun onAttached() {
        isRecycled = false
    }

    // MARK: - Touch Handling for Nested Scroll

    override fun onInterceptTouchEvent(ev: MotionEvent): Boolean {
        when (ev.actionMasked) {
            MotionEvent.ACTION_DOWN -> {
                activePointerId = ev.getPointerId(0)
                initialX = ev.x
                initialY = ev.y
                scrollState = ScrollState.IDLE
                // Don't intercept yet
                parent?.requestDisallowInterceptTouchEvent(false)
            }

            MotionEvent.ACTION_POINTER_DOWN -> {
                // Multi-touch - reset state
                scrollState = ScrollState.IDLE
            }

            MotionEvent.ACTION_MOVE -> {
                val pointerIndex = ev.findPointerIndex(activePointerId)
                if (pointerIndex == -1) return false

                val x = ev.getX(pointerIndex)
                val y = ev.getY(pointerIndex)
                val dx = abs(x - initialX)
                val dy = abs(y - initialY)

                if (scrollState == ScrollState.IDLE) {
                    // Determine scroll direction with threshold
                    if (dx > touchSlop || dy > touchSlop) {
                        if (dx > dy * 1.5f) {
                            // Strong horizontal movement
                            scrollState = ScrollState.HORIZONTAL
                            parent?.requestDisallowInterceptTouchEvent(true)
                        } else if (dy > dx * 1.5f) {
                            // Strong vertical movement
                            scrollState = ScrollState.VERTICAL
                            parent?.requestDisallowInterceptTouchEvent(false)
                        }
                        // If dx ≈ dy, wait for clearer direction
                    }
                } else {
                    // Already determined - maintain state
                    when (scrollState) {
                        ScrollState.HORIZONTAL ->
                            parent?.requestDisallowInterceptTouchEvent(true)
                        ScrollState.VERTICAL ->
                            parent?.requestDisallowInterceptTouchEvent(false)
                        else -> {}
                    }
                }
            }

            MotionEvent.ACTION_UP,
            MotionEvent.ACTION_CANCEL -> {
                scrollState = ScrollState.IDLE
                parent?.requestDisallowInterceptTouchEvent(false)
                activePointerId = -1
            }
        }

        return super.onInterceptTouchEvent(ev)
    }

    // MARK: - Measurement

    override fun onMeasure(widthMeasureSpec: Int, heightMeasureSpec: Int) {
        // Measure the ComposeView first
        composeView.measure(widthMeasureSpec, heightMeasureSpec)

        // Get the measured dimensions from ComposeView
        val width = composeView.measuredWidth
        var height = composeView.measuredHeight

        // Handle wrap_content edge case
        if (height == 0 && MeasureSpec.getMode(heightMeasureSpec) == MeasureSpec.AT_MOST) {
            // Give it a minimum height to prevent 0-height flash
            height = 100 // Minimum placeholder height in pixels
        }

        // Set our dimensions
        setMeasuredDimension(width, height)
    }

    // MARK: - Lifecycle Handling

    // Empty override is intentional — documents that we deliberately DO NOT
    // clear state on detach. The lifecycle observer in [setupLifecycleObserver]
    // clears state on actual destruction; clearing here breaks transient
    // detach/re-attach paths (ViewPager page changes, animations, dialogs
    // covering the host) where the same VG instance is expected to re-render
    // its existing unit on re-attach. RecyclerView recycling uses the explicit
    // [onRecycled] entry point.
    @Suppress("RedundantOverride")
    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()
        // Retry a pending rehydrate when restore ran before the bridge cache was ready
        // (host's NativeDisplayBridge.initialize hadn't been called yet, or the unit
        // hadn't landed in the cache yet). Safe no-op when the unit is already applied
        // or still absent from the bridge.
        val pendingUnitId = unitIdState.value
        if (configState.value == null && pendingUnitId != null) {
            rehydrateFromBridge(pendingUnitId)
        }
        if (configState.value != null) {
            requestLayout()
        }
    }

    // MARK: - State Save / Restore

    /**
     * Persist enough state to rehydrate the displayed unit across Activity
     * recreation (rotation, process restore). Only the [unitId] is saved —
     * the actual unit is looked up from the bridge cache on restore, which
     * keeps the Parcel small and avoids serialising large parsed configs.
     *
     * **Requires a stable `android:id`** on this view — Android's
     * `saveHierarchyState` skips Views with `NO_ID`. A VG declared inline in
     * XML with `android:id="@+id/..."` survives rotation automatically;
     * programmatically-created VGs that are added/removed from a container
     * each lifecycle do not, and should use a host-side state holder
     * (e.g. a ViewModel) instead.
     *
     * **Listeners are not restored.** `NativeDisplayActionListener` and
     * `NativeDisplayComponentListener` are closures over the host
     * Activity/Fragment and are not safe to persist. After restore, the
     * caller must re-attach them via [setUnit] / [setConfig] if they need
     * to handle interactions; the unit will still render correctly without
     * them.
     */
    override fun onSaveInstanceState(): Parcelable? {
        val superState = super.onSaveInstanceState()
        val savedUnitId = unitIdState.value ?: return superState
        return SavedState(superState, savedUnitId)
    }

    override fun onRestoreInstanceState(state: Parcelable?) {
        if (state !is SavedState) {
            super.onRestoreInstanceState(state)
            return
        }
        super.onRestoreInstanceState(state.superState)
        // Stash the restored id even if the bridge can't resolve it right now:
        // [onAttachedToWindow] retries when the parent enters the window, and a
        // host-driven [setUnit] will overwrite this value if the host gets there
        // first. Without this, an early restore (bridge not yet initialized, or
        // unit not yet loaded into the cache) would silently drop the saved id.
        unitIdState.value = state.unitId
        rehydrateFromBridge(state.unitId)
    }

    private fun rehydrateFromBridge(unitId: String) {
        val unit = NativeDisplayBridge.getInstance()?.getNativeDisplayForId(unitId) ?: return
        setUnit(unit)
    }

    private class SavedState : BaseSavedState {
        val unitId: String

        constructor(superState: Parcelable?, unitId: String) : super(superState) {
            this.unitId = unitId
        }

        private constructor(parcel: Parcel) : super(parcel) {
            unitId = parcel.readString().orEmpty()
        }

        override fun writeToParcel(out: Parcel, flags: Int) {
            super.writeToParcel(out, flags)
            out.writeString(unitId)
        }

        companion object {
            @JvmField
            val CREATOR: Parcelable.Creator<SavedState> = object : Parcelable.Creator<SavedState> {
                override fun createFromParcel(parcel: Parcel): SavedState = SavedState(parcel)
                override fun newArray(size: Int): Array<SavedState?> = arrayOfNulls(size)
            }
        }
    }
}