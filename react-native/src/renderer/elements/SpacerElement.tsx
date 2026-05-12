import React from 'react';
import { View } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { resolveLayoutStyle, MATCH_PARENT_MARKER, resolveDimension } from '../layoutModifier';
import { useRootSize } from '../../context/RootSizeContext';

interface SpacerElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

export function SpacerElement({ node, resolvedStyle }: SpacerElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);

  const widthRaw = resolveDimension(layout.width);
  const heightRaw = resolveDimension(layout.height);

  const hasExplicitSize = (widthRaw !== undefined && widthRaw !== MATCH_PARENT_MARKER)
    || (heightRaw !== undefined && heightRaw !== MATCH_PARENT_MARKER);
  const isFlex = widthRaw === MATCH_PARENT_MARKER || heightRaw === MATCH_PARENT_MARKER;

  // Default to flex:1 when no explicit size given (spacer fills remaining space)
  const style = hasExplicitSize
    ? layoutStyle
    : { ...layoutStyle, flex: 1 };

  return <View style={style} />;
}
