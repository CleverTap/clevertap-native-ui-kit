import React from 'react';
import { View } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';

interface DividerElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

export const DividerElement = React.memo(function DividerElement({ node, resolvedStyle }: DividerElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const dividerConfig = node.dividerConfig;

  const color = parseColor(dividerConfig?.color ?? resolvedStyle.borderColor ?? '#E0E0E0');
  const thickness = dividerConfig?.thickness ?? 1;

  // Native DividerConfig defaults orientation to horizontal (iOS
  // NativeDisplayNode.swift, Android NativeDisplayNode.kt). Match that. Only an
  // explicit "vertical" makes a vertical divider. No orientation means
  // horizontal.
  const isHorizontalDivider = dividerConfig?.orientation !== 'vertical';

  const dividerStyle = isHorizontalDivider
    ? { width: '100%' as const, height: thickness, backgroundColor: color }
    : { height: '100%' as const, width: thickness, backgroundColor: color };

  return <View style={[layoutStyle, dividerStyle]} />;
});
