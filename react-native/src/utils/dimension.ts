import { Dimension } from '../models/Layout';
import { TextDimension } from '../models/Style';

export function dimensionToNumber(dim: Dimension | undefined, parentSize: number): number | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return undefined;

  switch (dim.unit) {
    case 'dp':
    case 'sp':
      return dim.value;
    case 'percent':
      return (parentSize * dim.value) / 100;
    case 'px':
      return dim.value;
    default:
      return dim.value;
  }
}

export function isMatchParent(dim: Dimension | undefined): boolean {
  return dim?.special === 'match_parent';
}

export function isWrapContent(dim: Dimension | undefined): boolean {
  return !dim || dim.special === 'wrap_content';
}

export function resolveTextDim(td: TextDimension | undefined, rootHeightPx: number): number | undefined {
  if (!td) return undefined;
  const result = td.unit === 'percent' ? (rootHeightPx * td.value) / 1000 : td.value;
  // Never return 0 or negative. Android Fabric throws
  //   IllegalArgumentException: FontSize should be a positive value
  // when measuring text with `letterSpacing` set against a fontSize of 0.
  // Returning undefined makes the caller skip setting fontSize entirely, so
  // RN falls back to its own default (14) and Fabric is happy.
  // This happens in practice on the first render of a NativeDisplayView before
  // `onLayout` has supplied a non-zero `rootHeightPx`.
  return result > 0 ? result : undefined;
}

export function hasBorderRadiusPercent(dim: Dimension | undefined): boolean {
  return dim?.unit === 'percent';
}

export function resolveBorderRadius(dim: Dimension | undefined, rootHeightPx: number): number {
  if (!dim) return 0;
  if (dim.unit === 'percent') return rootHeightPx * dim.value / 100;
  return dim.value;
}

export function resolveBorderWidth(raw: number | undefined, rootHeightPx: number): number {
  if (!raw) return 0;
  return rootHeightPx * raw / 1000;
}

export function hasPercentDimensions(node: import('../models/NativeDisplayNode').NativeDisplayNode): boolean {
  const layout = node.layout;
  if (!layout) {
    if (node.type === 'container') {
      return node.children.some(hasPercentDimensions);
    }
    return false;
  }
  if (layout.width?.unit === 'percent') return true;
  if (layout.height?.unit === 'percent') return true;
  if (layout.offset?.unit === 'percent') return true;
  if (node.type === 'container') {
    return node.children.some(hasPercentDimensions);
  }
  return false;
}
