import React from 'react';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { getVideo } from '../../optional/optionalDeps';
import { useRootSize } from '../../context/RootSizeContext';
import { resolveLayoutStyle } from '../layoutModifier';

interface VideoElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
}

export const VideoElement = React.memo(function VideoElement({ node, resolvedStyle }: VideoElementProps): React.ReactElement | null {
  const { height: rootHeight } = useRootSize();
  const Video = getVideo();

  if (!Video) {
    console.warn('[VideoElement] VIDEO element requires react-native-video peer dependency. Element will not render.');
    return null;
  }

  const url = node.bindings?.url ?? '';
  if (!url) return null;

  const layout = node.layout ?? {};
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const videoConfig = node.bindings;

  const autoPlay = videoConfig?.autoPlay === 'true' || videoConfig?.autoPlay === undefined;
  const loop = videoConfig?.loop === 'true';
  const muted = videoConfig?.muted === 'true';
  const showControls = videoConfig?.showControls === 'true';

  return (
    <Video
      source={{ uri: url }}
      style={layoutStyle}
      paused={!autoPlay}
      repeat={loop}
      muted={muted}
      controls={showControls}
      resizeMode="contain"
    />
  );
});
