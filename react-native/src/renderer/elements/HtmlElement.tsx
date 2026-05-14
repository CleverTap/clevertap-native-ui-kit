import React from 'react';
import { Linking } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getWebView } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';

interface HtmlElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

// JS shim injected into the WebView to send CT events back to RN
const CT_SHIM = `
(function() {
  window.__ct_nd = {
    postMessage: function(type, data) {
      if (window.ReactNativeWebView) {
        window.ReactNativeWebView.postMessage(JSON.stringify({ type: type, data: data }));
      }
    }
  };
  true;
})();
`;

// Meta and style tags injected around inline HTML to make it responsive - matches Android HtmlRenderer.wrapHtmlWithResponsiveSizing()
const RESPONSIVE_META = `<meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>`;
const RESPONSIVE_STYLE = `<style>html,body{margin:0;padding:0;width:100%;height:100%;}</style>`;

function wrapHtml(html: string): string {
  // Has a <head> tag - insert just before </head>
  if (/<head[\s>]/i.test(html)) {
    return html.replace(/<\/head>/i, `${RESPONSIVE_META}${RESPONSIVE_STYLE}</head>`);
  }
  // Has <html> but no <head> - prepend (the browser will create <head> automatically)
  if (/<html[\s>]/i.test(html)) {
    return html.replace(/<html[^>]*>/i, (match) => `${match}${RESPONSIVE_META}${RESPONSIVE_STYLE}`);
  }
  // Bare HTML fragment - wrap it in a minimal document
  return `<!DOCTYPE html><html><head>${RESPONSIVE_META}${RESPONSIVE_STYLE}</head><body>${html}</body></html>`;
}

export const HtmlElement = React.memo(function HtmlElement({ node, resolvedStyle: _resolvedStyle }: HtmlElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const WebView = getWebView();

  if (!WebView) {
    console.warn('[HtmlElement] HTML element requires react-native-webview peer dependency. Element will not render.');
    return null;
  }

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);

  if (!layout.height || layout.height.special === 'wrap_content') {
    console.warn('[HtmlElement] HTML element requires an explicit layout.height. wrap_content is not supported and may result in a zero-height WebView.');
  }

  const htmlConfig = node.htmlConfig;
  const inlineHtml = node.bindings?.html;
  const url = node.bindings?.url;

  const baseUrl = htmlConfig?.baseUrl;
  const javascriptEnabled = htmlConfig?.javascriptEnabled !== false;
  const scrollEnabled = htmlConfig?.scrollEnabled !== false;
  const transparentBackground = htmlConfig?.transparentBackground ?? false;

  // Block navigation inside the WebView and open links in the system browser instead.
  // Matches Android WebViewClient.shouldOverrideUrlLoading() and iOS WKNavigationDelegate.
  const handleShouldStartLoad = ({ url: requestUrl, navigationType }: { url: string; navigationType?: string }) => {
    // Allow the initial load of the configured content
    if (requestUrl === 'about:blank') return true;
    if (inlineHtml && (requestUrl === baseUrl || !requestUrl || navigationType === 'other')) return true;

    // Block all other navigation and open the URL in the system browser
    Linking.openURL(requestUrl).catch(() => {
      console.warn('[HtmlElement] Could not open URL externally:', requestUrl);
    });
    return false;
  };

  const commonProps = {
    javaScriptEnabled: javascriptEnabled,
    scrollEnabled,
    injectedJavaScript: CT_SHIM,
    backgroundColor: transparentBackground ? 'transparent' : undefined,
    // Disable zoom - matches Android setSupportZoom(false) and iOS min/maxZoomScale=1
    scalesPageToFit: false,
    // Disable bounce - matches Android OVER_SCROLL_NEVER and iOS bounces=false
    bounces: false,
    overScrollMode: 'never' as const,
    // Block in-WebView navigation
    onShouldStartLoadWithRequest: handleShouldStartLoad,
  };

  if (inlineHtml) {
    return (
      <WebView
        style={layoutStyle}
        source={{ html: wrapHtml(inlineHtml), baseUrl }}
        {...commonProps}
      />
    );
  }

  if (url) {
    return (
      <WebView
        style={layoutStyle}
        source={{ uri: url }}
        {...commonProps}
      />
    );
  }

  return null;
});
