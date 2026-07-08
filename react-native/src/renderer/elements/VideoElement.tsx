import React, { useCallback, useState } from 'react';
import { Linking, Pressable, StyleSheet, Text, View } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getVideo } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';
import { coerceToBool } from '../../evaluator/VariableEvaluator';
import { NDLogger } from '../../internal/NDLogger';

interface VideoElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

// Allow any URL that has a scheme, including custom deeplinks (myapp://, etc.),
// like the native SDKs do (SDK-5859). We only require a valid scheme followed by
// ':', which drops junk like "www.google.com" that can't be opened anyway.
function isValidUrlScheme(url: string): boolean {
  return /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(url.trim());
}

export const VideoElement = React.memo(function VideoElement({ node, resolvedStyle }: VideoElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const Video = getVideo();

  const url = node.bindings?.url ?? '';

  // Read bindings up front: the useCallback hooks below must run before any return.
  const videoConfig = node.bindings;
  const openUrl = videoConfig?.openUrl ?? '';

  // Track playback errors so we can show a fallback overlay instead of a black screen.
  const [hasError, setHasError] = useState(false);
  const handleError = useCallback(() => {
    NDLogger.w('VideoElement', `Playback failed for url: ${url}`);
    setHasError(true);
  }, [url]);

  const handleOpenUrl = useCallback(() => {
    if (!openUrl) return;
    if (!isValidUrlScheme(openUrl)) {
      NDLogger.w('VideoElement', `Invalid URL scheme, dropping openUrl: ${openUrl}`);
      return;
    }
    Linking.openURL(openUrl).catch((e) => {
      NDLogger.w('VideoElement', `Failed to open URL: ${openUrl}`, e);
    });
  }, [openUrl]);

  if (!Video) {
    NDLogger.w('VideoElement', 'VIDEO element requires react-native-video peer dependency. Element will not render.');
    return null;
  }

  if (!url) return null;

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);

  // autoPlay/loop/muted default OFF (matches iOS/Android). coerceToBool handles
  // "true"/"false", "1"/"0", and native booleans so any form the BE sends is read
  // the same way as native; missing/bad values fall back to false.
  const autoPlay = coerceToBool(videoConfig?.autoPlay) ?? false;
  const loop = coerceToBool(videoConfig?.loop) ?? false;
  const muted = coerceToBool(videoConfig?.muted) ?? false;
  // Controls default ON (matches iOS/Android). Only an explicit false value hides them.
  const showControls = coerceToBool(videoConfig?.showControls) ?? true;

  const errorOverlay = hasError ? (
    <View style={[StyleSheet.absoluteFill, errorOverlayStyle]} pointerEvents="none">
      <Text style={errorTextStyle}>Video playback failed</Text>
    </View>
  ) : null;

  // If openUrl is set, put a tappable overlay on top of the player that opens
  // the URL. It sits above the native controls to catch taps first (matches iOS).
  if (openUrl) {
    return (
      <View style={layoutStyle}>
        <Video
          source={{ uri: url }}
          style={StyleSheet.absoluteFill}
          paused={!autoPlay}
          repeat={loop}
          muted={muted}
          controls={showControls}
          resizeMode="contain"
          onError={handleError}
        />
        {errorOverlay}
        <Pressable
          style={StyleSheet.absoluteFill}
          onPress={handleOpenUrl}
          accessibilityRole="link"
        />
      </View>
    );
  }

  return (
    <View style={layoutStyle}>
      <Video
        source={{ uri: url }}
        style={StyleSheet.absoluteFill}
        paused={!autoPlay}
        repeat={loop}
        muted={muted}
        controls={showControls}
        resizeMode="contain"
        onError={handleError}
      />
      {errorOverlay}
    </View>
  );
});

const errorOverlayStyle = {
  backgroundColor: 'rgba(0, 0, 0, 0.6)',
  justifyContent: 'center' as const,
  alignItems: 'center' as const,
};

const errorTextStyle = {
  color: '#ffffff',
  fontSize: 14,
  fontWeight: '600' as const,
  textAlign: 'center' as const,
  paddingHorizontal: 16,
};
