// Incremental, cross-run asset-URL manifest + Coil cache warming for the live
// (instrumented) events-screen screenshot automation.
//
// Counterpart of:
//   * flutter-sample/lib/automation/asset_manifest_automation.dart
//   * ios-sample/NativeDisplaySample/ImagePreloader.swift (AssetManifest)
//
// WHY: EventsScreenshotsTest fires campaigns live against the server, so a
// campaign's images are COLD on the first run — the first capture can show
// placeholders. The documented workaround is to "run the test twice" and keep
// the warm second pass. This removes that need:
//
//   1. COLLECT — a lightweight NativeDisplayBridgeListener registered before the
//      capture loop extracts every http(s) asset URL from each unit's `rawJson`
//      and APPENDS the new ones (deduped, union across runs) to a manifest file
//      in the app's files dir.
//   2. WARM — before firing events we read the manifest and pre-fetch every URL
//      through the SAME Coil ImageLoader the renderer uses
//      (ImageLoaderProvider.getImageLoader), filling its memory + disk cache.
//
// "Incremental" = the manifest is a union across runs (read existing, add new,
// never drop). Coil's disk cache also persists on the device across runs, so
// once a campaign's assets have been observed, every later run warms them before
// the campaign is even fired — making a single pass sufficient.
//
// This lives in androidTest (not the app) so production behaviour is untouched;
// the whole flow only runs inside the automation suite.

package com.clevertap.android.nativeui.sample.automation

import android.content.Context
import android.util.Log
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridge
import com.clevertap.android.nativedisplay.bridge.NativeDisplayBridgeListener
import com.clevertap.android.nativedisplay.bridge.NativeDisplayUnit
import coil.ImageLoader
import coil.request.ImageRequest
import coil.request.SuccessResult
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.async
import kotlinx.coroutines.awaitAll
import kotlinx.coroutines.runBlocking
import java.io.File

object AssetManifestAutomation {

    private const val TAG = "ndAutomation"
    private const val MANIFEST_FILE = "nd-asset-urls.txt"

    // "url": "https://..." — matches image/video bindings and background image urls.
    private val URL_REGEX = Regex(""""url"\s*:\s*"(https?://[^"]+)"""")

    private fun manifestFile(context: Context): File =
        File(context.applicationContext.filesDir, MANIFEST_FILE)

    /** Reads the manifest into an ordered, de-duplicated list. */
    fun read(context: Context): List<String> {
        val file = manifestFile(context)
        if (!file.exists()) return emptyList()
        return try {
            file.readLines().map { it.trim() }.filter { it.isNotEmpty() }.distinct()
        } catch (e: Exception) {
            Log.w(TAG, "Could not read asset manifest", e)
            emptyList()
        }
    }

    /** Extracts non-template http(s) asset URLs from a raw unit JSON string. */
    private fun extractUrls(rawJson: String?): List<String> {
        if (rawJson.isNullOrEmpty()) return emptyList()
        return URL_REGEX.findAll(rawJson)
            .map { it.groupValues[1] }
            .filter { !it.contains("{{") }
            .toList()
    }

    /**
     * Appends any newly-seen asset URLs from [units] to the manifest (union
     * across runs). Called from the bridge listener as live units arrive.
     */
    @Synchronized
    fun record(context: Context, units: List<NativeDisplayUnit>) {
        val known = read(context).toMutableSet()
        val before = known.size
        val added = mutableListOf<String>()
        for (unit in units) {
            for (url in extractUrls(unit.rawJson)) {
                if (known.add(url)) added.add(url)
            }
        }
        if (added.isEmpty()) return
        try {
            val file = manifestFile(context)
            // Append-only — preserves previously-seen URLs across runs.
            file.appendText(added.joinToString(separator = "\n", postfix = "\n"))
            Log.i(TAG, "Manifest +${added.size} new asset URL(s) " +
                "(total ${before + added.size}) -> ${file.absolutePath}")
        } catch (e: Exception) {
            Log.w(TAG, "Failed to append to asset manifest", e)
        }
    }

    /**
     * Registers a bridge listener that appends asset URLs from arriving units to
     * the manifest. Returns the listener so the caller can remove it on teardown.
     */
    fun startCollecting(context: Context): NativeDisplayBridgeListener {
        val bridge = NativeDisplayBridge.initialize(context.applicationContext)
        val listener = object : NativeDisplayBridgeListener {
            override fun onNativeDisplaysLoaded(units: List<NativeDisplayUnit>) {
                record(context, units)
            }
        }
        bridge.addListener(listener)
        Log.d(TAG, "Asset-manifest collector attached")
        return listener
    }

    fun stopCollecting(context: Context, listener: NativeDisplayBridgeListener) {
        try {
            NativeDisplayBridge.initialize(context.applicationContext).removeListener(listener)
        } catch (_: Throwable) { /* ignore */ }
    }

    /**
     * Pre-fetches every manifest URL through Coil, filling Coil's app-wide DISK
     * cache so the first capture renders warm.
     *
     * Note: the SDK's renderer uses an internal ImageLoader singleton
     * (`ImageLoaderProvider`, not visible from this test module), so we can't
     * share its in-memory cache. We build our own ImageLoader here, but Coil's
     * default DISK cache directory is per-app and shared across ImageLoaders —
     * so warming it populates the exact disk cache the renderer's loader reads
     * from. (Coil also persists this disk cache across process runs, which is
     * what makes the "run twice" workaround unnecessary.)
     *
     * Skips video URLs (not in the image pipeline). Best-effort: offline/404
     * failures are logged and skipped.
     */
    fun warmCoilCache(context: Context) {
        val urls = read(context).filter { !isVideo(it) }
        if (urls.isEmpty()) {
            Log.i(TAG, "Asset manifest empty — nothing to warm. Run once to populate; " +
                "later runs will warm before capture.")
            return
        }
        val imageLoader = ImageLoader.Builder(context.applicationContext).build()
        Log.i(TAG, "Warming Coil cache for ${urls.size} manifest asset(s)…")
        var ok = 0
        runBlocking {
            urls.map { url ->
                async(Dispatchers.IO) {
                    try {
                        val request = ImageRequest.Builder(context.applicationContext)
                            .data(url)
                            .build()
                        if (imageLoader.execute(request) is SuccessResult) ok++
                    } catch (e: Exception) {
                        Log.w(TAG, "Warm failed for $url", e)
                    }
                }
            }.awaitAll()
        }
        Log.i(TAG, "Coil cache warm complete: $ok/${urls.size} asset(s) ready.")
    }

    private fun isVideo(url: String): Boolean {
        val lower = url.lowercase()
        return listOf(".mp4", ".m3u8", ".webm", ".mov").any { lower.endsWith(it) }
    }
}
