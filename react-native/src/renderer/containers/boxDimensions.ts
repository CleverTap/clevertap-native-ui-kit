import type { Dimension, Layout } from '../../models/Layout';

/**
 * Pure BOX sizing helpers (no React / react-native imports) so they can be
 * unit-tested in a plain node environment.
 */

/**
 * Turn a layout Dimension into a pixel number.
 * Returns undefined for wrap_content so the content sizes itself.
 */
export function dimensionToPx(
  dim: Dimension | undefined,
  parentPx: number,
): number | undefined {
  if (!dim) return undefined;
  if (dim.special === 'wrap_content') return undefined;
  if (dim.special === 'match_parent') return parentPx;
  if (dim.unit === 'percent') return (parentPx * dim.value) / 100;
  // dp / sp / px - use the raw value
  return dim.value;
}

/** A dimension is "fixed" when it has a concrete unit (dp/sp/px), no special. */
export function isFixedDim(dim: Dimension | undefined): boolean {
  return dim != null && dim.special == null && dim.unit !== 'percent';
}

/**
 * Work out the BOX pixel size in JS, matching the cross-platform rule:
 *  0. aspectRatio overrides percent — when aspectRatio is set and NOT both width
 *     & height are fixed, the box takes the FULL available parent width and
 *     derives height = width / aspectRatio, ignoring width.percent/height.percent.
 *     (Only skipped when BOTH width AND height are fixed dp/sp/px.)
 *  1. Fixed dp/sp/px height
 *  2. Percent height of the parent
 *  3. Parent height
 *  4. Width (makes a square)
 *
 * Why compute it here instead of letting Yoga do it: a "60%" height inside an
 * unbounded ScrollView resolves to 0 before aspectRatio can kick in, so every
 * child ends up at y=0. Doing the math against the known root size avoids that.
 */
export function resolveBoxDimensionsPx(
  layout: Layout,
  rootWidth: number,
  rootHeight: number,
): { width: number; height: number } {
  const bothFixed = isFixedDim(layout.width) && isFixedDim(layout.height);

  // 0. aspectRatio overrides percent: full parent width, height derived from AR.
  //    width.percent / height.percent are ignored.
  if (layout.aspectRatio != null && layout.aspectRatio > 0 && !bothFixed) {
    const width = rootWidth;
    return { width, height: width / layout.aspectRatio };
  }

  // Width: fixed value, then percent of root, then root width
  const width = dimensionToPx(layout.width, rootWidth) ?? rootWidth;

  const h = layout.height;

  // 1. Fixed height
  if (h && h.special == null && h.unit !== 'percent') {
    return { width, height: h.value };
  }

  // 2. Percent of root height
  if (h?.unit === 'percent' && rootHeight > 0) {
    return { width, height: (rootHeight * h.value) / 100 };
  }

  // 3. Root height
  if (rootHeight > 0) {
    return { width, height: rootHeight };
  }

  // 4. Square
  return { width, height: width };
}
