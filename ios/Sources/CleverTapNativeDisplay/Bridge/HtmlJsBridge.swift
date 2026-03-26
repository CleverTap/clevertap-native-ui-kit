//
//  HtmlJsBridge.swift
//  CleverTapNativeDisplay
//

// MARK: - HTML JavaScript Bridge
// Runtime injection of CleverTap JS bridge into WKWebView.
// No compile-time dependency on CleverTap SDK — all interaction via NSClassFromString.

#if os(iOS)
import Foundation
import WebKit

/// Injects the CleverTap JavaScript bridge into a WKWebView's user content controller.
/// If the CleverTap Core SDK is not present at runtime, this is a silent no-op.
internal class HtmlJsBridge {

    /// Attempt to inject the CleverTap JS bridge into the given WKWebView's configuration.
    ///
    /// - Parameter userContentController: The WKUserContentController to register the handler on
    /// - Returns: `true` if injection succeeded
    @discardableResult
    static func tryInjectBridge(userContentController: WKUserContentController) -> Bool {
        // Look for CleverTap's JS interface class
        guard let jsInterfaceClass = NSClassFromString("CleverTapJSInterface") as? NSObject.Type else {
            print("[HtmlJsBridge] CleverTap JS interface not found, skipping bridge injection")
            return false
        }

        // Try to create an instance
        let handler = jsInterfaceClass.init()

        // Verify it conforms to WKScriptMessageHandler
        guard let scriptHandler = handler as? WKScriptMessageHandler else {
            print("[HtmlJsBridge] CleverTap JS interface does not conform to WKScriptMessageHandler")
            return false
        }

        // Register as script message handler
        userContentController.add(scriptHandler, name: "CleverTap")

        print("[HtmlJsBridge] CleverTap JS bridge injected successfully")
        return true
    }
}
#endif
