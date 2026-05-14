package com.clevertap.android.nativedisplay.bridge

import kotlinx.coroutines.CoroutineDispatcher
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.asCoroutineDispatcher
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.test.resetMain
import kotlinx.coroutines.test.setMain
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertTrue
import org.junit.Before
import org.junit.Test
import java.util.concurrent.ConcurrentLinkedQueue
import java.util.concurrent.CountDownLatch
import java.util.concurrent.Executors
import java.util.concurrent.TimeUnit
import java.util.concurrent.atomic.AtomicReference

/**
 * SDK-5770: validates that display-unit JSON parsing happens off the calling
 * thread, that listener delivery is marshalled back onto `Dispatchers.Main`,
 * and that submission ordering is preserved across rapid back-to-back calls.
 *
 * Constraints worth noting:
 *  - This is a JVM unit test (no Robolectric on the classpath), so there is
 *    no real Android `Looper`. We swap `Dispatchers.Main` for a real
 *    single-thread executor whose thread is named `nd-test-main`. Listener
 *    delivery is then asserted to run on that thread.
 *  - The bridge's parse scope name (`nd-parse`) is not propagated as a
 *    thread name by `Dispatchers.Default.limitedParallelism(1)`; only the
 *    `CoroutineName` element is. The off-main thread-name check therefore
 *    matches against `Default` / `Worker` markers rather than `nd-parse`.
 */
@OptIn(ExperimentalCoroutinesApi::class)
class NativeDisplayBridgeOffMainParseTest {

    private lateinit var bridge: NativeDisplayBridge

    /** Real single-thread executor standing in for the Android main looper. */
    private lateinit var mainExecutor: java.util.concurrent.ExecutorService
    private lateinit var mainDispatcher: CoroutineDispatcher
    private lateinit var mainThread: Thread

    private fun makeUnitJson(unitId: String, text: String = "Hello"): String = """
        {
            "wzrk_id": "$unitId",
            "native_display_config": {
                "root": {
                    "type": "element",
                    "id": "txt_$unitId",
                    "elementType": "text",
                    "bindings": { "text": "$text" },
                    "layout": {
                        "width": { "special": "match_parent" },
                        "height": { "special": "wrap_content" }
                    }
                }
            }
        }
    """.trimIndent()

    @Before
    fun setUp() {
        // Build a real single-thread executor and capture its thread.
        // We name it "nd-test-main" so the assertion below is unambiguous
        // and won't accidentally collide with the JUnit "Test worker" thread.
        val capturedThread = AtomicReference<Thread>()
        val latch = CountDownLatch(1)
        mainExecutor = Executors.newSingleThreadExecutor { r ->
            Thread(r, "nd-test-main").also { it.isDaemon = true }
        }
        mainExecutor.submit {
            capturedThread.set(Thread.currentThread())
            latch.countDown()
        }
        latch.await(5, TimeUnit.SECONDS)
        mainThread = capturedThread.get()
        mainDispatcher = mainExecutor.asCoroutineDispatcher()

        Dispatchers.setMain(mainDispatcher)

        resetSingleton()
        bridge = NativeDisplayBridge.create()
    }

    @After
    fun tearDown() {
        bridge.clear()
        resetSingleton()
        Dispatchers.resetMain()
        mainExecutor.shutdownNow()
    }

    private fun resetSingleton() {
        try {
            val field = NativeDisplayBridge::class.java.getDeclaredField("instance")
            field.isAccessible = true
            field.set(null, null)
        } catch (_: NoSuchFieldException) {
            NativeDisplayBridge::class.java.declaredFields
                .firstOrNull { it.type == NativeDisplayBridge::class.java }
                ?.let {
                    it.isAccessible = true
                    it.set(null, null)
                }
        }
    }

    /**
     * Block until both the parse scope drains AND the queued listener
     * delivery on `mainDispatcher` finishes. `awaitParseIdle()` waits for
     * the parse scope; submitting a sentinel through `mainExecutor` after
     * that drains anything the parse scope queued onto main.
     */
    private fun awaitProcessed() {
        runBlocking { bridge.awaitParseIdle() }
        val drained = CountDownLatch(1)
        mainExecutor.submit { drained.countDown() }
        assertTrue(
            "main dispatcher did not drain within 5s",
            drained.await(5, TimeUnit.SECONDS)
        )
    }

    // ---------------------------------------------------------------------
    // 1. Parsing happens off the caller's thread.
    // ---------------------------------------------------------------------

    /**
     * Install a thread-recording hook on the bridge's parser. Captures the
     * thread each `tryParse` call runs on via the parser's `threadObserver`
     * test seam. The bridge's parser is private, so reflection is required —
     * but we no longer need to swap the parser instance, only set its
     * observer property (the parser itself is `final internal` and not
     * subclassable).
     */
    private fun installRecordingParser(): ConcurrentLinkedQueue<Thread> {
        val recorded = ConcurrentLinkedQueue<Thread>()
        val parserField = NativeDisplayBridge::class.java.getDeclaredField("parser")
        parserField.isAccessible = true
        val parser = parserField.get(bridge) as NativeDisplayConfigParser
        parser.threadObserver = { recorded.add(it) }
        return recorded
    }

    @Test
    fun `parser runs off the caller thread`() {
        val parseThreads = installRecordingParser()
        val callerThread = Thread.currentThread()

        bridge.processDisplayUnits(listOf(makeUnitJson("u1"), makeUnitJson("u2")))
        bridge.processDisplayUnit(makeUnitJson("u3"))
        awaitProcessed()

        assertEquals("expected one tryParse per submitted JSON", 3, parseThreads.size)
        for (t in parseThreads) {
            assertFalse(
                "tryParse must not run on the test caller thread (got: ${t.name})",
                t == callerThread
            )
            assertFalse(
                "tryParse must not run on the main dispatcher thread (got: ${t.name})",
                t == mainThread
            )
        }
    }

    @Test
    fun `parser thread name marks it as a coroutine default dispatcher worker`() {
        val parseThreads = installRecordingParser()

        bridge.processDisplayUnit(makeUnitJson("probe"))
        awaitProcessed()

        assertEquals(1, parseThreads.size)
        val name = parseThreads.peek()!!.name
        // Default dispatcher workers carry "DefaultDispatcher" / "Worker" in
        // their thread name. Both markers are acceptable across coroutines
        // versions. The assertion deliberately rejects the test thread by
        // way of inclusion checks rather than equality.
        assertTrue(
            "parse worker thread name should look like a Default dispatcher worker " +
                "(got: $name)",
            name.contains("DefaultDispatcher", ignoreCase = true) ||
                name.contains("Worker", ignoreCase = true)
        )
        assertFalse(
            "parse worker must not run on our 'main' executor thread (got: $name)",
            name == "nd-test-main"
        )
    }

    // ---------------------------------------------------------------------
    // 2. Listener delivery happens on Dispatchers.Main.
    // ---------------------------------------------------------------------

    @Test
    fun `processDisplayUnit listener fires on Dispatchers Main`() {
        val notifyThread = AtomicReference<Thread>()
        bridge.addListener(object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                notifyThread.set(Thread.currentThread())
            }
        })

        bridge.processDisplayUnit(makeUnitJson("only"))
        awaitProcessed()

        assertNotNull("listener was never invoked", notifyThread.get())
        assertEquals(
            "listener must fire on the dispatcher we configured as main",
            mainThread, notifyThread.get()
        )
    }

    @Test
    fun `processDisplayUnits listener fires on Dispatchers Main`() {
        val notifyThreads = ConcurrentLinkedQueue<Thread>()
        bridge.addListener(object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                notifyThreads.add(Thread.currentThread())
            }
        })

        bridge.processDisplayUnits(listOf(makeUnitJson("u1")))
        bridge.processDisplayUnits(listOf(makeUnitJson("u2")))
        awaitProcessed()

        assertEquals(2, notifyThreads.size)
        for (t in notifyThreads) {
            assertEquals(
                "every listener notification must fire on the main dispatcher thread",
                mainThread, t
            )
        }
    }

    // ---------------------------------------------------------------------
    // 3. FIFO ordering across rapid back-to-back submissions.
    // ---------------------------------------------------------------------

    @Test
    fun `ten rapid submissions are observed by the listener in submission order`() {
        val received = ConcurrentLinkedQueue<String>()
        bridge.addListener(object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                // processDisplayUnit delivers a single-unit list. We submit
                // ten separate single-unit calls so each notification carries
                // exactly one id.
                for (u in units) received.add(u.unitId)
            }
        })

        // Tight loop on the test thread. The bridge must serialize these
        // FIFO across the parse dispatcher; if it didn't, ids could land
        // out of order.
        val ids = (1..10).map { "u$it" }
        for (id in ids) {
            bridge.processDisplayUnit(makeUnitJson(id))
        }
        awaitProcessed()

        assertEquals(ids, received.toList())
    }
}
