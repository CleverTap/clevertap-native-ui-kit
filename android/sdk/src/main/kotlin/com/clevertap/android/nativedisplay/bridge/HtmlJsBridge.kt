package com.clevertap.android.nativedisplay.bridge

import android.annotation.SuppressLint
import android.content.Context
import android.util.Log
import android.webkit.WebView

/**
 * Injects the CleverTap JavaScript bridge into a WebView.
 *
 * Uses the CleverTap Core SDK's CTWebInterface via reflection.
 * If the Core SDK is not present at runtime, this is a silent no-op.
 */
internal object HtmlJsBridge {

    private const val TAG = "HtmlJsBridge"
    private const val JS_INTERFACE_NAME = "CleverTap"

    /**
     * Attempt to inject the CleverTap JS bridge into the given WebView.
     *
     * @param webView The WebView to inject into
     * @param context Context for CleverTapAPI instance lookup
     * @return true if injection succeeded
     */
    // CTWebInterface methods have @JavascriptInterface — lint can't see through reflection
    @SuppressLint("JavascriptInterface")
    fun tryInjectBridge(webView: WebView, context: Context): Boolean {
        return try {
            // Get CleverTapAPI default instance
            val ctApiClass = Class.forName("com.clevertap.android.sdk.CleverTapAPI")
            val getDefault = ctApiClass.getMethod("getDefaultInstance", Context::class.java)
            val ctInstance = getDefault.invoke(null, context.applicationContext)
                ?: run {
                    Log.d(TAG, "CleverTapAPI.getDefaultInstance() returned null")
                    return false
                }

            // Create CTWebInterface(cleverTapAPI)
            val webInterfaceClass = Class.forName("com.clevertap.android.sdk.CTWebInterface")
            val constructor = webInterfaceClass.getConstructor(ctApiClass)
            val webInterface = constructor.newInstance(ctInstance)

            // Add as JavaScript interface
            webView.addJavascriptInterface(webInterface, JS_INTERFACE_NAME)

            Log.d(TAG, "CleverTap JS bridge injected successfully")
            true
        } catch (_: ClassNotFoundException) {
            Log.d(TAG, "CleverTap Core SDK not found, skipping JS bridge injection")
            false
        } catch (_: NoClassDefFoundError) {
            Log.d(TAG, "CleverTap Core SDK not found, skipping JS bridge injection")
            false
        } catch (e: Exception) {
            Log.w(TAG, "Failed to inject CleverTap JS bridge: ${e.message}")
            false
        }
    }
}
