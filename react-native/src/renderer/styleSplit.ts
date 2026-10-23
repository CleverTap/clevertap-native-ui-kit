import type { TextStyle, ViewStyle } from 'react-native';

/**
 * Style keys that belong on the wrapping View / Pressable, not the inner Text.
 *
 * On a Text, `overflow: hidden` makes iOS clip glyphs and stop wrapping, and
 * border/background paint around the text's own size instead of the whole
 * element. So these must go on the View.
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
 * Split a node style into a view part (wrapper View / Pressable) and a text
 * part (inner Text). Keeps view-only styles off the Text, where they cause
 * iOS rendering bugs. Used by TextElement and ButtonElement.
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
