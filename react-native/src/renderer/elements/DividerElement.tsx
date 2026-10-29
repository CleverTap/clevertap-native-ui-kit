import React from 'react';
import { View } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';

interface DividerElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

export const DividerElement = React.memo(function DividerElement({ node, resolvedStyle }: DividerElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  // Run the same style pass every other element runs. It paints
  // backgroundColor, border, and corner radius. On iOS these come from a
  // generic decoration wrapper that sits around every node. RN has no such
  // wrapper, so the element applies them itself. Without this the divider
  // ignored its own backgroundColor and layout height.
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);
  const dividerConfig = node.dividerConfig;

  // The divider line. iOS always draws it. DividerConfig defaults are
  // horizontal orientation, thickness 1, and no color. The color falls back to
  // the node border color and then a light gray.
  const lineColor = parseColor(dividerConfig?.color ?? resolvedStyle.borderColor ?? '#E0E0E0');
  const thickness = dividerConfig?.thickness ?? 1;

  // DividerConfig orientation defaults to horizontal in both native SDKs
  // (iOS NativeDisplayNode.swift, Android NativeDisplayNode.kt). Only an
  // explicit "vertical" makes a vertical divider. No orientation means
  // horizontal.
  const isHorizontalDivider = dividerConfig?.orientation !== 'vertical';

  const lineStyle = isHorizontalDivider
    ? { width: '100%' as const, height: thickness, backgroundColor: lineColor }
    : { height: '100%' as const, width: thickness, backgroundColor: lineColor };

  // The outer box carries the element's own size (layout.width / layout.height)
  // and its background. The line sits centered inside it. This matches iOS: the
  // line is `thickness` thick and the colored band fills the layout size.
  return (
    <View style={[layoutStyle, nodeStyle, { alignItems: 'center', justifyContent: 'center' }]}>
      <View style={lineStyle} />
    </View>
  );
});
