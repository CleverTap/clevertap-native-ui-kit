package com.clevertap.android.nativedisplay.bridge

import com.clevertap.android.nativedisplay.internal.NDLogger

/**
 * Public log-level enum for the Native Display SDK.
 *
 * Values mirror the CleverTap Core SDK's `setDebugLevel` integer convention:
 *
 * | Level   | Value | Description                              |
 * |---------|-------|------------------------------------------|
 * | OFF     | -1    | Suppress all SDK log output              |
 * | INFO    |  0    | Warnings and errors only (production-safe)|
 * | DEBUG   |  2    | Development-level detail                 |
 * | VERBOSE |  3    | Maximum verbosity                        |
 *
 * **Usage:**
 * ```kotlin
 * NativeDisplayBridge.setLogLevel(NDLogLevel.DEBUG)   // verbose dev builds
 * NativeDisplayBridge.setLogLevel(NDLogLevel.OFF)     // silence in production
 * ```
 */
enum class NDLogLevel {
    OFF,
    INFO,
    DEBUG,
    VERBOSE;

    /** Map to the internal [NDLogger.Level]. */
    internal fun toInternal(): NDLogger.Level = when (this) {
        OFF -> NDLogger.Level.OFF
        INFO -> NDLogger.Level.INFO
        DEBUG -> NDLogger.Level.DEBUG
        VERBOSE -> NDLogger.Level.VERBOSE
    }
}
