import React, { useState } from 'react';
import { View } from 'react-native';
import type { LayoutChangeEvent, ViewStyle } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import { resolveArrangement } from '../arrangement';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { parseColor } from '../../utils/color';
import { useRootSize } from '../../context/RootSizeContext';
import { BackgroundRenderer } from '../BackgroundRenderer';
import { TappableContainer } from '../TappableContainer';

interface VerticalContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

export const VerticalContainer = React.memo(function VerticalContainer({
  node,
  resolvedStyle,
  resolvedStyles,
  actionHandler,
  RenderNode,
}: VerticalContainerProps): React.ReactElement {
  const { width: rootWidth, height: rootHeight } = useRootSize();
  // Goes with the width pin below. On iOS, `height: '100%'` on an absolute
  // child measures against the parent's content height, not its rendered
  // height, so the background comes up short. We measure after layout and pass
  // that pixel height back. First render uses '100%' (maybe wrong), second
  // render after onLayout is correct.
  const [measuredHeight, setMeasuredHeight] = useState<number | null>(null);
  const handleContainerLayout = (e: LayoutChangeEvent): void => {
    const h = e.nativeEvent.layout.height;
    setMeasuredHeight((prev) => (prev === h ? prev : h));
  };
  const layout = node.layout ?? {};

  const arrangement = layout.arrangement ?? { strategy: 'spaced' };
  const arrangementStyle = resolveArrangement(arrangement, 'column');
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
            width: '100%',
            height: dividerConfig.thickness,
            backgroundColor: parseColor(dividerConfig.color) ?? '#CCCCCC',
          }}
        />,
      );
    }
  });

  // On iOS, `width: '100%'` collapses to wrap_content when the parent stretches
  // its children (the default) instead of having a fixed width. So we swap in an
  // explicit pixel width from useRootSize(), the same trick BoxContainer uses.
  //
  // For nested "100%" containers rootWidth may be wider than the real parent,
  // but that combo is rare and just overflows visibly (no crash), which flags
  // the misuse in testing.
  //
  // wrap_content containers (no width, no flex) still need alignSelf: 'stretch'
  // so a flex-start parent doesn't collapse them.
  const { width: _w, flexShrink: _fs, ...layoutWithoutWidth } = layoutStyle;
  const isFullWidth = layoutStyle.width === '100%';
  const finalLayoutStyle: ViewStyle = isFullWidth
    ? { ...layoutWithoutWidth, width: rootWidth }
    : layoutStyle;
  const widthStyle =
    !isFullWidth && !layoutStyle.width && layoutStyle.flex == null
      ? { alignSelf: 'stretch' as const }
      : undefined;

  return (
    <TappableContainer
      node={node}
      actionHandler={actionHandler}
      onLayout={handleContainerLayout}
      style={[
        finalLayoutStyle,
        nodeStyle,
        {
          flexDirection: arrangementStyle.flexDirection,
          justifyContent: arrangementStyle.justifyContent,
          alignItems: arrangementStyle.alignItems,
          gap: arrangementStyle.gap,
        },
        widthStyle,
      ]}
    >
      {resolvedStyle.background && (
        <BackgroundRenderer
          background={resolvedStyle.background}
          // On iOS, `width: '100%'` on an absolute child measures against the
          // parent's content width (its children's wrap_content size), not its
          // real width, so the background gets truncated. When we know the pixel
          // width (isFullWidth case), pass that; otherwise fall back to '100%',
          // which is fine for the wrap_content/nested cases.
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            width: isFullWidth ? rootWidth : '100%',
            height: measuredHeight ?? '100%',
          }}
        >
          {null}
        </BackgroundRenderer>
      )}
      {childElements}
    </TappableContainer>
  );
});
