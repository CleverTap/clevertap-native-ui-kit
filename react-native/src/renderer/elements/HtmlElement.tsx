import React from 'react';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getWebView } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';

interface HtmlElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

// Injected JS shim to dispatch CT events back to RN
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

export function HtmlElement({ node, resolvedStyle }: HtmlElementProps): React.ReactElement | null {
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

  if (inlineHtml) {
    return (
      <WebView
        style={layoutStyle}
        source={{ html: inlineHtml, baseUrl }}
        javaScriptEnabled={javascriptEnabled}
        scrollEnabled={scrollEnabled}
        injectedJavaScript={CT_SHIM}
        backgroundColor={transparentBackground ? 'transparent' : undefined}
      />
    );
  }

  if (url) {
    return (
      <WebView
        style={layoutStyle}
        source={{ uri: url }}
        javaScriptEnabled={javascriptEnabled}
        scrollEnabled={scrollEnabled}
        injectedJavaScript={CT_SHIM}
        backgroundColor={transparentBackground ? 'transparent' : undefined}
      />
    );
  }

  return null;
}
