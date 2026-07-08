import React from 'react';
import { Linking } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getWebView } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';
import { NDLogger } from '../../internal/NDLogger';

interface HtmlElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

// JS injected into the WebView so page content can send CT events back to RN.
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

// Meta/style tags added to inline HTML to make it responsive (matches Android).
const RESPONSIVE_META = `<meta name='viewport' content='width=device-width,initial-scale=1.0,maximum-scale=1.0,user-scalable=no'>`;
const RESPONSIVE_STYLE = `<style>html,body{margin:0;padding:0;width:100%;height:100%;}</style>`;

function wrapHtml(html: string): string {
  // Has a <head> - insert just before </head>.
  if (/<head[\s>]/i.test(html)) {
    return html.replace(/<\/head>/i, `${RESPONSIVE_META}${RESPONSIVE_STYLE}</head>`);
  }
  // Has <html> but no <head> - insert right after the <html> tag.
  if (/<html[\s>]/i.test(html)) {
    return html.replace(/<html[^>]*>/i, (match) => `${match}${RESPONSIVE_META}${RESPONSIVE_STYLE}`);
  }
  // Bare fragment - wrap it in a minimal document.
  return `<!DOCTYPE html><html><head>${RESPONSIVE_META}${RESPONSIVE_STYLE}</head><body>${html}</body></html>`;
}

export const HtmlElement = React.memo(function HtmlElement({ node, resolvedStyle: _resolvedStyle }: HtmlElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const WebView = getWebView();

  if (!WebView) {
    NDLogger.w('HtmlElement', 'HTML element requires react-native-webview peer dependency. Element will not render.');
    return null;
  }

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);

  if (!layout.height || layout.height.special === 'wrap_content') {
    NDLogger.w('HtmlElement', 'HTML element requires an explicit layout.height. wrap_content is not supported and may result in a zero-height WebView.');
  }

  const htmlConfig = node.htmlConfig;
  const inlineHtml = node.bindings?.html;
  const url = node.bindings?.url;

  const baseUrl = htmlConfig?.baseUrl;
  const javascriptEnabled = htmlConfig?.javascriptEnabled !== false;
  const scrollEnabled = htmlConfig?.scrollEnabled !== false;
  const transparentBackground = htmlConfig?.transparentBackground ?? false;

  // Keep the WebView from navigating; open links in the system browser instead
  // (matches Android and iOS).
  const handleShouldStartLoad = ({ url: requestUrl, navigationType }: { url: string; navigationType?: string }) => {
    // Allow the initial content load.
    if (requestUrl === 'about:blank') return true;
    if (inlineHtml && (requestUrl === baseUrl || !requestUrl || navigationType === 'other')) return true;

    // Block anything else and open it externally.
    Linking.openURL(requestUrl).catch(() => {
      NDLogger.w('HtmlElement', 'Could not open URL externally:', requestUrl);
    });
    return false;
  };

  const commonProps = {
    javaScriptEnabled: javascriptEnabled,
    scrollEnabled,
    injectedJavaScript: CT_SHIM,
    backgroundColor: transparentBackground ? 'transparent' : undefined,
    // Disable zoom (matches native).
    scalesPageToFit: false,
    // Disable bounce/overscroll (matches native).
    bounces: false,
    overScrollMode: 'never' as const,
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
