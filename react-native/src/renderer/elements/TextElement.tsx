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
import { useVariables } from '../../context/VariablesContext';
import { VariableEvaluator } from '../../evaluator/VariableEvaluator';
import { NDLogger } from '../../internal/NDLogger';

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
 * Always renders as `<View><Text/></View>`. The wrapper View holds layout and
 * view-level style (background, border, shadow); the inner Text holds text style.
 * `splitNodeStyle` decides which keys go where (ButtonElement uses it too).
 *
 * Why the wrapper is always there: view styles like borderRadius put on a
 * `<Text>` hug the glyphs, not the element's box. Also `resolveNodeStyle` adds
 * `overflow: 'hidden'` for borderRadius, and on iOS that on a `<Text>` clips
 * the text to one line ("Some UI body wi").
 *
 * We don't auto-set a default `lineHeight`: on iOS, an explicit lineHeight on
 * width-constrained text forces single-line measurement and clips it (confirmed
 * on-device: multiline body text truncates to "Some UI body wi" on one line).
 * Let iOS pick its own. Authors who need line-height parity must set it in the
 * JSON. ButtonElement can set a default because its label is single-line.
 */
export const TextElement = React.memo(function TextElement({ node, resolvedStyle }: TextElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const fontCtx = useFontContext();
  const variables = useVariables();
  const layout = node.layout ?? {};

  // Substitute {{variable}} placeholders, same as the native renderers. A
  // string with no placeholders passes through unchanged.
  const text = new VariableEvaluator(variables).evaluateString(node.bindings?.text ?? '');

  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  const fontFamily = resolveFont(resolvedStyle.fontFamily, fontCtx);
  if (fontFamily) {
    nodeStyle.fontFamily = fontFamily;
  }

  // Pass 0 (unlimited lines) when maxLines is omitted. On iOS, leaving it
  // undefined defaults to 1 line and clips wide text ("Some UI body wi").
  const maxLines: number = resolvedStyle.maxLines ?? 0;
  const overflow = resolvedStyle.overflow;
  // Map overflow to RN ellipsizeMode: 'tail' = ellipsis, 'clip' = hard clip.
  const ellipsizeMode: 'tail' | 'clip' | undefined =
    overflow === 'ellipsis' ? 'tail' : overflow === 'clip' ? 'clip' : undefined;

  // Split view-level style (for the wrapper View) from text-level style (for the Text).
  const { viewStyle, textStyle } = splitNodeStyle(nodeStyle as Record<string, unknown>);

  // Drop `overflow: hidden` (added by resolveNodeStyle for borderRadius). There's
  // nothing to clip here, and on iOS it breaks text measurement so text wraps wrong.
  delete (viewStyle as Record<string, unknown>).overflow;

  // textShadow is a native Text prop in RN, so keep it on the inner Text.
  if (resolvedStyle.textShadow) {
    const ts = resolvedStyle.textShadow;
    textStyle.textShadowColor = parseColor(ts.color);
    textStyle.textShadowOffset = { width: ts.offsetX, height: ts.offsetY };
    textStyle.textShadowRadius = ts.blur;
  }

  const isWrapContent = isWrapContentLayout(layout);

  // wrap_content text uses flexShrink:0 so it keeps its natural width and is never
  // squeezed by its parent (matches Android). RN's default flexShrink:1 would let
  // chips in a tight row shrink and wrap to two lines, making them mismatched heights.
  // Trade-off: a long string next to a fixed-width sibling can push it off-screen in
  // a tight row (same as Android). Set an explicit width or maxLines:1 + ellipsis to clip.
  const wrapperStyle: ViewStyle = isWrapContent
    ? { ...layoutStyle, ...viewStyle, flexShrink: 0 }
    : { ...layoutStyle, ...viewStyle };

  // Gradient text via MaskedView: the Text is the mask, the gradient fills it.
  const gradient = resolvedStyle.textGradient;
  // Guard against a malformed gradient (missing colors) - fall back to flat text
  // instead of throwing, so we don't trip the error boundary.
  if (gradient && Array.isArray(gradient.colors) && gradient.colors.length >= 2) {
    const MaskedView = getMaskedView();
    const LinearGradient = getLinearGradient();

    if (MaskedView && LinearGradient) {
      // Subtract 90 so 0deg points up, matching BackgroundRenderer's gradient
      // math and the native/Flutter text gradients. Without it the fill is
      // rotated 90deg from the background gradients in the same config.
      const angleRad = (((gradient.angle ?? 0) - 90) * Math.PI) / 180;
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
          >
            {/* Invisible copy of the text. It gives the gradient a real size.
                The mask above then shows the gradient through the text shape.
                A bare flex:1 gradient has no size when the parent has no
                height. The text nodes use wrap_content. So the parent has no
                height. Without this copy the whole masked view is blank. */}
            <Text
              style={[textStyle, { opacity: 0 }]}
              numberOfLines={maxLines}
              ellipsizeMode={ellipsizeMode}
            >
              {text}
            </Text>
          </LinearGradient>
        </MaskedView>
      );
    }
    // Deps missing - fall back to the first color as flat text.
    const missing = [
      !MaskedView && '@react-native-masked-view/masked-view',
      !LinearGradient && 'react-native-linear-gradient',
    ].filter(Boolean).join(' and ');
    NDLogger.w('TextElement', `textGradient requires ${missing}. Falling back to flat text color.`);
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
