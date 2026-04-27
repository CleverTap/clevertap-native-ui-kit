//
//  HtmlWebView.swift
//  CleverTapNativeDisplay
//

#if os(iOS)
import SwiftUI
import UIKit
import WebKit

/// SwiftUI wrapper for WKWebView that renders HTML content.
/// WebView is created once in makeUIView and survives view updates.
struct HtmlWebView: UIViewRepresentable {
    let html: String?
    let url: String?
    let config: HtmlConfig

    func makeCoordinator() -> Coordinator {
        Coordinator()
    }

    func makeUIView(context: Context) -> WKWebView {
        let configuration = WKWebViewConfiguration()

        // JavaScript
        let webpagePreferences = WKWebpagePreferences()
        webpagePreferences.allowsContentJavaScript = config.javascriptEnabled
        configuration.defaultWebpagePreferences = webpagePreferences

        // Inline media playback
        configuration.allowsInlineMediaPlayback = true
        configuration.mediaTypesRequiringUserActionForPlayback = []

        // Inject viewport meta tag to prevent text zoom / auto-sizing
        // (iOS equivalent of Android's textZoom = 100)
        let viewportScript = WKUserScript(
            source: """
                var meta = document.createElement('meta');
                meta.name = 'viewport';
                meta.content = 'width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no';
                document.head.appendChild(meta);
                """,
            injectionTime: .atDocumentEnd,
            forMainFrameOnly: true
        )
        configuration.userContentController.addUserScript(viewportScript)

        // Try to inject CleverTap JS bridge
        HtmlJsBridge.tryInjectBridge(userContentController: configuration.userContentController)

        let webView = WKWebView(frame: .zero, configuration: configuration)
        webView.navigationDelegate = context.coordinator

        // Scroll behavior (aligned with CT Core SDK — no bounce)
        webView.scrollView.isScrollEnabled = config.scrollEnabled
        webView.scrollView.showsVerticalScrollIndicator = config.scrollEnabled
        webView.scrollView.showsHorizontalScrollIndicator = config.scrollEnabled
        webView.scrollView.bounces = false

        // Transparent background
        if config.transparentBackground {
            webView.isOpaque = false
            webView.backgroundColor = UIColor.clear
            webView.scrollView.backgroundColor = UIColor.clear
        }

        // Disable zoom (pinch-to-zoom)
        webView.scrollView.minimumZoomScale = 1.0
        webView.scrollView.maximumZoomScale = 1.0

        return webView
    }

    func updateUIView(_ webView: WKWebView, context: Context) {
        // html takes priority over url
        if let html = html, !html.isEmpty {
            let baseURL = config.baseUrl.flatMap { URL(string: $0) }
            let finalHtml = Self.wrapHtmlWithResponsiveSizing(html)
            webView.loadHTMLString(finalHtml, baseURL: baseURL)
        } else if let urlString = url, !urlString.isEmpty, let requestUrl = URL(string: urlString) {
            webView.load(URLRequest(url: requestUrl))
        }
    }

    /// Wraps inline HTML with responsive body sizing to fill the WebView dimensions.
    /// Follows the Core SDK pattern of injecting body sizing styles so content
    /// fills the allocated space.
    private static func wrapHtmlWithResponsiveSizing(_ html: String) -> String {
        let responsiveStyle = "<style>body{margin:0;padding:0;width:100%;height:100%;}</style>" +
            "<meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>"

        if html.range(of: "<head>", options: .caseInsensitive) != nil {
            // Inject into existing <head>
            return html.replacingOccurrences(
                of: "<head>",
                with: "<head>\(responsiveStyle)",
                options: .caseInsensitive,
                range: html.range(of: "<head>", options: .caseInsensitive)
            )
        } else if html.range(of: "<!DOCTYPE", options: .caseInsensitive) != nil ||
                    html.range(of: "<html", options: .caseInsensitive) != nil {
            // Full document without <head> — prepend styles
            return "\(responsiveStyle)\(html)"
        } else {
            // HTML fragment — wrap in full document
            return "<!DOCTYPE html><html><head>\(responsiveStyle)</head><body>\(html)</body></html>"
        }
    }

    static func dismantleUIView(_ webView: WKWebView, coordinator: Coordinator) {
        webView.stopLoading()
        webView.load(URLRequest(url: URL(string: "about:blank")!))
        webView.navigationDelegate = nil
    }

    /// Coordinator acts as WKNavigationDelegate to block in-view navigation.
    class Coordinator: NSObject, WKNavigationDelegate {
        func webView(
            _ webView: WKWebView,
            decidePolicyFor navigationAction: WKNavigationAction,
            decisionHandler: @escaping (WKNavigationActionPolicy) -> Void
        ) {
            // Allow initial page loads and same-document navigations
            if navigationAction.navigationType == .other {
                decisionHandler(.allow)
                return
            }

            // Block navigation — open links externally
            if let url = navigationAction.request.url {
                UIApplication.shared.open(url)
            }
            decisionHandler(.cancel)
        }
    }
}
#endif
