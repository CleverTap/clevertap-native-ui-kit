import React from 'react';
import { View } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { NativeDisplayContainer } from '../../models/NativeDisplayNode';
import type { Dimension, Layout } from '../../models/Layout';
import type { Style } from '../../models/Style';
import type { ResolvedStyles } from '../../models/NativeDisplayConfig';
import type { ActionHandler } from '../../handler/ActionHandler';
import type { RenderNodeProps } from '../types';
import {
  resolveLayoutStyle,
  resolveNodeStyle,
} from '../layoutModifier';
import { BackgroundRenderer } from '../BackgroundRenderer';
import { useRootSize } from '../../context/RootSizeContext';

interface BoxContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

/**
 * Turn a layout Dimension into a pixel number.
 * Returns undefined for wrap_content so the content sizes itself.
 */
function dimensionToPx(dim: Dimension | undefined, parentPx: number): number | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return parentPx;
  if (dim.unit === 'percent') return (parentPx * dim.value) / 100;
  // dp / sp / px - use the raw value
  return dim.value;
}

/**
 * Work out the BOX pixel size in JS, using the same priority order as Android:
 *  1. Fixed dp/sp/px height
 *  2. aspectRatio + known width (beats percent)
 *  3. Percent height of the parent
 *  4. Parent height
 *  5. Width (makes a square)
 *
 * Why compute it here instead of letting Yoga do it: a "60%" height inside an
 * unbounded ScrollView resolves to 0 before aspectRatio can kick in, so every
 * child ends up at y=0. Doing the math against the known root size avoids that.
 */
function resolveBoxDimensionsPx(
  layout: Layout,
  rootWidth: number,
  rootHeight: number,
): { width: number; height: number } {
  // Width: fixed value, then percent of root, then root width
  const width = dimensionToPx(layout.width, rootWidth) ?? rootWidth;

  const h = layout.height;

  // 1. Fixed height
  if (h && h.special == null && h.unit !== 'percent') {
    return { width, height: h.value };
  }

  // 2. aspectRatio beats percent height
  if (layout.aspectRatio != null && layout.aspectRatio > 0) {
    return { width, height: width / layout.aspectRatio };
  }

  // 3. Percent of root height
  if (h?.unit === 'percent' && rootHeight > 0) {
    return { width, height: (rootHeight * h.value) / 100 };
  }

  // 4. Root height
  if (rootHeight > 0) {
    return { width, height: rootHeight };
  }

  // 5. Square
  return { width, height: width };
}

export const BoxContainer = React.memo(function BoxContainer({
  node,
  resolvedStyle,
  resolvedStyles,
  actionHandler,
  RenderNode,
}: BoxContainerProps): React.ReactElement {
  const { width: rootWidth, height: rootHeight } = useRootSize();
  const layout = node.layout ?? {};

  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  // Drop the `height` style when aspectRatio is set with a percent height.
  // aspectRatio already sizes it, and keeping `height: "60%"` makes Yoga
  // resolve it to 0 in an unbounded ScrollView, fighting the aspectRatio.
  const boxStyle: ViewStyle = { ...layoutStyle, ...nodeStyle, position: 'relative' };
  if (
    layout.aspectRatio != null &&
    layout.aspectRatio > 0 &&
    layout.height?.unit === 'percent'
  ) {
    delete (boxStyle as Record<string, unknown>).height;
  }

  const boxSize = resolveBoxDimensionsPx(layout, rootWidth, rootHeight);

  return (
    <View style={boxStyle}>
      {resolvedStyle.background && (
        <BackgroundRenderer
          background={resolvedStyle.background}
          style={{
            position: 'absolute',
            top: 0,
            left: 0,
            // Use the pixel size we already computed so Yoga never has to
            // resolve bottom/right against an aspectRatio-derived height.
            width: boxSize.width,
            height: boxSize.height,
          }}
        >
          {null}
        </BackgroundRenderer>
      )}
      {node.children.map((child) => {
        const childLayout = child.layout ?? {};
        const offset = childLayout.offset;

        // Position of the child's top-left corner within the BOX
        let top = 0;
        let left = 0;
        if (offset) {
          if (offset.unit === 'percent') {
            top = (boxSize.height * offset.y) / 100;
            left = (boxSize.width * offset.x) / 100;
          } else {
            // dp / sp / px - use the raw values
            top = offset.y;
            left = offset.x;
          }
        }

        // Child size in pixels (undefined = wrap content on that axis)
        const widthPx = dimensionToPx(childLayout.width, boxSize.width);
        const heightPx = dimensionToPx(childLayout.height, boxSize.height);

        const wrapperStyle: ViewStyle = { position: 'absolute', top, left };
        if (widthPx !== undefined) wrapperStyle.width = widthPx;
        if (heightPx !== undefined) wrapperStyle.height = heightPx;

        // Give the child an explicit pixel width/height, not "100%". The
        // wrapper already has the same pixel size, so it's not applied twice.
        //
        // Why not "100%": on iOS, a chain of percent widths does not reliably
        // pass a real width down to the text measurer, so text measures at its
        // natural width, renders on one line, and gets clipped by the
        // borderRadius overflow:hidden. Explicit pixels keep every step definite.
        //
        // Clear offset - the wrapper's top/left already positions the child, so
        // leaving it would make RenderNode apply it a second time.
        const overriddenLayout = {
          ...childLayout,
          offset: undefined,
          ...(widthPx !== undefined
            ? { width: { value: widthPx, unit: 'dp' as const, special: null } }
            : {}),
          ...(heightPx !== undefined
            ? { height: { value: heightPx, unit: 'dp' as const, special: null } }
            : {}),
        };
        const childForRender = { ...child, layout: overriddenLayout };

        return (
          <View key={child.id} style={wrapperStyle}>
            <RenderNode
              node={childForRender}
              resolvedStyles={resolvedStyles}
              actionHandler={actionHandler}
            />
          </View>
        );
      })}
    </View>
  );
});
