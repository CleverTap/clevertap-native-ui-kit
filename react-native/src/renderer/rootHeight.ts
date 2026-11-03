import type { Layout } from '../models/Layout';

/**
 * Pure rootHeight-anchor helpers (no react-native import) so they can be unit
 * tested in a plain node environment. They mirror the native Android SDK's
 * resolveRootWidthPx / resolveRootHeightPx so percent fontSize / borderRadius /
 * lineHeight anchor on the SAME value across Android, iOS and RN.
 */

/**
 * Root width in dp for the aspect-ratio height calc — mirrors native
 * resolveRootWidthPx: percent resolves against the parent, dp/sp/px use the raw
 * value, specials (match_parent / wrap_content) fall back to the parent width.
 */
export function resolveRootWidthDp(
  rootLayout: Layout | undefined,
  parentWidth: number,
): number {
  const w = rootLayout?.width;
  if (!w || w.special != null) return parentWidth;
  if (w.unit === 'percent') return parentWidth > 0 ? (parentWidth * w.value) / 100 : 0;
  return w.value; // dp / sp / px
}

/**
 * rootHeight anchor (dp), mirroring native resolveRootHeightPx EXACTLY:
 *   1. fixed dp/sp/px height
 *   2. aspectRatio -> resolveRootWidth / aspectRatio   (honors the declared % width)
 *   3. percent height x parentHeight
 *   4. parentHeight
 *   5. screen height
 *
 * RN previously used the MEASURED view height, which over-sizes the anchor for
 * aspectRatio roots: the box renders at full width, but native anchors on the
 * declared percent width — so percent fonts came out too large (fewer text lines).
 */
export function resolveRootHeightDp(
  rootLayout: Layout | undefined,
  parentWidth: number,
  parentHeight: number,
  screenHeight: number,
): number {
  const h = rootLayout?.height;
  if (h && h.special == null && h.unit !== 'percent' && h.value > 0) return h.value;

  const ar = rootLayout?.aspectRatio;
  if (ar != null && ar > 0) {
    const rw = resolveRootWidthDp(rootLayout, parentWidth);
    if (rw > 0) return rw / ar;
  }

  if (h && h.special == null && h.unit === 'percent' && parentHeight > 0) {
    return (parentHeight * h.value) / 100;
  }

  if (parentHeight > 0) return parentHeight;
  return screenHeight;
}
