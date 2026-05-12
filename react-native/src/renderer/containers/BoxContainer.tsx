import React from 'react';
import { View } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import { resolveLayoutStyle, resolveNodeStyle, resolveOffsetStyle } from '../layoutModifier';
import { useRootSize } from '../../context/RootSizeContext';

interface BoxContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

export function BoxContainer({
  node,
  resolvedStyle,
  resolvedStyles,
  actionHandler,
  RenderNode,
}: BoxContainerProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};

  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  return (
    <View style={[layoutStyle, nodeStyle, { position: 'relative' }]}>
      {node.children.map((child) => {
        const childLayout = child.layout ?? {};
        const offset = childLayout.offset;
        const transform = offset
          ? [
              { translateX: resolveOffsetStyle(offset).translateX },
              { translateY: resolveOffsetStyle(offset).translateY },
            ]
          : undefined;

        return (
          <View
            key={child.id}
            style={[
              { position: 'absolute', top: 0, left: 0 },
              transform ? { transform } : undefined,
            ]}
          >
            <RenderNode
              node={child}
              resolvedStyles={resolvedStyles}
              actionHandler={actionHandler}
            />
          </View>
        );
      })}
    </View>
  );
}
