package com.clevertap.android.nativeui.sample.xmlfeed

import android.content.Intent
import android.graphics.Color
import android.net.Uri
import android.os.Bundle
import android.text.Editable
import android.text.TextWatcher
import android.view.ContextThemeWrapper
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import android.view.ViewGroup.LayoutParams.WRAP_CONTENT
import android.view.inputmethod.EditorInfo
import android.widget.LinearLayout
import androidx.core.view.doOnAttach
import androidx.fragment.app.Fragment
import androidx.fragment.app.activityViewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.view.NativeDisplayViewGroup
import com.clevertap.android.nativeui.sample.databinding.FragmentXmlFeedBinding
import com.clevertap.android.sdk.CleverTapAPI
import com.google.android.material.R as MaterialR
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.launch

/**
 * XML-based integration demo (Approach 2 — custom rendering via Views).
 *
 * Mirrors `CleverTapIntegrationScreen` (Compose) but implemented entirely with XML +
 * the Views system. Demonstrates [NativeDisplayViewGroup] — the View-system equivalent
 * of the Compose `NativeDisplayView`.
 *
 *  - Fires CleverTap events via EditText + button.
 *  - Listens on [NativeDisplayBridge] and, for each [NativeDisplayUnit] that arrives,
 *    adds a fresh [NativeDisplayViewGroup] to the canvas and feeds the unit into it.
 *  - Shows an event log at the bottom.
 *
 * For the slot-based ([Approach 1][com.clevertap.android.nativedisplay.placement.NativeDisplaySlotView])
 * Views demo, see `XmlSlotsFragment`.
 */
class XmlFeedFragment : Fragment() {

    private var _binding: FragmentXmlFeedBinding? = null
    private val binding get() = _binding!!

    // Activity-scoped so the cached units / log survive the remove+add that
    // XmlFeedScreen performs on rotation (a fragment-scoped VM would be cleared
    // because the fragment instance is destroyed during that transition).
    private val viewModel: XmlFeedViewModel by activityViewModels()

    private var bridge: NativeDisplayBridge? = null
    private var cleverTapApi: CleverTapAPI? = null

    private val bridgeListener = object : NativeDisplayBridgeListener {
        // Only push into the VM. Rendering is driven exclusively by the
        // repeatOnLifecycle(STARTED) collector in onViewCreated — that gate
        // ensures the view tree is actually attached before canvas.addView
        // runs. Calling renderUnits directly here used to race ahead of the
        // attach pass on rotation and produced a blank screen.
        override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
            viewModel.setUnits(units)
            log("Received ${units.size} unit(s): ${units.joinToString { it.unitId }}")
        }
    }

    private val actionListener = object : NativeDisplayActionListener {
        override fun onOpenUrl(url: String, openInBrowser: Boolean): Boolean {
            log("ACTION openUrl: $url")
            try {
                startActivity(Intent(Intent.ACTION_VIEW, Uri.parse(url)).apply {
                    flags = Intent.FLAG_ACTIVITY_NEW_TASK
                })
            } catch (e: Exception) {
                log("ERROR opening URL: ${e.message}")
            }
            return true
        }

        override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) {
            log("ACTION custom: $key=$value")
        }

        override fun onNavigate(destination: String, params: Map<String, String>?) {
            log("ACTION navigate: $destination")
        }

        override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
            val propsStr = properties?.entries?.joinToString(", ") { "${it.key}=${it.value}" } ?: ""
            log("EVENT $eventName $propsStr")
        }

        override fun onActionError(action: Action, error: Throwable) {
            log("ERROR ${error.message}")
        }
    }

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        // MaterialButton/CardView requires Theme.MaterialComponents; wrap the inflater context.
        val themedInflater = inflater.cloneInContext(
            ContextThemeWrapper(requireContext(), MaterialR.style.Theme_MaterialComponents_Light_NoActionBar)
        )
        _binding = FragmentXmlFeedBinding.inflate(themedInflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        cleverTapApi = CleverTapAPI.getDefaultInstance(requireContext().applicationContext)
        bridge = NativeDisplayBridge.initialize(requireContext().applicationContext)
        bridge?.addListener(bridgeListener)

        setupEventInput()
        setupClearLog()
        setupLogToggle()

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.logEntries.collect { entries ->
                    updateLogView(entries)
                }
            }
        }

        // VM is the single source of truth: bridgeListener only writes here, the
        // collector below is the only render entry point. distinctUntilChanged keyed
        // on unit ids absorbs Core SDK redeliveries that carry the same logical
        // payload (same wzrk_id) re-parsed into a structurally-different list — those
        // would otherwise trigger a wasteful second renderUnits on every rotation.
        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.receivedUnits
                    .distinctUntilChanged { old, new -> old.map { it.unitId } == new.map { it.unitId } }
                    .collect { units ->
                        // Pass empty lists through too — renderUnits clears the canvas
                        // and surfaces emptyCanvasText so stale widgets don't linger
                        // when the bridge / VM transitions back to no units.
                        renderUnits(units)
                    }
            }
        }
    }

    private fun setupEventInput() {
        binding.eventNameInput.addTextChangedListener(object : TextWatcher {
            override fun afterTextChanged(s: Editable?) {
                binding.sendEventButton.isEnabled = s?.isNotBlank() == true && cleverTapApi != null
            }
            override fun beforeTextChanged(s: CharSequence?, start: Int, count: Int, after: Int) {}
            override fun onTextChanged(s: CharSequence?, start: Int, before: Int, count: Int) {}
        })

        binding.eventNameInput.setOnEditorActionListener { _, actionId, _ ->
            if (actionId == EditorInfo.IME_ACTION_SEND) { fireEvent(); true } else false
        }

        binding.sendEventButton.setOnClickListener { fireEvent() }
    }

    private fun fireEvent() {
        val name = binding.eventNameInput.text?.toString()?.trim() ?: return
        if (name.isEmpty()) return
        cleverTapApi?.pushEvent(name)
        log("Fired event: $name")
        binding.eventNameInput.setText("")
    }

    private fun setupClearLog() {
        binding.clearLogButton.setOnClickListener {
            viewModel.clearLog()
        }
    }

    /**
     * Wires the show/hide toggle on the event log header. Defaults to "visible" so humans
     * see the log; tests can tap [R.id.event_log_toggle] to hide the log content before
     * screenshotting so it doesn't obstruct the rendered UI.
     *
     * When hidden, the log content ScrollView is gone AND the container's layout params are
     * collapsed to wrap_content (with weight=0 in landscape) so the panel shrinks to just the
     * header row instead of leaving a big empty rectangle.
     */
    private fun setupLogToggle() {
        // Cache the layout params from the inflated XML so we can restore them when re-shown.
        // Portrait: container is wrap_content; landscape: container has weight=1.
        val originalParams = binding.eventLogContainer.layoutParams as LinearLayout.LayoutParams
        val originalHeight = originalParams.height
        val originalWeight = originalParams.weight

        var logVisible = true
        binding.eventLogToggle.setOnClickListener {
            logVisible = !logVisible
            binding.eventLogContent.visibility = if (logVisible) View.VISIBLE else View.GONE
            binding.clearLogButton.visibility = if (logVisible) View.VISIBLE else View.GONE
            val lp = binding.eventLogContainer.layoutParams as LinearLayout.LayoutParams
            if (logVisible) {
                lp.height = originalHeight
                lp.weight = originalWeight
            } else {
                lp.height = WRAP_CONTENT
                lp.weight = 0f
            }
            binding.eventLogContainer.layoutParams = lp
            binding.eventLogToggle.contentDescription =
                if (logVisible) "Hide event log" else "Show event log"
            // Toggle the icon between "view" (eye) and "view-off" (closed-eye-ish stand-in;
            // framework drawables don't ship a true VisibilityOff so we reuse close_clear_cancel).
            binding.eventLogToggle.setImageResource(
                if (logVisible) android.R.drawable.ic_menu_view
                else android.R.drawable.ic_menu_close_clear_cancel
            )
        }
    }

    private fun renderUnits(units: List<NativeDisplayUnit>) {
        val canvas = binding.displayCanvas

        // On rotation the StateFlow collector can fire as soon as the fragment
        // reaches STARTED, which on some devices precedes the canvas finishing
        // its first layout pass — addView against an unattached parent would
        // leave the widget orphaned (no onAttachedToWindow → no Compose start →
        // blank). Defer until the canvas actually attaches.
        if (!canvas.isAttachedToWindow) {
            canvas.doOnAttach { renderUnits(units) }
            return
        }

        if (units.isEmpty()) {
            binding.emptyCanvasText.visibility = View.VISIBLE
            canvas.visibility = View.GONE
            canvas.removeAllViews()
            return
        }
        binding.emptyCanvasText.visibility = View.GONE
        canvas.visibility = View.VISIBLE
        canvas.removeAllViews()

        // One NativeDisplayViewGroup per received unit, stacked vertically.
        val spacingPx = (12 * resources.displayMetrics.density).toInt()
        units.forEachIndexed { index, unit ->
            val widget = NativeDisplayViewGroup(requireContext()).apply {
                layoutParams = LinearLayout.LayoutParams(
                    LinearLayout.LayoutParams.MATCH_PARENT,
                    LinearLayout.LayoutParams.WRAP_CONTENT
                ).also {
                    if (index > 0) it.topMargin = spacingPx
                }
                setUnit(unit, actionListener = actionListener)
            }
            canvas.addView(widget)
        }
    }

    private fun log(message: String) {
        viewModel.log(message)
    }

    private fun updateLogView(entries: List<String>) {
        if (entries.isEmpty()) {
            binding.logTextView.text = "No events yet"
            binding.logTextView.setTextColor(Color.parseColor("#607D8B"))
            return
        }
        binding.logTextView.text = entries.joinToString("\n")
        binding.logTextView.setTextColor(Color.parseColor("#80CBC4"))
        binding.eventLogContent.post { binding.eventLogContent.fullScroll(View.FOCUS_DOWN) }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        bridge?.removeListener(bridgeListener)
        _binding = null
    }
}
