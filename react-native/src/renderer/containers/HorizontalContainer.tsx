import React from 'react';
import { View } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import { resolveArrangement } from '../arrangement';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';

interface HorizontalContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

export function HorizontalContainer({
  node,
  resolvedStyle,
  resolvedStyles,
  actionHandler,
  RenderNode,
}: HorizontalContainerProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};

  const arrangement = layout.arrangement ?? { strategy: 'spaced' };
  const arrangementStyle = resolveArrangement(arrangement, 'row');
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  const dividerConfig = node.dividerConfig;
  const children = node.children;

  const childElements: React.ReactNode[] = [];
  children.forEach((child, index) => {
    childElements.push(
      <RenderNode
        key={child.id}
        node={child}
        resolvedStyles={resolvedStyles}
        actionHandler={actionHandler}
      />,
    );

    if (dividerConfig && index < children.length - 1) {
      childElements.push(
        <View
          key={`divider-${index}`}
          style={{
            height: '100%',
            width: dividerConfig.thickness,
            backgroundColor: parseColor(dividerConfig.color) ?? '#CCCCCC',
          }}
        />,
      );
    }
  });

  return (
    <View
      style={[
        layoutStyle,
        nodeStyle,
        {
          flexDirection: arrangementStyle.flexDirection,
          justifyContent: arrangementStyle.justifyContent,
          alignItems: arrangementStyle.alignItems,
          gap: arrangementStyle.gap,
        },
      ]}
    >
      {childElements}
    </View>
  );
}
