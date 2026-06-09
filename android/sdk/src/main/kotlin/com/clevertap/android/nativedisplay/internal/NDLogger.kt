package com.clevertap.android.nativedisplay.internal

import android.util.Log

/**
 * Structured logger for the Native Display SDK.
 *
 * Log levels mirror the CleverTap Core SDK convention so that [syncFromCoreSdk] can
 * map Core SDK debug levels directly:
 *   -1 = OFF  (suppress all output)
 *    0 = INFO  (warnings + errors only)
 *    2 = DEBUG (development-level detail)
 *    3 = VERBOSE (maximum verbosity)
 *
 * Ordering: VERBOSE > DEBUG > INFO. OFF suppresses everything.
 * Warnings and errors are emitted at INFO and above — they are always important.
 *
 * Default level: INFO. Clients set a higher level via [NativeDisplayBridge.setLogLevel].
 *
 * Clients set the level via [NativeDisplayBridge.setLogLevel] which accepts the public
 * [NDLogLevel] enum. Internal SDK code uses this object directly.
 */
internal object NDLogger {

    /**
     * Log verbosity levels. Values match CleverTap Core SDK's `setDebugLevel` integers
     * so [syncFromCoreSdk] can cast directly.
     */
    enum class Level(val value: Int) {
        OFF(-1),
        INFO(0),
        DEBUG(2),
        VERBOSE(3);

        companion object {
            /**
             * Map a Core SDK integer debug level to an [Level], falling back to [DEBUG]
             * for unknown values (e.g. future levels introduced by a newer Core SDK).
             */
            fun fromInt(v: Int): Level = entries.firstOrNull { it.value == v } ?: DEBUG
        }
    }

    private val stateLock = Any()

    @Volatile
    private var level: Level = Level.INFO

    @Volatile
    private var explicitlySet: Boolean = false

    /** Set the active log level. Marks the level as explicitly set. */
    fun setLevel(l: Level) {
        synchronized(stateLock) {
            level = l
            explicitlySet = true
        }
    }

    /** Return the currently active log level. */
    fun getLevel(): Level = level

    /** True if a client call to [setLevel] has already set an explicit preference. */
    fun isExplicitlySet(): Boolean = explicitlySet

    /**
     * Sync from the CleverTap Core SDK integer debug level.
     *
     * Does NOT set [explicitlySet] — allows re-sync on subsequent auto-wire calls
     * until the client explicitly calls [setLevel].
     *
     * @param coreLevel Integer returned by `CleverTapAPI.getDebugLevel()`
     */
    fun syncFromCoreSdk(coreLevel: Int) {
        synchronized(stateLock) {
            if (!explicitlySet) {
                level = Level.fromInt(coreLevel)
            }
        }
    }

    // ── Log methods ────────────────────────────────────────────────────────

    fun v(tag: String, msg: String) {
        if (level.value >= Level.VERBOSE.value) Log.v(tag, msg)
    }

    fun d(tag: String, msg: String) {
        if (level.value >= Level.DEBUG.value) Log.d(tag, msg)
    }

    fun i(tag: String, msg: String) {
        if (level.value >= Level.INFO.value) Log.i(tag, msg)
    }

    /** Warnings are shown at INFO and above (they are always significant). */
    fun w(tag: String, msg: String) {
        if (level.value >= Level.INFO.value) Log.w(tag, msg)
    }

    /** Errors are shown at INFO and above (they are always significant). */
    fun e(tag: String, msg: String, t: Throwable? = null) {
        if (level.value >= Level.INFO.value) {
            if (t != null) Log.e(tag, msg, t) else Log.e(tag, msg)
        }
    }
}
