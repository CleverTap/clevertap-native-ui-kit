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
///
/// On iOS, CleverTapJSInterface uses the WKScriptMessageHandler pattern:
///   `window.webkit.messageHandlers.clevertap.postMessage({action: "recordEventWithProps", ...})`
///
/// To provide cross-platform parity with Android (where `window.CleverTap.pushEvent()` works
/// via addJavascriptInterface), we also inject a JS shim that creates `window.CleverTap` with
/// matching method signatures. This way, the same HTML/JS works on both platforms.
internal class HtmlJsBridge {

    /// Handler name matching the Core SDK's CTInAppHTMLViewController registration (lowercase).
    private static let handlerName = "clevertap"

    /// Attempt to inject the CleverTap JS bridge into the given WKWebView's configuration.
    ///
    /// - Parameter userContentController: The WKUserContentController to register the handler on
    /// - Returns: `true` if injection succeeded
    @discardableResult
    static func tryInjectBridge(userContentController: WKUserContentController) -> Bool {
        // Look for CleverTap's JS interface class
        guard let jsInterfaceClass = NSClassFromString("CleverTapJSInterface") as? NSObject.Type else {
            NDLogger.d("HtmlJsBridge", "CleverTap JS interface not found, skipping bridge injection")
            return false
        }

        // CleverTapJSInterface requires initWithConfig: — try to get the config from the default instance
        // Step 1: Get CleverTap shared instance
        guard let ctClass = NSClassFromString("CleverTap") as? NSObject.Type else {
            NDLogger.w("HtmlJsBridge", "CleverTap class not found")
            return false
        }

        let sharedSelector = NSSelectorFromString("sharedInstance")
        guard ctClass.responds(to: sharedSelector),
              let result = ctClass.perform(sharedSelector),
              let ctInstance = result.takeUnretainedValue() as? NSObject else {
            NDLogger.w("HtmlJsBridge", "Failed to get CleverTap shared instance")
            return false
        }

        // Step 2: Get the instance config
        let configSelector = NSSelectorFromString("config")
        guard ctInstance.responds(to: configSelector),
              let configResult = ctInstance.perform(configSelector),
              let config = configResult.takeUnretainedValue() as? NSObject else {
            NDLogger.w("HtmlJsBridge", "Failed to get CleverTap instance config")
            return false
        }

        // Step 3: Create CleverTapJSInterface with initWithConfig:
        let initWithConfigSelector = NSSelectorFromString("initWithConfig:")
        guard let handler = jsInterfaceClass.perform(NSSelectorFromString("alloc"))?
                .takeUnretainedValue() as? NSObject,
              handler.responds(to: initWithConfigSelector) else {
            NDLogger.w("HtmlJsBridge", "CleverTapJSInterface does not respond to initWithConfig:")
            return false
        }

        guard let initializedHandler = handler.perform(initWithConfigSelector, with: config)?
                .takeUnretainedValue() as? NSObject else {
            NDLogger.w("HtmlJsBridge", "Failed to initialize CleverTapJSInterface with config")
            return false
        }

        // Step 4: Verify it conforms to WKScriptMessageHandler
        guard let scriptHandler = initializedHandler as? WKScriptMessageHandler else {
            NDLogger.w("HtmlJsBridge", "CleverTapJSInterface does not conform to WKScriptMessageHandler")
            return false
        }

        // Step 5: Register as script message handler (lowercase name matches Core SDK)
        userContentController.add(scriptHandler, name: handlerName)

        // Step 6: Inject JS shim for cross-platform parity with Android's window.CleverTap
        let shimScript = WKUserScript(
            source: Self.crossPlatformJsShim,
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        )
        userContentController.addUserScript(shimScript)

        NDLogger.d("HtmlJsBridge", "CleverTap JS bridge injected successfully")
        return true
    }

    /// JavaScript shim that creates `window.CleverTap` on iOS, mapping method calls to
    /// `window.webkit.messageHandlers.clevertap.postMessage()` with the action/payload
    /// format expected by CleverTapJSInterface.
    ///
    /// This provides the same API surface as Android's addJavascriptInterface:
    ///   - window.CleverTap.pushEvent(name)
    ///   - window.CleverTap.pushEvent(name, props)
    ///   - window.CleverTap.pushProfile(profile)
    ///   - window.CleverTap.pushChargedEvent(details, items)
    ///   - window.CleverTap.onUserLogin(profile)
    ///   - window.CleverTap.dismissInAppNotification()
    ///   - window.CleverTap.promptForPushPermission(showFallback)
    private static let crossPlatformJsShim = """
    (function() {
        if (window.CleverTap) return;
        var _post = function(msg) {
            if (window.webkit && window.webkit.messageHandlers && window.webkit.messageHandlers.clevertap) {
                window.webkit.messageHandlers.clevertap.postMessage(msg);
            }
        };
        window.CleverTap = {
            pushEvent: function(name, props) {
                _post({action: 'recordEventWithProps', event: name, properties: props || {}});
            },
            pushProfile: function(profile) {
                _post({action: 'profilePush', properties: profile});
            },
            pushChargedEvent: function(details, items) {
                _post({action: 'recordChargedEvent', chargeDetails: details, items: items});
            },
            onUserLogin: function(profile) {
                _post({action: 'onUserLogin', properties: profile});
            },
            profileSetMultiValues: function(key, values) {
                _post({action: 'profileSetMultiValues', key: key, values: values});
            },
            profileAddMultiValue: function(key, value) {
                _post({action: 'profileAddMultiValue', key: key, value: value});
            },
            profileAddMultiValues: function(key, values) {
                _post({action: 'profileAddMultiValues', key: key, values: values});
            },
            profileRemoveMultiValue: function(key, value) {
                _post({action: 'profileRemoveMultiValue', key: key, value: value});
            },
            profileRemoveMultiValues: function(key, values) {
                _post({action: 'profileRemoveMultiValues', key: key, values: values});
            },
            profileIncrementValueBy: function(key, value) {
                _post({action: 'profileIncrementValueBy', key: key, value: value});
            },
            profileDecrementValueBy: function(key, value) {
                _post({action: 'profileDecrementValueBy', key: key, value: value});
            },
            dismissInAppNotification: function() {
                _post({action: 'dismissInAppNotification'});
            },
            promptForPushPermission: function(showFallback) {
                _post({action: 'promptForPushPermission', showFallbackSettings: showFallback || false});
            }
        };
    })();
    """
}
#endif
