import React, { useEffect, useRef, useState } from 'react';
import { View } from 'react-native';
import type { ViewStyle, LayoutChangeEvent } from 'react-native';
import type { NativeDisplayUnit } from '../bridge/NativeDisplayUnit';
import type { NativeDisplayConfig, ResolvedConfig, ResolvedStyles } from '../models/NativeDisplayConfig';
import type { NativeDisplayNode } from '../models/NativeDisplayNode';
import type { NativeDisplayActionListener } from '../listener/NativeDisplayActionListener';
import type { NativeDisplayComponentListener } from '../listener/NativeDisplayComponentListener';
import { NativeDisplayBridge } from '../bridge/NativeDisplayBridge';
import { ActionHandler } from '../handler/ActionHandler';
import { RootSizeProvider } from '../context/RootSizeContext';
import { FontProvider } from '../context/FontContext';
import { VariablesProvider } from '../context/VariablesContext';
import { RenderNode } from './RenderNode';
import { RenderErrorBoundary } from './RenderErrorBoundary';

interface NativeDisplayViewPropsWithUnit {
  unit: NativeDisplayUnit;
  config?: never;
  resolvedStyles?: never;
}

interface NativeDisplayViewPropsWithConfig {
  unit?: never;
  config: NativeDisplayConfig;
  resolvedStyles: ResolvedStyles;
}

type NativeDisplayViewProps = (NativeDisplayViewPropsWithUnit | NativeDisplayViewPropsWithConfig) & {
  availableSize?: { width: number; height: number };
  actionListener?: NativeDisplayActionListener;
  componentListener?: NativeDisplayComponentListener;
  fontResolver?: (fontFamily: string) => string;
  // Layer-1 client font. When set, it wins over the JSON fontFamily and the
  // fontResolver, matching iOS `nativeDisplayFontFamily` and Android
  // `LocalFontFamily`. Use it to force one font across iOS, Android, and RN.
  defaultFontFamily?: string;
  style?: ViewStyle;
};

export function NativeDisplayView(props: NativeDisplayViewProps): React.ReactElement | null {
  const {
    availableSize,
    actionListener = null,
    componentListener = null,
    fontResolver,
    defaultFontFamily,
    style,
  } = props;

  // Hooks must run every render, no matter the props.
  const [measuredSize, setMeasuredSize] = useState<{ width: number; height: number } | null>(null);

  // Keep the listener in a ref so the effect can call it without listing it as
  // a dep. Hosts usually pass a new listener each render, and if it were a dep
  // the effect would re-run every render and re-fire "Notification Viewed".
  const actionListenerRef = useRef(actionListener);
  actionListenerRef.current = actionListener;

  let unitId: string;
  let root: NativeDisplayNode | undefined;
  let resolvedStyles: ResolvedStyles;
  let variables: Record<string, unknown>;

  if (props.unit) {
    const resolved = props.unit.config as ResolvedConfig;
    unitId = props.unit.unitId;
    root = resolved.root;
    resolvedStyles = props.unit.resolvedStyles;
    variables = resolved.variables ?? {};
  } else {
    const cfg = props.config as NativeDisplayConfig;
    unitId = '';
    root = cfg.root;
    resolvedStyles = props.resolvedStyles;
    variables = cfg.variables ?? {};
  }

  // rootSize is the reference size for percent dimensions. It must match the
  // real width of the wrapper View, or BoxContainer's absolute children drift.
  // We measure via onLayout instead of the window size, since host padding or
  // margins make the window wrong. Hosts can skip measuring via availableSize.
  const rootSize = availableSize ?? measuredSize;

  useEffect(() => {
    if (!unitId || !root) return;
    // Fire once when the unit appears. The bridge tracker dedupes, so a plain
    // re-render won't fire it again.
    NativeDisplayBridge.shared.pushViewedEvent(unitId);
    actionListenerRef.current?.onDisplayUnitViewed?.(unitId);
    actionListenerRef.current?.onTrackEvent?.('Notification Viewed', undefined);

    // On unmount, release the unit so a later remount (scrolled back in,
    // navigated back to) fires Viewed again. Keyed on [unitId, root] only
    // (not actionListener) so it runs on a real unmount / unit swap, not
    // every render - rotations re-render without unmounting.
    return () => {
      NativeDisplayBridge.shared.releaseViewedUnit(unitId);
    };
  }, [unitId, root]);

  if (!root) return null;

  const actionHandler = new ActionHandler(
    actionListener,
    componentListener,
    unitId ? NativeDisplayBridge.shared : null,
    unitId,
  );

  const handleLayout = (event: LayoutChangeEvent) => {
    const { width, height } = event.nativeEvent.layout;
    // Only update if the size changed, to avoid re-render loops.
    setMeasuredSize((prev) =>
      prev && prev.width === width && prev.height === height
        ? prev
        : { width, height },
    );
  };

  // First render, before we've measured: show an empty wrapper just to capture
  // the real size. Rendering content now with a guessed size would flash the
  // wrong layout for a frame.
  if (!rootSize) {
    return <View style={style} onLayout={handleLayout} />;
  }

  // RenderErrorBoundary keeps bad JSON from crashing the host app (see that
  // file for details). key={unitId} gives each unit a fresh boundary, since a
  // tripped boundary stays broken until it unmounts - without the key, a broken
  // unit's fallback would linger after switching to a healthy one.
  // Keep onLayout attached (unless availableSize is given) so rotations and
  // resizes re-measure.
  //
  // Explicit width pins the outer View to the measured pixel width. Without it,
  // root containers with width: 100% collapse to wrap_content on iOS, because
  // Yoga only resolves percentages against a parent with a defined width.
  return (
    <View
      style={[{ width: rootSize.width }, style]}
      onLayout={availableSize ? undefined : handleLayout}
    >
      <RenderErrorBoundary key={unitId || 'default'}>
        <RootSizeProvider size={rootSize}>
          <FontProvider fontResolver={fontResolver} defaultFontFamily={defaultFontFamily}>
            <VariablesProvider variables={variables}>
              <RenderNode
                node={root}
                resolvedStyles={resolvedStyles}
                actionHandler={actionHandler}
              />
            </VariablesProvider>
          </FontProvider>
        </RootSizeProvider>
      </RenderErrorBoundary>
    </View>
  );
}
