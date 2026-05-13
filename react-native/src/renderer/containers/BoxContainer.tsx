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
import { useRootSize } from '../../context/RootSizeContext';

interface BoxContainerProps {
  node: NativeDisplayContainer;
  resolvedStyle: Partial<Style>;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  RenderNode: React.ComponentType<RenderNodeProps>;
}

/**
 * Converts a layout Dimension to an absolute pixel value.
 * Returns undefined for wrap_content (let content size itself).
 */
function dimensionToPx(dim: Dimension | undefined, parentPx: number): number | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return parentPx;
  if (dim.unit === 'percent') return (parentPx * dim.value) / 100;
  // dp / sp / px — treat as raw density-independent points
  return dim.value;
}

/**
 * Resolves the BOX container's pixel dimensions synchronously, mirroring
 * Android's NativeDisplayRenderer.resolveRootHeightPx() priority order:
 *
 *  1. Fixed dp/sp/px height → direct value
 *  2. aspectRatio + known width → width / aspectRatio   ← wins over percent
 *  3. Percent height + bounded parent → parentHeight × value / 100
 *  4. Parent height
 *  5. Width fallback (square)
 *
 * This avoids the onLayout trap: when height:"60%" lives inside an
 * unconstrained ScrollView, Yoga resolves it as 0 before aspectRatio can
 * override it, so onLayout reports height=0 and every child lands at y=0.
 * Computing in JS against the known root dimensions bypasses Yoga entirely.
 */
function resolveBoxDimensionsPx(
  layout: Layout,
  rootWidth: number,
  rootHeight: number,
): { width: number; height: number } {
  // Width: fixed → percent of root → root width
  const width = dimensionToPx(layout.width, rootWidth) ?? rootWidth;

  const h = layout.height;

  // Priority 1: explicit fixed height (dp / sp / px, no special)
  if (h && h.special == null && h.unit !== 'percent') {
    return { width, height: h.value };
  }

  // Priority 2: aspectRatio overrides percent height (matches Android line 348-353)
  if (layout.aspectRatio != null && layout.aspectRatio > 0) {
    return { width, height: width / layout.aspectRatio };
  }

  // Priority 3: percent height relative to root height
  if (h?.unit === 'percent' && rootHeight > 0) {
    return { width, height: (rootHeight * h.value) / 100 };
  }

  // Priority 4: root height
  if (rootHeight > 0) {
    return { width, height: rootHeight };
  }

  // Priority 5: square fallback
  return { width, height: width };
}

export function BoxContainer({
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
  // We suppress the `height` style when aspectRatio is set alongside a percent
  // height — the aspectRatio prop handles the visual size correctly, and keeping
  // `height: "60%"` would make Yoga resolve it as 0 in an unconstrained
  // ScrollView axis, fighting the aspectRatio.
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
      {node.children.map((child) => {
        const childLayout = child.layout ?? {};
        const offset = childLayout.offset;

        // Child position (top-left corner within the BOX)
        let top = 0;
        let left = 0;
        if (offset) {
          if (offset.unit === 'percent') {
            top = (boxSize.height * offset.y) / 100;
            left = (boxSize.width * offset.x) / 100;
          } else {
            // dp / sp / px — raw values
            top = offset.y;
            left = offset.x;
          }
        }

        // Child dimensions in px (undefined = wrap content along that axis)
        const widthPx = dimensionToPx(childLayout.width, boxSize.width);
        const heightPx = dimensionToPx(childLayout.height, boxSize.height);

        const wrapperStyle: ViewStyle = { position: 'absolute', top, left };
        if (widthPx !== undefined) wrapperStyle.width = widthPx;
        if (heightPx !== undefined) wrapperStyle.height = heightPx;

        // Override child's own width/height to the resolved PIXEL dimensions
        // (dp), not "100%". The wrapper already carries the same pixel size,
        // so this is not a double-application: every wrapper down the chain
        // ends up with the same definite pixel size.
        //
        // Why not "100%": iOS RN's text measurement does not reliably chain
        // a width constraint through (wrapper:pixel → BackgroundRenderer-view:
        // no-explicit-width-just-stretch → element-wrapper:width-100%) into
        // RCTText's measure function. The text gets measured at intrinsic
        // (unbounded) width and renders single-line, then the outer wrapper's
        // overflow:'hidden' (auto-injected by borderRadius) hard-clips it.
        // Substituting explicit dp values keeps every link in the chain
        // "definite" so Yoga passes a real maxWidth into RCTText.
        //
        // Clear offset — the wrapper's top/left already places the child;
        // leaving offset set would cause RenderNode to double-apply it as a
        // transform.
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
}
