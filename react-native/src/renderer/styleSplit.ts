import type { TextStyle, ViewStyle } from 'react-native';

/**
 * View-level RN style keys.
 *
 * When these appear in the resolved `nodeStyle`, they MUST be applied to the
 * wrapping `<View>` / `<Pressable>` (the "box"), not to an inner `<Text>`.
 *
 * Background: `resolveNodeStyle` auto-injects `overflow: 'hidden'` whenever a
 * node has `borderRadius`, so that View children get clipped to rounded corners.
 * If that style lands on a `<Text>`, iOS clips the rendered glyphs and disables
 * soft-wrap, producing single-line hard-clipping ("Some UI body wi").
 *
 * Similarly, `borderColor` / `borderWidth` / `backgroundColor` applied to a
 * `<Text>` paint a box around the text's intrinsic size, not around the
 * element's layout footprint - making the stroke hug the label instead of the
 * button.
 */
export const VIEW_STYLE_KEYS: ReadonlyArray<string> = [
  'backgroundColor',
  'borderRadius',
  'borderTopLeftRadius',
  'borderTopRightRadius',
  'borderBottomLeftRadius',
  'borderBottomRightRadius',
  'borderWidth',
  'borderColor',
  'borderTopWidth',
  'borderRightWidth',
  'borderBottomWidth',
  'borderLeftWidth',
  'overflow',
  'opacity',
  'shadowColor',
  'shadowOffset',
  'shadowOpacity',
  'shadowRadius',
  'elevation',
];

/**
 * Split a resolved node style object into a view-level subset (for the wrapper
 * View / Pressable) and a text-level subset (for the inner Text).
 *
 * Used by `TextElement` and `ButtonElement` to keep view-only styles (border,
 * background, clipping, shadow, opacity) off the inner `<Text>` where they
 * cause iOS rendering bugs.
 */
export function splitNodeStyle(
  nodeStyle: Record<string, unknown>,
): { viewStyle: ViewStyle; textStyle: TextStyle } {
  const viewStyle: Record<string, unknown> = {};
  const textStyle: Record<string, unknown> = {};
  for (const k of Object.keys(nodeStyle)) {
    if (VIEW_STYLE_KEYS.includes(k)) {
      viewStyle[k] = nodeStyle[k];
    } else {
      textStyle[k] = nodeStyle[k];
    }
  }
  return { viewStyle: viewStyle as ViewStyle, textStyle: textStyle as TextStyle };
}
