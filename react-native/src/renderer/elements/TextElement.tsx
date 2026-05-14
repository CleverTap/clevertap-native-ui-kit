import React from 'react';
import { Text, View } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { Layout } from '../../models/Layout';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { parseColor } from '../../utils/color';
import { getMaskedView, getLinearGradient } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { useFontContext, resolveFont } from '../../context/FontContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { splitNodeStyle } from '../styleSplit';

function isWrapContentLayout(layout: Layout): boolean {
  const w = layout.width;
  const h = layout.height;
  const wIsWrap = !w || (w.special === 'wrap_content') || (w.value === 0 && !w.special);
  const hIsWrap = !h || (h.special === 'wrap_content') || (h.value === 0 && !h.special);
  return wIsWrap && hIsWrap;
}

interface TextElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

/**
 * TextElement always renders as `<View><Text/></View>`.
 *
 * Why the wrapper is unconditional:
 *  - `resolveNodeStyle` injects `overflow: 'hidden'` whenever `borderRadius`
 *    is set, to clip View children to rounded corners. If that style lands on a
 *    `<Text>`, iOS clips the glyphs and disables soft-wrap, producing
 *    single-line hard-clipping like "Some UI body wi".
 *  - View-only properties (borderRadius, borderWidth, borderColor, shadow*,
 *    backgroundColor) painted directly on a `<Text>` hug the glyph box, not
 *    the element's layout footprint.
 *
 * Structure mirrors the iOS SwiftUI renderer:
 *   wrapper View = layout modifier + view-level style
 *   inner Text   = text-level style (color, font, letterSpacing, textShadow,
 *                  textAlign, lineHeight)
 *
 * `splitNodeStyle` decides which keys go where.
 * `ButtonElement` uses the same helper.
 *
 * Why we do not auto-inject a default `lineHeight`:
 *   On iOS Fabric, setting an explicit `lineHeight` on an `<RCTText>` whose
 *   parent has a constrained width forces the measurement pass into single-line
 *   mode at intrinsic width. The wrapper then hard-clips the glyphs. Letting
 *   iOS pick its own lineHeight (about 1.176 x fontSize) avoids the bug. JSON
 *   authors who need cross-platform line-height parity must set `lineHeight`
 *   explicitly in the unit JSON.
 */
export const TextElement = React.memo(function TextElement({ node, resolvedStyle }: TextElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const fontCtx = useFontContext();
  const layout = node.layout ?? {};

  const text = node.bindings?.text ?? '';

  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  const fontFamily = resolveFont(resolvedStyle.fontFamily, fontCtx);
  if (fontFamily) {
    nodeStyle.fontFamily = fontFamily;
  }

  // RN Text `numberOfLines`:
  //   - `undefined` should mean "unlimited", but on iOS Fabric the prop
  //     defaults to `1` when not explicitly set. Any text wider than its
  //     parent View is hard-clipped to one line ("Some UI body wi").
  //   - `0` is the documented sentinel for unlimited lines with wrapping.
  // Always pass `0` when the JSON omits `maxLines`.
  const maxLines: number = resolvedStyle.maxLines ?? 0;
  const overflow = resolvedStyle.overflow;
  // Map to RN ellipsizeMode: 'tail' for ellipsis, 'clip' for hard clip, undefined for default.
  // Matches Android TextOverflow.Ellipsis / Clip / Visible.
  const ellipsizeMode: 'tail' | 'clip' | undefined =
    overflow === 'ellipsis' ? 'tail' : overflow === 'clip' ? 'clip' : undefined;

  // Split into view-level keys (borderRadius, backgroundColor, borderWidth,
  // borderColor, overflow, opacity, shadow*, elevation) for the wrapper View,
  // and text-level keys (color, font*, letterSpacing, textAlign, textDecoration*)
  // for the inner Text.
  const { viewStyle, textStyle } = splitNodeStyle(nodeStyle as Record<string, unknown>);

  // `resolveNodeStyle` injects `overflow: 'hidden'` when borderRadius is set,
  // so View children get clipped to rounded corners. For a Text-only wrapper
  // there is nothing to clip - the rounded corner is just a border outline.
  //
  // On iOS, `overflow: 'hidden'` on the direct parent of an RCTText can break
  // the measurement pass. Removing it lets RCTText receive the wrapper's width
  // as a definite max-width, so text wraps correctly.
  delete (viewStyle as Record<string, unknown>).overflow;

  // textShadow* are native Text properties in RN - keep them on the inner Text.
  if (resolvedStyle.textShadow) {
    const ts = resolvedStyle.textShadow;
    textStyle.textShadowColor = parseColor(ts.color);
    textStyle.textShadowOffset = { width: ts.offsetX, height: ts.offsetY };
    textStyle.textShadowRadius = ts.blur;
  }

  const isWrapContent = isWrapContentLayout(layout);

  // wrap_content text needs flexShrink:1 on the wrapper so a long string next
  // to a fixed-dp sibling (such as an image with an explicit width) shrinks
  // rather than pushing the sibling off-screen. This matches the intent of
  // iOS not setting .frame(maxWidth:.infinity) on the wrap-content branch.
  const wrapperStyle: ViewStyle = isWrapContent
    ? { ...layoutStyle, ...viewStyle, flexShrink: 1 }
    : { ...layoutStyle, ...viewStyle };

  // Gradient path using MaskedView. The mask holds the styled Text; MaskedView
  // owns layout and view-level styles so corners, borders, and clipping apply
  // to the gradient box, not to the glyphs.
  const gradient = resolvedStyle.textGradient;
  // Guard: `colors` may be null/undefined if the server sends a malformed
  // textGradient object. Fall through to flat text rendering instead of
  // throwing, so the error boundary is not triggered by this one case.
  if (gradient && Array.isArray(gradient.colors) && gradient.colors.length >= 2) {
    const MaskedView = getMaskedView();
    const LinearGradient = getLinearGradient();

    if (MaskedView && LinearGradient) {
      const angleRad = ((gradient.angle ?? 0) * Math.PI) / 180;
      const startX = 0.5 - Math.cos(angleRad) * 0.5;
      const startY = 0.5 - Math.sin(angleRad) * 0.5;
      const endX = 0.5 + Math.cos(angleRad) * 0.5;
      const endY = 0.5 + Math.sin(angleRad) * 0.5;

      const parsedColors = gradient.colors.map((c) => parseColor(c) ?? c);

      return (
        <MaskedView
          style={[wrapperStyle, { flexDirection: 'row' }]}
          maskElement={
            <Text
              style={[textStyle, { color: 'black' }]}
              numberOfLines={maxLines}
              ellipsizeMode={ellipsizeMode}
            >
              {text}
            </Text>
          }
        >
          <LinearGradient
            colors={parsedColors}
            start={{ x: startX, y: startY }}
            end={{ x: endX, y: endY }}
            style={{ flex: 1 }}
          />
        </MaskedView>
      );
    }
    // Fall back to the first color as flat text
    const missing = [
      !MaskedView && '@react-native-masked-view/masked-view',
      !LinearGradient && 'react-native-linear-gradient',
    ].filter(Boolean).join(' and ');
    console.warn(`[TextElement] textGradient requires ${missing}. Falling back to flat text color.`);
    textStyle.color = parseColor(gradient.colors[0]) ?? textStyle.color;
  }

  return (
    <View style={wrapperStyle}>
      <Text
        style={textStyle}
        numberOfLines={maxLines}
        ellipsizeMode={ellipsizeMode}
      >
        {text}
      </Text>
    </View>
  );
});
