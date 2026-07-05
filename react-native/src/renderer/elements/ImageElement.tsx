import React, { useCallback, useRef } from 'react';
import { Image, Pressable } from 'react-native';
import type { ImageStyle } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ImageFit } from '../../models/enums';
import { ActionHandler } from '../../handler/ActionHandler';
import { getExpoImage, getFastImage } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';

// Two taps within this window count as a double-tap. Matches ButtonElement /
// Android's ViewConfiguration.DOUBLE_TAP_TIMEOUT (300 ms).
const DOUBLE_TAP_WINDOW_MS = 300;

interface ImageElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
  actionHandler: ActionHandler;
}

type RNResizeMode = 'cover' | 'contain' | 'stretch' | 'repeat' | 'center';

function fitToResizeMode(fit: ImageFit | undefined): RNResizeMode {
  switch (fit) {
    case 'crop': return 'cover';
    case 'contain': return 'contain';
    case 'fill': return 'stretch';
    case 'tile': return 'repeat';
    default: return 'cover';
  }
}

function isGif(url: string, animated?: boolean | null): boolean {
  if (animated === true) return true;
  if (animated === false) return false;
  return url.toLowerCase().endsWith('.gif');
}

export const ImageElement = React.memo(function ImageElement({ node, resolvedStyle, actionHandler }: ImageElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const lastTapAt = useRef<number>(0);

  // Server-driven images can carry interaction actions just like buttons.
  // Both native SDKs fire "Notification Clicked" (with element attribution)
  // and dispatch the onClick action when an IMAGE with actions is tapped
  // (SDK-5862). Without this, an actionable image is inert on RN - no event
  // reaches the server and the action never runs.
  const clickAction = node.actions?.onClick;
  const doubleTapAction = node.actions?.onDoubleTap;
  const longPressAction = node.actions?.onLongPress;
  const interactive = !!(clickAction || doubleTapAction || longPressAction);

  const handlePress = useCallback(() => {
    const now = Date.now();
    const gap = now - lastTapAt.current;
    lastTapAt.current = now;

    // Fire the unit-clicked event on every tap, matching ButtonElement and
    // the native image-tap path. Pass the onClick action so element
    // attribution (action_type, action_url, wzrk_*, ...) rides along.
    actionHandler.fireClickedEvent(node.id, clickAction);

    if (gap > 0 && gap < DOUBLE_TAP_WINDOW_MS && doubleTapAction) {
      actionHandler.handle(doubleTapAction, node.id, 'doubleTap');
      return; // skip onClick for the tap that completes the double-tap
    }

    if (clickAction) {
      actionHandler.handle(clickAction, node.id, 'click');
    }
  }, [node, actionHandler, clickAction, doubleTapAction]);

  const handleLongPress = useCallback(() => {
    if (longPressAction) {
      actionHandler.handle(longPressAction, node.id, 'longPress');
    }
  }, [node, actionHandler, longPressAction]);

  const url = node.bindings?.url ?? '';
  if (!url) return null;

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);
  const imageConfig = node.imageConfig;
  const fit = imageConfig?.fit;
  const resizeMode = fitToResizeMode(fit);
  const gif = isGif(url, imageConfig?.animated);

  // Cast needed: resolveNodeStyle returns ViewStyle & TextStyle where overflow includes 'scroll',
  // but ImageStyle only allows 'visible' | 'hidden'. Images never scroll, so the cast is safe.
  const combinedStyle = { ...layoutStyle, ...nodeStyle } as unknown as ImageStyle;

  let image: React.ReactElement;

  const ExpoImage = getExpoImage();
  const FastImage = getFastImage();
  if (ExpoImage) {
    image = (
      <ExpoImage
        source={{ uri: url }}
        style={combinedStyle}
        contentFit={fit === 'tile' ? 'repeat' : resizeMode}
      />
    );
  } else if (FastImage && !gif) {
    const fastImageResizeMode = fit === 'crop'
      ? FastImage.resizeMode?.cover
      : fit === 'fill'
        ? FastImage.resizeMode?.stretch
        : fit === 'contain'
          ? FastImage.resizeMode?.contain
          : FastImage.resizeMode?.cover;

    image = (
      <FastImage
        source={{ uri: url }}
        style={combinedStyle}
        resizeMode={fastImageResizeMode}
      />
    );
  } else {
    // Neither expo-image nor react-native-fast-image is available; fall back to the built-in Image.
    // GIFs will animate on iOS but show only a static frame on Android.
    if (gif) {
      console.warn('[ImageElement] GIF detected but neither expo-image nor react-native-fast-image is installed. Install one of these peer dependencies for GIF support on Android.');
    }
    image = (
      <Image
        source={{ uri: url }}
        style={combinedStyle}
        resizeMode={resizeMode}
      />
    );
  }

  // Non-interactive image: render it directly, no tap wrapper (keeps the
  // hit-testing / layout identical to before for the common case).
  if (!interactive) return image;

  // Interactive image: wrap in a style-less Pressable so it shrink-wraps to
  // the image's own footprint (the image keeps its full layout+visual style),
  // then routes taps through the same click path as ButtonElement.
  return (
    <Pressable onPress={handlePress} onLongPress={handleLongPress} accessibilityRole="imagebutton">
      {image}
    </Pressable>
  );
});
