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
import android.view.inputmethod.EditorInfo
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.material3.MaterialTheme
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.ViewCompositionStrategy
import androidx.fragment.app.Fragment
import androidx.fragment.app.viewModels
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.lifecycleScope
import androidx.lifecycle.repeatOnLifecycle
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.models.Action
import com.clevertap.android.nativedisplay.renderer.NativeDisplayView
import com.clevertap.android.nativeui.sample.databinding.FragmentXmlFeedBinding
import com.clevertap.android.sdk.CleverTapAPI
import com.google.android.material.R as MaterialR
import kotlinx.coroutines.launch

/**
 * XML-based integration test screen.
 *
 * Mirrors CleverTapIntegrationScreen but implemented entirely with XML layouts + Fragment,
 * to verify the SDK works correctly in a View/XML-based host (not just Compose Activity).
 *
 * - Fires CleverTap events via EditText + button
 * - Renders received NativeDisplayUnits via ComposeView embedded in the XML layout
 * - Shows an event log at the bottom
 */
class XmlFeedFragment : Fragment() {

    private var _binding: FragmentXmlFeedBinding? = null
    private val binding get() = _binding!!

    private val viewModel: XmlFeedViewModel by viewModels()

    private var bridge: NativeDisplayBridge? = null
    private var cleverTapApi: CleverTapAPI? = null

    private val bridgeListener = object : NativeDisplayBridgeListener {
        override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
            viewModel.setUnits(units)
            log("Received ${units.size} unit(s): ${units.joinToString { it.unitId }}")
            renderUnits(units)
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
        setupCanvas()
        setupClearLog()

        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.logEntries.collect { entries ->
                    updateLogView(entries)
                }
            }
        }

        // Re-render units on rotation: ViewModel retains them across configuration changes.
        viewLifecycleOwner.lifecycleScope.launch {
            viewLifecycleOwner.repeatOnLifecycle(Lifecycle.State.STARTED) {
                viewModel.receivedUnits.collect { units ->
                    if (units.isNotEmpty()) {
                        renderUnits(units)
                    }
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

    private fun setupCanvas() {
        binding.displayCanvas.setViewCompositionStrategy(
            ViewCompositionStrategy.DisposeOnViewTreeLifecycleDestroyed
        )
    }

    private fun setupClearLog() {
        binding.clearLogButton.setOnClickListener {
            viewModel.clearLog()
        }
    }

    private fun renderUnits(units: List<NativeDisplayUnit>) {
        if (units.isEmpty()) {
            binding.emptyCanvasText.visibility = View.VISIBLE
            binding.displayCanvas.visibility = View.GONE
            return
        }
        binding.emptyCanvasText.visibility = View.GONE
        binding.displayCanvas.visibility = View.VISIBLE
        binding.displayCanvas.setContent {
            MaterialTheme {
                Column {
                    units.forEach { unit ->
                        NativeDisplayView(
                            config = unit.config,
                            modifier = Modifier.fillMaxWidth(),
                            actionListener = actionListener
                        )
                    }
                }
            }
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
        binding.logScrollView.post { binding.logScrollView.fullScroll(View.FOCUS_DOWN) }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        bridge?.removeListener(bridgeListener)
        _binding = null
    }
}
