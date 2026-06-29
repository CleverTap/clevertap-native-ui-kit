package com.clevertap.android.nativedisplay.renderer

import android.annotation.SuppressLint
import android.content.Intent
import android.graphics.Color
import android.view.View
import android.webkit.WebResourceRequest
import android.webkit.WebView
import android.webkit.WebViewClient
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.viewinterop.AndroidView
import com.clevertap.android.nativedisplay.bridge.HtmlJsBridge
import com.clevertap.android.nativedisplay.models.HtmlConfig

/**
 * Composable that renders HTML content in a WebView.
 * WebView is created once in factory and survives recomposition.
 * Content is loaded in update only when bindings change.
 */
@SuppressLint("SetJavaScriptEnabled")
@Composable
internal fun HtmlElementView(
    html: String?,
    url: String?,
    config: HtmlConfig,
    modifier: Modifier = Modifier
) {
    AndroidView(
        factory = { ctx ->
            WebView(ctx).apply {
                // Configure WebView settings (aligned with CT Core SDK's CTInAppWebView)
                settings.apply {
                    javaScriptEnabled = config.javascriptEnabled
                    javaScriptCanOpenWindowsAutomatically = false
                    domStorageEnabled = config.javascriptEnabled
                    // Security: disable file and universal access
                    allowFileAccess = false
                    allowContentAccess = false
                    @SuppressLint("AllowFileAccessFromFileURLs")
                    allowFileAccessFromFileURLs = false
                    // Disable zoom
                    setSupportZoom(false)
                    builtInZoomControls = false
                    displayZoomControls = false
                    // Prevent system font scaling from distorting HTML layout
                    textZoom = 100
                    // User scaling
                    loadWithOverviewMode = true
                    useWideViewPort = true
                }

                // Scroll behavior
                overScrollMode = View.OVER_SCROLL_NEVER
                isVerticalScrollBarEnabled = config.scrollEnabled
                isHorizontalScrollBarEnabled = config.scrollEnabled
                isVerticalFadingEdgeEnabled = false
                isHorizontalFadingEdgeEnabled = false

                // Transparent background
                if (config.transparentBackground) {
                    setBackgroundColor(Color.TRANSPARENT)
                }

                // Block navigation — links open externally
                webViewClient = object : WebViewClient() {
                    override fun shouldOverrideUrlLoading(
                        view: WebView?,
                        request: WebResourceRequest?
                    ): Boolean {
                        request?.url?.let { uri ->
                            try {
                                ctx.startActivity(Intent(Intent.ACTION_VIEW, uri))
                            } catch (_: Exception) {
                                // No handler for this URL scheme
                            }
                        }
                        return true
                    }
                }

                // Try to inject CleverTap JS bridge
                HtmlJsBridge.tryInjectBridge(this, ctx)
            }
        },
        update = { webView ->
            // Load content — html takes priority over url
            when {
                !html.isNullOrEmpty() -> {
                    // Wrap with responsive body sizing (aligned with CT Core SDK pattern)
                    // If HTML already has <head>, inject sizing style there;
                    // otherwise wrap in a full document with viewport meta
                    val finalHtml = wrapHtmlWithResponsiveSizing(html)
                    webView.loadDataWithBaseURL(
                        config.baseUrl,
                        finalHtml,
                        "text/html",
                        "UTF-8",
                        null
                    )
                }
                !url.isNullOrEmpty() -> {
                    webView.loadUrl(url)
                }
            }
        },
        onRelease = { webView ->
            webView.stopLoading()
            webView.loadUrl("about:blank")
            webView.clearHistory()
            webView.destroy()
        },
        modifier = modifier
    )
}

/**
 * Wraps inline HTML with responsive body sizing to fill the WebView dimensions.
 * Follows the Core SDK pattern (CTInAppBaseFullHtmlFragment) of injecting
 * body sizing styles so content fills the allocated space.
 *
 * - If the HTML already has a <head> tag, injects responsive styles into it.
 * - Otherwise, wraps in a full HTML document with viewport meta and body sizing.
 */
private fun wrapHtmlWithResponsiveSizing(html: String): String {
    val responsiveStyle = "<style>body{margin:0;padding:0;width:100%;height:100%;}</style>" +
        "<meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>"

    return if (html.contains("<head>", ignoreCase = true)) {
        // Inject into existing <head> (same as Core SDK's replaceFirst pattern)
        html.replaceFirst("<head>", "<head>$responsiveStyle", ignoreCase = true)
    } else if (html.contains("<!DOCTYPE", ignoreCase = true) || html.contains("<html", ignoreCase = true)) {
        // Full document without <head> — prepend styles as-is (browser auto-creates <head>)
        "$responsiveStyle$html"
    } else {
        // HTML fragment — wrap in full document
        "<!DOCTYPE html><html><head>$responsiveStyle</head><body>$html</body></html>"
    }
}
