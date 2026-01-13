package com.clevertap.nativedisplay.view

import android.content.Context
import android.util.AttributeSet
import android.view.MotionEvent
import android.view.ViewConfiguration
import android.widget.FrameLayout
import androidx.compose.material3.MaterialTheme
import androidx.compose.runtime.*
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ComposeView
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.core.view.ViewCompat.isNestedScrollingEnabled
import androidx.lifecycle.DefaultLifecycleObserver
import androidx.lifecycle.LifecycleOwner
import androidx.lifecycle.findViewTreeLifecycleOwner
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.listener.NativeDisplayComponentListener
import com.clevertap.android.nativedisplay.models.ResolvedConfig
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView

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
 * <com.clevertap.nativedisplay.view.NativeDisplayViewGroup
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

                config?.let { resolvedConfig ->
                    MaterialTheme {
                        NativeDisplayView(
                            config = resolvedConfig,
                            modifier = Modifier,
                            actionListener = actionListener,
                            componentListener = componentListener
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
    fun setConfig(
        config: ResolvedConfig,
        actionListener: NativeDisplayActionListener? = null,
        componentListener: NativeDisplayComponentListener? = null
    ) {
        // Clear recycled state
        isRecycled = false

        // Update state - this triggers recomposition
        configState.value = config
        actionListenerState.value = actionListener
        componentListenerState.value = componentListener

        // Request layout to ensure proper sizing
        requestLayout()
    }

    /**
     * Clear the current configuration and remove all content.
     */
    fun clearConfig() {
        configState.value = null
        actionListenerState.value = null
        componentListenerState.value = null
    }

    /**
     * Call this when RecyclerView recycles the view.
     * Prepares the view for reuse and prevents memory leaks.
     */
    fun onRecycled() {
        isRecycled = true

        // Clear listeners to prevent memory leaks
        actionListenerState.value = null
        componentListenerState.value = null

        // Clear config
        configState.value = null
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
                val dx = Math.abs(x - initialX)
                val dy = Math.abs(y - initialY)

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

    override fun onDetachedFromWindow() {
        super.onDetachedFromWindow()

        // Clear state if not recycled
        if (!isRecycled) {
            configState.value = null
            actionListenerState.value = null
            componentListenerState.value = null
        }
    }

    override fun onAttachedToWindow() {
        super.onAttachedToWindow()

        // Request layout when attached
        if (configState.value != null) {
            requestLayout()
        }
    }
}