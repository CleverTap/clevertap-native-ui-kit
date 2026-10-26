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

// Map JSON font weights to values RN honors. RN only handles 'normal', 'bold',
// and numeric strings '100'-'900'; 'light' and 'medium' get dropped to normal.
// Convert them to 300/500 to match native.
function mapFontWeight(weight: string): TextStyle['fontWeight'] {
  switch (weight) {
    case 'light':
      return '300';
    case 'medium':
      return '500';
    case 'bold':
      return 'bold';
    case 'normal':
      return 'normal';
    default:
      // Numeric string or unknown value - pass through.
      return weight as TextStyle['fontWeight'];
  }
}

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

export function resolveOffsetStyle(offset: Offset): {
  top: number | `${number}%`;
  left: number | `${number}%`;
} {
  if (offset.unit === 'percent') {
    return { top: `${offset.y}%`, left: `${offset.x}%` };
  }
  // dp / sp / px - use the raw number (RN treats unitless as dp).
  return { top: offset.y, left: offset.x };
}

export function resolveLayoutStyle(layout: Layout, rootHeightPx: number): ViewStyle {
  const style: ViewStyle = {};

  const width = resolveDimension(layout.width);
  if (width === MATCH_PARENT_MARKER) {
    // Fill horizontal space. Use width: '100%', not flex: 1 - flex fills the
    // main axis (height in a vertical container), not width.
    style.width = '100%';
  } else if (width !== undefined) {
    // Explicit width must hold its size. flexShrink: 0 stops a sibling from
    // squeezing it in a horizontal row.
    style.width = width as number | `${number}%`;
    style.flexShrink = 0;
  }
  // wrap_content keeps RN's default flexShrink of 1, so it can shrink to make
  // room for fixed-size siblings.

  const height = resolveDimension(layout.height);
  if (height === MATCH_PARENT_MARKER) {
    // Fill vertical space. Use height: '100%', not flex: 1. flex fills the main
    // axis. The main axis is the width in a horizontal container, not the
    // height. This matches native fillMaxHeight (Android) and
    // maxHeight: .infinity (iOS). Those fill the height in any container
    // direction.
    style.height = '100%';
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
    // Clip children to the rounded corners.
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
    // RN lineHeight is absolute - don't multiply by fontSize.
    if (lh != null) style.lineHeight = lh;
  }

  if (resolved.fontFamily) {
    style.fontFamily = resolved.fontFamily;
  }

  if (resolved.fontWeight) {
    style.fontWeight = mapFontWeight(resolved.fontWeight);
  }

  if (resolved.fontStyle) {
    style.fontStyle = resolved.fontStyle as TextStyle['fontStyle'];
  }

  if (resolved.letterSpacing != null) {
    // Skip letterSpacing when fontSize is exactly 0. Android Fabric derives
    // letter spacing from fontSize and throws if fontSize is 0. An unset
    // fontSize falls back to RN's default (14), which is fine.
    if (style.fontSize !== 0) {
      style.letterSpacing = resolved.letterSpacing;
    }
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
