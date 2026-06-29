package com.clevertap.android.nativeui.sample.xmlslots

import android.os.Bundle
import android.view.LayoutInflater
import android.view.View
import android.view.ViewGroup
import androidx.fragment.app.Fragment
import androidx.recyclerview.widget.LinearLayoutManager
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativeui.sample.databinding.FragmentXmlSlotsBinding
import com.clevertap.android.sdk.CleverTapAPI

/**
 * XML-based slot integration demo (Approach 1 — slot-based via Views).
 *
 * The View-system parallel of `SlotDemoScreen` (Compose). The whole screen is
 * a single [androidx.recyclerview.widget.RecyclerView] driven by
 * [SlotFeedAdapter]: row 0 is the "Slot Demo" header (title + description +
 * full-width "Fetch Slot Data" button), followed by 19 interleaved rows (4
 * `NativeDisplaySlotView`s + 15 first-party content cards) — identical to the
 * Compose demo.
 *
 * The "Fetch Slot Data" button fires the same hardcoded CleverTap events as
 * the Compose demo; each `NativeDisplaySlotView` self-registers with the slot
 * manager on window-attach.
 *
 * For the custom-rendering (Approach 2, `NativeDisplayViewGroup`) Views demo,
 * see `XmlFeedFragment`.
 */
class XmlSlotsFragment : Fragment() {

    private var _binding: FragmentXmlSlotsBinding? = null
    private val binding get() = _binding!!

    private var cleverTapApi: CleverTapAPI? = null

    override fun onCreateView(
        inflater: LayoutInflater,
        container: ViewGroup?,
        savedInstanceState: Bundle?
    ): View {
        _binding = FragmentXmlSlotsBinding.inflate(inflater, container, false)
        return binding.root
    }

    override fun onViewCreated(view: View, savedInstanceState: Bundle?) {
        super.onViewCreated(view, savedInstanceState)

        cleverTapApi = CleverTapAPI.getDefaultInstance(requireContext().applicationContext)
        // Bridge must be initialized before any slot view attaches to its window.
        NativeDisplayBridge.initialize(requireContext().applicationContext)

        binding.slotRecycler.apply {
            layoutManager = LinearLayoutManager(requireContext(), LinearLayoutManager.VERTICAL, false)
            adapter = SlotFeedAdapter(buildSlotFeedItems(), onFetchClick = ::fetchSlotData)
            addItemDecoration(VerticalSpacingItemDecoration(spacingDp = 12))
            setHasFixedSize(true)
        }
    }

    /**
     * Hardcoded events that target the four campaign slots on the dashboard.
     * Mirrors the "Fetch Slot Data" button in `SlotDemoScreen.kt` and
     * `SlotDemoView.swift` so all three demos pull the same campaigns.
     */
    private fun fetchSlotData() {
        cleverTapApi?.run {
            pushEvent("Footer1")
            pushEvent("Footer5")
            pushEvent("Header1")
            pushEvent("Header2")
            pushEvent("Header4")
            pushEvent("lalit")
        }
    }

    override fun onDestroyView() {
        super.onDestroyView()
        // Drop the adapter so RecyclerView detaches slot views (and they
        // unregister from the slot manager) before the binding goes null.
        binding.slotRecycler.adapter = null
        _binding = null
    }
}
