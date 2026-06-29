import React, { useCallback, useState } from 'react';
import { Linking, Pressable, StyleSheet, Text, View } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getVideo } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';

interface VideoElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

// Mirror ActionHandler.isValidUrlScheme - keep the same allow-list so the
// behavior of "tap the video to open this URL" matches button clicks.
function isValidUrlScheme(url: string): boolean {
  const scheme = url.split(':')[0]?.toLowerCase();
  return ['http', 'https', 'tel', 'mailto'].includes(scheme ?? '');
}

export const VideoElement = React.memo(function VideoElement({ node, resolvedStyle }: VideoElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const Video = getVideo();

  const url = node.bindings?.url ?? '';

  // Pull bindings up front because the openUrl overlay handler is declared
  // with useCallback - hooks must run unconditionally before any return.
  const videoConfig = node.bindings;
  const openUrl = videoConfig?.openUrl ?? '';

  // Track playback errors so we can render a fallback overlay instead of
  // a silent black surface. Mirrors iOS's AVPlayerItem.status observation.
  const [hasError, setHasError] = useState(false);
  const handleError = useCallback(() => {
    console.warn(`[VideoElement] Playback failed for url: ${url}`);
    setHasError(true);
  }, [url]);

  const handleOpenUrl = useCallback(() => {
    if (!openUrl) return;
    if (!isValidUrlScheme(openUrl)) {
      console.warn(`[VideoElement] Invalid URL scheme, dropping openUrl: ${openUrl}`);
      return;
    }
    Linking.openURL(openUrl).catch((e) => {
      console.warn(`[VideoElement] Failed to open URL: ${openUrl}`, e);
    });
  }, [openUrl]);

  if (!Video) {
    console.warn('[VideoElement] VIDEO element requires react-native-video peer dependency. Element will not render.');
    return null;
  }

  if (!url) return null;

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);

  const autoPlay = videoConfig?.autoPlay === 'true' || videoConfig?.autoPlay === undefined;
  const loop = videoConfig?.loop === 'true';
  const muted = videoConfig?.muted === 'true';
  // Controls default to ON, matching iOS/Android PR #15. Only an explicit
  // `"false"` from the JSON suppresses them; missing or any other string
  // value keeps them visible so authors don't have to opt in for the
  // common case.
  const showControls = videoConfig?.showControls !== 'false';

  const errorOverlay = hasError ? (
    <View style={[StyleSheet.absoluteFill, errorOverlayStyle]} pointerEvents="none">
      <Text style={errorTextStyle}>Video playback failed</Text>
    </View>
  ) : null;

  // openUrl binding (PR #15): when present, overlay a Pressable that
  // launches the URL when tapped. The overlay sits on top of the player so
  // it intercepts taps before they reach native controls; that mirrors
  // iOS's "open-url overlay button" behavior.
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
