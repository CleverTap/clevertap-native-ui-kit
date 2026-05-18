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
  // Symmetric companion to the width pin below. iOS Fabric resolves `height: '100%'`
  // on absolute children against the parent's intrinsic content height, not the
  // parent's actual rendered (wrap_content) height - so the bg ends short of the
  // tallest flow child. We measure the container post-layout and feed the pixel
  // value back as the bg's explicit height. First render falls back to '100%'
  // (possibly wrong); the second render after onLayout is correct.
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

  // iOS Yoga collapses `width: '100%'` to wrap_content when the parent's
  // cross-axis size is established via `alignItems: 'stretch'` (the default)
  // rather than a definite width - even when the parent has an explicit
  // pixel width set, the resolution chain breaks once Fabric is involved.
  // We sidestep Yoga entirely by substituting an explicit pixel width from
  // `useRootSize()`, the same trick `BoxContainer` uses for its children.
  //
  // For nested containers with width: '100%', `rootWidth` may exceed the
  // immediate parent's width, but in practice nested containers either use
  // wrap_content or explicit widths - 100% nested is rare. The overflow is
  // visible (no crash) and surfaces the misuse during testing.
  //
  // wrap_content containers (no width, no flex) still need `alignSelf: 'stretch'`
  // so that `alignItems: 'flex-start'` on a flex parent doesn't collapse them.
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
    <View
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
          // For absolute children, iOS Fabric resolves `width: '100%'` against
          // the parent's INTRINSIC content width (= the flex children's wrap_content
          // size), NOT the parent's explicit `width` prop. So even though the
          // VerticalContainer View renders at e.g. 420dp wide, a bg child with
          // `width: '100%'` collapses to the text's ~290dp intrinsic width.
          // When we know the container's pixel width (isFullWidth case, where we
          // substituted rootWidth above), pass that same pixel value here.
          // For wrap_content/nested cases we fall back to '100%' - imperfect but
          // those cases don't expose the absolute-percent-resolution bug.
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
    </View>
  );
});
