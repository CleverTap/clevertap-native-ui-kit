package com.clevertap.android.nativeui.sample

import android.app.Application

/**
 * Sample application.
 *
 * Note: Image loading (including GIF support) is handled internally by the
 * Native Display SDK. No Coil configuration needed in the host app.
 */
class SampleApplication : Application() {
    // No custom ImageLoader needed - SDK provides its own with GIF support
}
