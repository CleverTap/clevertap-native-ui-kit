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
  containerDirection?: 'row' | 'column';
}

export function DividerElement({ node, resolvedStyle, containerDirection }: DividerElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const dividerConfig = node.dividerConfig;

  const color = parseColor(dividerConfig?.color ?? resolvedStyle.borderColor ?? '#CCCCCC');
  const thickness = dividerConfig?.thickness ?? 1;

  const isHorizontalDivider =
    dividerConfig?.orientation === 'horizontal' ||
    (!dividerConfig?.orientation && containerDirection === 'column');

  const dividerStyle = isHorizontalDivider
    ? { width: '100%' as const, height: thickness, backgroundColor: color }
    : { height: '100%' as const, width: thickness, backgroundColor: color };

  return <View style={[layoutStyle, dividerStyle]} />;
}
