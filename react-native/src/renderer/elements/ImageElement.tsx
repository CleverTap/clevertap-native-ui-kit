import React from 'react';
import { Image } from 'react-native';
import type { ImageStyle } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import type { ImageFit } from '../../models/enums';
import { getExpoImage, getFastImage } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';

interface ImageElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
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

export function ImageElement({ node, resolvedStyle }: ImageElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const url = node.bindings?.url ?? '';
  if (!url) return null;

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);
  const imageConfig = node.imageConfig;
  const fit = imageConfig?.fit;
  const resizeMode = fitToResizeMode(fit);
  const gif = isGif(url, imageConfig?.animated);

  // Cast needed: resolveNodeStyle returns ViewStyle & TextStyle whose overflow includes 'scroll',
  // but ImageStyle only allows 'visible' | 'hidden'. Images don't scroll, so the cast is safe.
  const combinedStyle = { ...layoutStyle, ...nodeStyle } as unknown as ImageStyle;

  const ExpoImage = getExpoImage();
  if (ExpoImage) {
    return (
      <ExpoImage
        source={{ uri: url }}
        style={combinedStyle}
        contentFit={fit === 'tile' ? 'repeat' : resizeMode}
      />
    );
  }

  const FastImage = getFastImage();
  if (FastImage && !gif) {
    const fastImageResizeMode = fit === 'crop'
      ? FastImage.resizeMode?.cover
      : fit === 'fill'
        ? FastImage.resizeMode?.stretch
        : fit === 'contain'
          ? FastImage.resizeMode?.contain
          : FastImage.resizeMode?.cover;

    return (
      <FastImage
        source={{ uri: url }}
        style={combinedStyle}
        resizeMode={fastImageResizeMode}
      />
    );
  }

  // Falling back to RN built-in Image - neither expo-image nor react-native-fast-image is installed.
  // GIFs will animate on iOS but show only a static frame on Android.
  if (gif) {
    console.warn('[ImageElement] GIF detected but neither expo-image nor react-native-fast-image is installed. Install one of these peer dependencies for GIF support on Android.');
  }

  return (
    <Image
      source={{ uri: url }}
      style={combinedStyle}
      resizeMode={resizeMode}
    />
  );
}
