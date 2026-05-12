import { Platform } from 'react-native';
import type { ViewStyle, TextStyle } from 'react-native';
import type { Dimension, Layout, Offset, Spacing } from '../models/Layout';
import type { Style } from '../models/Style';
import {
  resolveBorderRadius,
  resolveBorderWidth,
} from '../utils/dimension';
import { parseColor } from '../utils/color';
import { resolveTextDim } from '../utils/dimension';
import {
  resolveSpacingTop,
  resolveSpacingBottom,
  resolveSpacingLeft,
  resolveSpacingRight,
} from '../models/Layout';

export const MATCH_PARENT_MARKER = '__match_parent__';

export function resolveDimension(dim: Dimension | undefined): number | string | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return MATCH_PARENT_MARKER;

  switch (dim.unit) {
    case 'dp':
    case 'sp':
    case 'px':
      return dim.value;
    case 'percent':
      return `${dim.value}%`;
    default:
      return dim.value;
  }
}

export function resolveSpacingStyle(spacing: Spacing): {
  paddingTop: number;
  paddingRight: number;
  paddingBottom: number;
  paddingLeft: number;
} {
  return {
    paddingTop: resolveSpacingTop(spacing),
    paddingRight: resolveSpacingRight(spacing),
    paddingBottom: resolveSpacingBottom(spacing),
    paddingLeft: resolveSpacingLeft(spacing),
  };
}

export function resolveOffsetStyle(offset: Offset): { translateX: number; translateY: number } {
  let x = offset.x;
  let y = offset.y;
  return { translateX: x, translateY: y };
}

export function resolveLayoutStyle(layout: Layout, rootHeightPx: number): ViewStyle {
  const style: ViewStyle = {};

  const width = resolveDimension(layout.width);
  if (width === MATCH_PARENT_MARKER) {
    style.flex = 1;
  } else if (width !== undefined) {
    style.width = width as number | `${number}%`;
    // Explicit dp/px/percent width means this element must hold its stated size.
    // flexShrink: 0 prevents a sibling with wrap_content from pushing it off-screen
    // in a horizontal flex row.
    style.flexShrink = 0;
  }
  // wrap_content (width === undefined) leaves flexShrink at RN's default of 1,
  // so the element can yield space to fixed-size siblings when the row is tight.

  const height = resolveDimension(layout.height);
  if (height === MATCH_PARENT_MARKER) {
    if (!style.flex) style.flex = 1;
  } else if (height !== undefined) {
    style.height = height as number | `${number}%`;
  }

  if (layout.aspectRatio != null) {
    style.aspectRatio = layout.aspectRatio;
  }

  if (layout.padding) {
    const p = resolveSpacingStyle(layout.padding);
    style.paddingTop = p.paddingTop;
    style.paddingRight = p.paddingRight;
    style.paddingBottom = p.paddingBottom;
    style.paddingLeft = p.paddingLeft;
  }

  return style;
}

export function resolveNodeStyle(resolved: Partial<Style>, rootHeightPx: number): ViewStyle & TextStyle {
  const style: ViewStyle & TextStyle = {};

  if (resolved.opacity != null) {
    style.opacity = resolved.opacity;
  }

  if (resolved.backgroundColor) {
    style.backgroundColor = parseColor(resolved.backgroundColor);
  }

  if (resolved.borderRadius) {
    style.borderRadius = resolveBorderRadius(resolved.borderRadius, rootHeightPx);
    // overflow hidden needed to clip children to borderRadius
    style.overflow = 'hidden';
  }

  if (resolved.borderWidth != null) {
    style.borderWidth = resolveBorderWidth(resolved.borderWidth, rootHeightPx);
  }

  if (resolved.borderColor) {
    style.borderColor = parseColor(resolved.borderColor);
  }

  if (resolved.shadowColor) {
    const shadowColor = parseColor(resolved.shadowColor) ?? 'rgba(0,0,0,0.2)';
    const shadowRadius = resolved.shadowRadius ?? 4;
    const shadowOpacity = 1;

    Object.assign(
      style,
      Platform.select({
        ios: {
          shadowColor,
          shadowOffset: {
            width: resolved.shadowOffsetX ?? 0,
            height: resolved.shadowOffsetY ?? 2,
          },
          shadowRadius,
          shadowOpacity,
        },
        android: {
          elevation: Math.round(shadowRadius),
        },
      }),
    );
  }

  if (resolved.textColor) {
    style.color = parseColor(resolved.textColor);
  }

  if (resolved.fontSize) {
    const fs = resolveTextDim(resolved.fontSize, rootHeightPx);
    if (fs != null) style.fontSize = fs;
  }

  if (resolved.lineHeight) {
    const lh = resolveTextDim(resolved.lineHeight, rootHeightPx);
    // lineHeight in RN is absolute - never multiply by fontSize
    if (lh != null) style.lineHeight = lh;
  }

  if (resolved.fontFamily) {
    style.fontFamily = resolved.fontFamily;
  }

  if (resolved.fontWeight) {
    style.fontWeight = resolved.fontWeight as TextStyle['fontWeight'];
  }

  if (resolved.fontStyle) {
    style.fontStyle = resolved.fontStyle as TextStyle['fontStyle'];
  }

  if (resolved.letterSpacing != null) {
    style.letterSpacing = resolved.letterSpacing;
  }

  if (resolved.textDecoration) {
    if (resolved.textDecoration === 'underline') {
      style.textDecorationLine = 'underline';
    } else if (resolved.textDecoration === 'strikethrough') {
      style.textDecorationLine = 'line-through';
    } else if (resolved.textDecoration === 'none') {
      style.textDecorationLine = 'none';
    }
  }

  if (resolved.textAlign) {
    style.textAlign = resolved.textAlign as TextStyle['textAlign'];
  }

  return style;
}
