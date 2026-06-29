package com.clevertap.android.nativedisplay.handler

import android.content.Context
import android.content.ContextWrapper
import com.clevertap.android.nativedisplay.listener.NativeDisplayActionListener
import com.clevertap.android.nativedisplay.models.Action
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.test.UnconfinedTestDispatcher
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.runTest
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test

/**
 * Unit tests for [ActionHandler.fireSystemEvent] auto-attribution behavior.
 *
 * Matrix:
 *   { client listener present / absent }
 * × { bridge push fires / bridge push absent (null Core SDK) }
 * × { "Notification Viewed" / "Notification Clicked" }
 *
 * Production code path: `ActionHandler` always invokes its `pushViewedEvent`/
 * `pushClickedEvent` lambdas for matching events. In production those lambdas
 * delegate to `NativeDisplayBridge.getInstance()?.pushViewedEvent(...)` etc.,
 * which is itself null-guarded on `cleverTapApi`. We exercise the seam directly
 * with capturing fakes so we can assert ordering and the no-op branches without
 * standing up CleverTapAPI / Compose.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class ActionHandlerSystemEventTest {

    // `ActionHandler`'s coroutineScope is bound to `Dispatchers.Main`; using an
    // unconfined dispatcher means `launch { ... }` runs inline so assertions are
    // immediate (no advanceUntilIdle needed).
    private val context: Context = ContextWrapper(null)

    @Before
    fun setUp() {
        Dispatchers.setMain(UnconfinedTestDispatcher())
    }

    @After
    fun tearDown() {
        Dispatchers.resetMain()
    }

    // -- Test fakes --

    private class FakeListener : NativeDisplayActionListener {
        val trackEvents = mutableListOf<Pair<String, Map<String, Any?>?>>()
        val viewed = mutableListOf<String>()
        val clicked = mutableListOf<String>()

        override fun onTrackEvent(eventName: String, properties: Map<String, Any?>?) {
            trackEvents.add(eventName to properties)
        }
        override fun onCustomAction(key: String, value: Any?, metadata: Map<String, String>?) = Unit
        override fun onNavigate(destination: String, params: Map<String, String>?) = Unit
        override fun onActionError(action: Action, error: Throwable) = Unit
        override fun onDisplayUnitViewed(unitId: String) { viewed.add(unitId) }
        override fun onDisplayUnitClicked(unitId: String) { clicked.add(unitId) }
    }

    /** Counting bridge stand-in for `bridge.pushViewedEvent(unitId)` (no extras). */
    private class ViewedPushCounter {
        val invocations = mutableListOf<String>()
        val fn: (String) -> Unit = { id -> invocations.add(id) }
    }

    /** Counting bridge stand-in for `bridge.pushClickedEvent(unitId, extras)`. */
    private class ClickedPushCounter {
        val invocations = mutableListOf<String>()
        val extras = mutableListOf<Map<String, Any?>?>()
        val fn: (String, Map<String, Any?>?) -> Unit = { id, extra ->
            invocations.add(id)
            extras.add(extra)
        }
    }

    private fun newHandler(
        listener: NativeDisplayActionListener? = null,
        unitId: String? = "unit-1",
        pushViewed: ViewedPushCounter = ViewedPushCounter(),
        pushClicked: ClickedPushCounter = ClickedPushCounter(),
    ): Triple<ActionHandler, ViewedPushCounter, ClickedPushCounter> {
        val handler = ActionHandler(
            context = context,
            unitId = unitId,
            pushViewedEvent = pushViewed.fn,
            pushClickedEvent = pushClicked.fn,
        ).apply {
            this.listener = listener
        }
        return Triple(handler, pushViewed, pushClicked)
    }

    // -- Notification Viewed: client listener present + bridge wired --

    @Test
    fun `viewed fires listener and bridge when both are present`() = runTest {
        val listener = FakeListener()
        val (handler, viewedPusher, clickedPusher) = newHandler(listener)

        handler.fireSystemEvent("Notification Viewed")

        assertEquals(listOf("Notification Viewed"), listener.trackEvents.map { it.first })
        assertEquals(listOf("unit-1"), listener.viewed)
        assertEquals(listOf("unit-1"), viewedPusher.invocations)
        assertTrue(clickedPusher.invocations.isEmpty())
        assertTrue(listener.clicked.isEmpty())
    }

    // -- Notification Viewed: NO client listener, bridge wired --
    // Core requirement of this change: attribution must still fire.

    @Test
    fun `viewed fires bridge even when no client listener is attached`() = runTest {
        val (handler, viewedPusher, _) = newHandler(listener = null)

        handler.fireSystemEvent("Notification Viewed")

        assertEquals(listOf("unit-1"), viewedPusher.invocations)
    }

    // -- Notification Viewed: client listener present, bridge NOT wired (no Core SDK).
    // In production this is `NativeDisplayBridge.getInstance() == null` OR
    // `bridge.cleverTapApi == null`. The default lambda short-circuits silently;
    // we model that with a counter that never gets invoked (we pass a custom
    // lambda which does nothing on purpose and assert listener still fires).

    @Test
    fun `viewed still notifies listener when bridge push is a no-op`() = runTest {
        val listener = FakeListener()
        val noOpPusher = ViewedPushCounter()  // counter exists but lambda body could be no-op
        val handler = ActionHandler(
            context = context,
            unitId = "unit-1",
            pushViewedEvent = { /* simulate bridge missing / cleverTapApi == null */ },
            pushClickedEvent = { _, _ -> /* unused */ },
        ).apply {
            this.listener = listener
        }

        handler.fireSystemEvent("Notification Viewed")

        assertEquals(listOf("unit-1"), listener.viewed)
        assertEquals(listOf("Notification Viewed"), listener.trackEvents.map { it.first })
        // noOpPusher untouched
        assertTrue(noOpPusher.invocations.isEmpty())
    }

    // -- Notification Viewed: no listener AND no bridge: trackEvent still routed
    // through listener (which is null) — overall must be a graceful no-op.

    @Test
    fun `viewed standalone with no listener and no bridge is a graceful no-op`() = runTest {
        val handler = ActionHandler(
            context = context,
            unitId = "unit-1",
            pushViewedEvent = { /* bridge absent */ },
            pushClickedEvent = { _, _ -> /* bridge absent */ },
        )
        // Should not throw.
        handler.fireSystemEvent("Notification Viewed")
    }

    // -- Notification Clicked symmetry --

    @Test
    fun `clicked fires listener and bridge when both are present`() = runTest {
        val listener = FakeListener()
        val (handler, viewedPusher, clickedPusher) = newHandler(listener)

        handler.fireSystemEvent("Notification Clicked")

        assertEquals(listOf("Notification Clicked"), listener.trackEvents.map { it.first })
        assertEquals(listOf("unit-1"), listener.clicked)
        assertEquals(listOf("unit-1"), clickedPusher.invocations)
        assertTrue(viewedPusher.invocations.isEmpty())
        assertTrue(listener.viewed.isEmpty())
    }

    @Test
    fun `clicked fires bridge even when no client listener is attached`() = runTest {
        val (handler, _, clickedPusher) = newHandler(listener = null)

        handler.fireSystemEvent("Notification Clicked")

        assertEquals(listOf("unit-1"), clickedPusher.invocations)
    }

    // -- Null unitId: trackEvent still goes to listener; bridge is skipped --

    @Test
    fun `null unitId fires onTrackEvent but skips bridge and listener attribution`() = runTest {
        val listener = FakeListener()
        val (handler, viewedPusher, clickedPusher) = newHandler(listener, unitId = null)

        handler.fireSystemEvent("Notification Viewed")
        handler.fireSystemEvent("Notification Clicked")

        // onTrackEvent is unit-id-agnostic and still fires.
        assertEquals(
            listOf("Notification Viewed", "Notification Clicked"),
            listener.trackEvents.map { it.first }
        )
        // Attribution callbacks require a unitId — both must remain untouched.
        assertTrue(listener.viewed.isEmpty())
        assertTrue(listener.clicked.isEmpty())
        assertTrue(viewedPusher.invocations.isEmpty())
        assertTrue(clickedPusher.invocations.isEmpty())
    }

    // -- Properties pass-through --

    @Test
    fun `viewed forwards properties to onTrackEvent but not to bridge`() = runTest {
        val listener = FakeListener()
        val (handler, viewedPusher, _) = newHandler(listener)
        val props = mapOf("nodeId" to "root")

        handler.fireSystemEvent("Notification Viewed", properties = props)

        assertEquals(1, listener.trackEvents.size)
        assertEquals("Notification Viewed", listener.trackEvents[0].first)
        assertEquals(props, listener.trackEvents[0].second)
        // Viewed bridge call is unit-level — no extras forwarded.
        assertEquals(listOf("unit-1"), viewedPusher.invocations)
    }

    @Test
    fun `clicked forwards action extras to bridge`() = runTest {
        val (handler, _, clickedPusher) = newHandler()
        val extras = mapOf(
            "wzrk_btn_id" to "cta_buy",
            "action_type" to "open_url",
            "action_url" to "https://example.com"
        )

        handler.fireSystemEvent("Notification Clicked", properties = extras)

        assertEquals(listOf("unit-1"), clickedPusher.invocations)
        assertEquals(listOf<Map<String, Any?>?>(extras), clickedPusher.extras)
    }

    // -- Unrelated system event: bridge NOT invoked --

    @Test
    fun `non-attribution system event does not invoke bridge`() = runTest {
        val listener = FakeListener()
        val (handler, viewedPusher, clickedPusher) = newHandler(listener)

        handler.fireSystemEvent("Some Other Event")

        assertEquals(listOf("Some Other Event"), listener.trackEvents.map { it.first })
        assertTrue(listener.viewed.isEmpty())
        assertTrue(listener.clicked.isEmpty())
        assertTrue(viewedPusher.invocations.isEmpty())
        assertTrue(clickedPusher.invocations.isEmpty())
    }

    // -- Sanity: independent unit IDs --

    @Test
    fun `bridge receives the unitId provided at construction`() = runTest {
        val (handler, viewedPusher, _) = newHandler(unitId = "wzrk-abc-123")

        handler.fireSystemEvent("Notification Viewed")

        assertEquals(listOf("wzrk-abc-123"), viewedPusher.invocations)
    }

    @Test
    fun `null listener and trackEvent has no observable effect`() = runTest {
        // Just guard against NPE on listener?.onTrackEvent when listener is null.
        val (handler, _, _) = newHandler(listener = null)
        handler.fireSystemEvent("Notification Viewed")
        // No assertion needed beyond "did not throw".
        assertNull(null)
    }
}
