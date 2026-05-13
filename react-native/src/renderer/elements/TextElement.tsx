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
 * TextElement always renders as <View><Text/></View>.
 *
 * Why the wrapper is unconditional:
 *  - `resolveNodeStyle` injects `overflow: 'hidden'` whenever `borderRadius` is
 *    set (to clip children of a View to rounded corners). If that style lands
 *    on a <Text>, iOS clips the rendered glyphs to the box and DISABLES soft-
 *    wrap, producing single-line hard-clipping like "Some UI body wi".
 *  - View-only properties (borderRadius, borderWidth, borderColor, shadow*,
 *    backgroundColor) painted directly on a <Text> hug the glyph box, not the
 *    element's layout footprint.
 *
 * Architecture mirrors the iOS SwiftUI renderer:
 *   wrapper View == LayoutModifier + view-level style
 *   inner Text   == text-level style (color, font, letterSpacing, textShadow,
 *                                     textAlign, lineHeight)
 *
 * `splitNodeStyle` is the single source of truth for which keys go where.
 * `ButtonElement` uses the same helper.
 *
 * Why we do NOT auto-inject a default `lineHeight`:
 *   On iOS Fabric, setting an explicit `lineHeight` on an `<RCTText>` whose
 *   parent has a constrained width forces the measurement pass into single-
 *   line mode at intrinsic width. The wrapper then hard-clips the overflowing
 *   glyphs ("Some UI body wi"). Letting iOS pick its own lineHeight (~1.176 ×
 *   fontSize) avoids the bug. JSON authors who need cross-platform line-height
 *   parity must set `lineHeight` explicitly in the unit JSON.
 */
export function TextElement({ node, resolvedStyle }: TextElementProps): React.ReactElement {
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
  //   - `undefined` is supposed to mean "unlimited", but on iOS Fabric the
  //     prop defaults to `1` when not explicitly set, producing single-line
  //     hard-clipped output ("Some UI body wi") for any text whose natural
  //     width exceeds its parent View's width.
  //   - `0` is the documented sentinel for "unlimited lines with wrapping".
  // Always pass `0` when the JSON omits `maxLines`.
  const maxLines: number = resolvedStyle.maxLines ?? 0;
  const overflow = resolvedStyle.overflow;
  // RN ellipsizeMode: 'tail' for ellipsis, 'clip' for hard clip, undefined for default.
  // Matches Android TextOverflow.Ellipsis / Clip / Visible.
  const ellipsizeMode: 'tail' | 'clip' | undefined =
    overflow === 'ellipsis' ? 'tail' : overflow === 'clip' ? 'clip' : undefined;

  // Split: view-level (borderRadius, backgroundColor, borderWidth, borderColor,
  // overflow, opacity, shadow*, elevation) -> wrapper View.
  // text-level (color, font*, letterSpacing, textAlign, textDecoration*) -> inner Text.
  const { viewStyle, textStyle } = splitNodeStyle(nodeStyle as Record<string, unknown>);

  // resolveNodeStyle auto-injects `overflow: 'hidden'` whenever borderRadius is
  // set, so View children get clipped to rounded corners. For a Text-only
  // wrapper there is nothing to clip - the glyphs paint themselves and the
  // rounded corner geometry is carried by the border outline, not by clipping.
  //
  // Worse: on iOS, `overflow:'hidden'` on the direct parent of an RCTText can
  // disrupt the text measurement pass. Strip it here so RCTText receives the
  // wrapper's width as a definite max-width during measurement and wraps
  // correctly.
  delete (viewStyle as Record<string, unknown>).overflow;

  // textShadow* are NATIVE Text properties on RN - keep them on the inner Text.
  if (resolvedStyle.textShadow) {
    const ts = resolvedStyle.textShadow;
    textStyle.textShadowColor = parseColor(ts.color);
    textStyle.textShadowOffset = { width: ts.offsetX, height: ts.offsetY };
    textStyle.textShadowRadius = ts.blur;
  }

  const isWrapContent = isWrapContentLayout(layout);

  // wrap_content text needs flexShrink:1 on the wrapper so a long string next
  // to a fixed-dp sibling (image with explicit width) shrinks rather than
  // pushing the sibling off-screen. Same intent as iOS's lack of
  // .frame(maxWidth:.infinity) on the wrap-content branch.
  const wrapperStyle: ViewStyle = isWrapContent
    ? { ...layoutStyle, ...viewStyle, flexShrink: 1 }
    : { ...layoutStyle, ...viewStyle };

  // Gradient (MaskedView) path. The mask receives the styled Text; MaskedView
  // owns layout + view-level style so corners / borders / clipping apply to
  // the gradient's box, not to the glyphs.
  const gradient = resolvedStyle.textGradient;
  if (gradient && gradient.colors.length >= 2) {
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
    // Fallback: use first color as flat text
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
}
