import React from 'react';
import { Text, View } from 'react-native';
import type { TextStyle, ViewStyle } from 'react-native';
import type { Layout } from '../../models/Layout';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { resolveTextDim } from '../../utils/dimension';
import { parseColor } from '../../utils/color';
import { getMaskedView, getLinearGradient } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { useFontContext, resolveFont } from '../../context/FontContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';

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

  const maxLines = resolvedStyle.maxLines;
  const overflow = resolvedStyle.overflow;
  // RN ellipsizeMode: 'tail' for ellipsis, 'clip' for hard clip, undefined for default.
  // Matches Android TextOverflow.Ellipsis / Clip / Visible.
  const ellipsizeMode: 'tail' | 'clip' | undefined =
    overflow === 'ellipsis' ? 'tail' : overflow === 'clip' ? 'clip' : undefined;

  // lineHeight must always be explicit
  let lineHeight: number | undefined = nodeStyle.lineHeight as number | undefined;
  if (lineHeight == null && resolvedStyle.fontSize) {
    const fs = resolveTextDim(resolvedStyle.fontSize, rootHeight) ?? 14;
    // Fall back: platform default ratio Android=1.5, iOS=1.176 - use 1.3 as neutral cross-platform safe default
    lineHeight = fs * 1.3;
    nodeStyle.lineHeight = lineHeight;
  }

  const textStyle: TextStyle = {
    ...nodeStyle,
  };

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
          style={[layoutStyle, { flexDirection: 'row' }]}
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

  if (resolvedStyle.textShadow) {
    const ts = resolvedStyle.textShadow;
    textStyle.textShadowColor = parseColor(ts.color);
    textStyle.textShadowOffset = { width: ts.offsetX, height: ts.offsetY };
    textStyle.textShadowRadius = ts.blur;
  }

  // Wrap <Text> in a <View> so the View is the flex item seen by parent containers.
  // <Text> in a flex row measures itself at the full container width when it wraps,
  // making flexShrink ineffective. A View wrapper is properly measured and shrinkable,
  // so fixed-size siblings (e.g. an image with explicit dp width) are never pushed
  // off-screen by long text content.
  const isWrapContent = isWrapContentLayout(layout);
  if (isWrapContent) {
    const { backgroundColor, ...textOnlyStyle } = textStyle as TextStyle & { backgroundColor?: string };
    const wrapperStyle: ViewStyle = {
      ...layoutStyle,
      flexShrink: 1,
      ...(backgroundColor ? { backgroundColor } : {}),
    };
    return (
      <View style={wrapperStyle}>
        <Text
          style={textOnlyStyle as TextStyle}
          numberOfLines={maxLines}
          ellipsizeMode={ellipsizeMode}
        >
          {text}
        </Text>
      </View>
    );
  }

  return (
    <Text
      style={[layoutStyle, textStyle]}
      numberOfLines={maxLines}
      ellipsizeMode={ellipsizeMode}
    >
      {text}
    </Text>
  );
}
