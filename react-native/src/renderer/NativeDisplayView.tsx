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
  style?: ViewStyle;
};

export function NativeDisplayView(props: NativeDisplayViewProps): React.ReactElement | null {
  const {
    availableSize,
    actionListener = null,
    componentListener = null,
    fontResolver,
    style,
  } = props;

  // Hooks must always be called, regardless of props
  const [measuredSize, setMeasuredSize] = useState<{ width: number; height: number } | null>(null);
  const viewedRef = useRef(false);

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

  // rootSize is the reference width/height for resolving percent dimensions inside
  // the unit. It MUST match the actual rendered width of the outer wrapper View,
  // otherwise BoxContainer's `boxSize` (computed against rootWidth) diverges from
  // the View's CSS-derived size (Yoga's "80%" of the actual parent), and the
  // absolutely-positioned children drift relative to the container.
  //
  // We measure via onLayout instead of falling back to Dimensions.get('window'),
  // because any host wrapping (padding, margin, sidebar, etc.) makes the window
  // size wrong. The host can short-circuit measurement by passing availableSize.
  const rootSize = availableSize ?? measuredSize;

  useEffect(() => {
    if (viewedRef.current || !unitId || !root) return;
    viewedRef.current = true;
    NativeDisplayBridge.shared.pushViewedEvent(unitId);
    actionListener?.onDisplayUnitViewed?.(unitId);
    actionListener?.onTrackEvent?.('Notification Viewed', undefined);
  }, [unitId, actionListener, root]);

  if (!root) return null;

  const actionHandler = new ActionHandler(
    actionListener,
    componentListener,
    unitId ? NativeDisplayBridge.shared : null,
    unitId,
  );

  const handleLayout = (event: LayoutChangeEvent) => {
    const { width, height } = event.nativeEvent.layout;
    // Only update if changed, to avoid re-render loops when the layout settles.
    setMeasuredSize((prev) =>
      prev && prev.width === width && prev.height === height
        ? prev
        : { width, height },
    );
  };

  // First render (no availableSize, not yet measured): render an empty wrapper
  // to capture the real available size. Rendering content here with fallback
  // window dims would force a re-layout one frame later AND show the wrong
  // size briefly.
  if (!rootSize) {
    return <View style={style} onLayout={handleLayout} />;
  }

  // RenderErrorBoundary stops a bad JSON config from crashing the host app.
  // See RenderErrorBoundary.tsx for the full explanation.
  //
  // key={unitId} resets the boundary whenever the active unit changes. An error
  // boundary stays in hasError=true until it unmounts. Without this key,
  // switching from a broken unit to a healthy one would still show the fallback
  // because the same boundary instance is reused.
  // Keep onLayout attached (unless availableSize is provided) so rotations or
  // parent resizes re-measure and rootSize stays accurate.
  //
  // Explicit `width: rootSize.width` pins the outer View to the measured pixel
  // width. Without this, root containers that declare `width: 100%` collapse to
  // wrap_content on iOS - Yoga resolves percentages against the parent's defined
  // width, and stretch-only sizing (the ScrollView alignItems default) is not
  // counted as "defined". The visible symptom: a horizontal container's flow
  // children measure to their own intrinsic widths, the container shrinks to
  // hug them, and the background (also 100%) only covers the text portion while
  // a sibling image overflows past it.
  return (
    <View
      style={[{ width: rootSize.width }, style]}
      onLayout={availableSize ? undefined : handleLayout}
    >
      <RenderErrorBoundary key={unitId || 'default'}>
        <RootSizeProvider size={rootSize}>
          <FontProvider fontResolver={fontResolver}>
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
