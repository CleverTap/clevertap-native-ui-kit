import React, { useEffect, useRef, useState } from 'react';
import { View, Dimensions } from 'react-native';
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
import { hasPercentDimensions } from '../utils/dimension';

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

  const needsMeasurement = root != null && !availableSize && hasPercentDimensions(root);

  let rootSize: { width: number; height: number };
  if (availableSize) {
    rootSize = availableSize;
  } else if (!needsMeasurement) {
    rootSize = {
      width: Dimensions.get('window').width,
      height: Dimensions.get('window').height,
    };
  } else {
    rootSize = measuredSize ?? {
      width: Dimensions.get('window').width,
      height: Dimensions.get('window').height,
    };
  }

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
    setMeasuredSize({ width, height });
  };

  // RenderErrorBoundary stops a bad JSON config from crashing the host app.
  // See RenderErrorBoundary.tsx for the full explanation.
  //
  // key={unitId} resets the boundary whenever the active unit changes. An error
  // boundary stays in hasError=true until it unmounts. Without this key,
  // switching from a broken unit to a healthy one would still show the fallback
  // because the same boundary instance is reused.
  const inner = (
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
  );

  if (needsMeasurement && !measuredSize) {
    return (
      <View style={style} onLayout={handleLayout}>
        {inner}
      </View>
    );
  }

  return <View style={style}>{inner}</View>;
}
