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
 * Convert a layout Dimension to an absolute pixel value.
 * Returns undefined for wrap_content so the content can size itself.
 */
function dimensionToPx(dim: Dimension | undefined, parentPx: number): number | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return parentPx;
  if (dim.unit === 'percent') return (parentPx * dim.value) / 100;
  // dp / sp / px - use the value as raw density-independent points
  return dim.value;
}

/**
 * Compute the BOX container's pixel dimensions synchronously, following the
 * same priority order as Android's NativeDisplayRenderer.resolveRootHeightPx():
 *
 *  1. Fixed dp/sp/px height - use the value directly
 *  2. aspectRatio + known width - width / aspectRatio (wins over percent)
 *  3. Percent height + bounded parent - parentHeight x value / 100
 *  4. Parent height
 *  5. Width as fallback (produces a square)
 *
 * This avoids a Yoga trap: when height is "60%" inside an unconstrained
 * ScrollView, Yoga resolves it to 0 before aspectRatio can override it, so
 * onLayout reports height=0 and every child lands at y=0. Computing in JS
 * against the known root dimensions sidesteps Yoga entirely.
 */
function resolveBoxDimensionsPx(
  layout: Layout,
  rootWidth: number,
  rootHeight: number,
): { width: number; height: number } {
  // Width: fixed value, then percent of root, then root width
  const width = dimensionToPx(layout.width, rootWidth) ?? rootWidth;

  const h = layout.height;

  // Priority 1: explicit fixed height (dp / sp / px, no special value)
  if (h && h.special == null && h.unit !== 'percent') {
    return { width, height: h.value };
  }

  // Priority 2: aspectRatio overrides percent height (matches Android renderer line 348-353)
  if (layout.aspectRatio != null && layout.aspectRatio > 0) {
    return { width, height: width / layout.aspectRatio };
  }

  // Priority 3: percent height relative to root height
  if (h?.unit === 'percent' && rootHeight > 0) {
    return { width, height: (rootHeight * h.value) / 100 };
  }

  // Priority 4: fall back to the root height
  if (rootHeight > 0) {
    return { width, height: rootHeight };
  }

  // Priority 5: fall back to a square
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

  // Compute BOX pixel dimensions synchronously using Android's priority order.
  // We remove the `height` style when aspectRatio is set alongside a percent
  // height - the aspectRatio prop handles the visual size correctly, and keeping
  // `height: "60%"` would make Yoga resolve it as 0 in an unconstrained
  // ScrollView axis, which fights the aspectRatio.
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
            // Use the pre-computed pixel dimensions so Yoga never needs to resolve
            // bottom/right constraints against an aspectRatio-derived parent height.
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

        // Child size in pixels (undefined means wrap content along that axis)
        const widthPx = dimensionToPx(childLayout.width, boxSize.width);
        const heightPx = dimensionToPx(childLayout.height, boxSize.height);

        const wrapperStyle: ViewStyle = { position: 'absolute', top, left };
        if (widthPx !== undefined) wrapperStyle.width = widthPx;
        if (heightPx !== undefined) wrapperStyle.height = heightPx;

        // Override the child's own width/height with the resolved pixel values
        // (dp), not "100%". The wrapper already carries the same pixel size,
        // so this is not a double-application: every wrapper in the chain ends
        // up with the same definite pixel size.
        //
        // Why not "100%": iOS RN's text measurement does not reliably chain a
        // width constraint through (wrapper:pixel -> BackgroundRenderer view with
        // no explicit width -> element wrapper: width-100%) into RCTText's
        // measure function. The text gets measured at intrinsic (unbounded) width
        // and renders on a single line, then the outer wrapper's overflow:'hidden'
        // (auto-injected by borderRadius) hard-clips it. Using explicit dp values
        // keeps every step in the chain definite, so Yoga passes a real maxWidth
        // to RCTText.
        //
        // Clear offset here - the wrapper's top/left already places the child.
        // Leaving offset set would cause RenderNode to apply it again as a transform.
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
