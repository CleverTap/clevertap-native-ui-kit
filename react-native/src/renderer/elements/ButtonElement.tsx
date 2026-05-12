import React, { useCallback, useRef } from 'react';
import { Pressable, Text } from 'react-native';
import type { TextStyle } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { ActionHandler } from '../../handler/ActionHandler';
import { useRootSize } from '../../context/RootSizeContext';
import { useFontContext, resolveFont } from '../../context/FontContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { resolveTextDim } from '../../utils/dimension';

// Two taps within this window are treated as a double-tap.
// Matches Android's default ViewConfiguration.DOUBLE_TAP_TIMEOUT (300 ms).
const DOUBLE_TAP_WINDOW_MS = 300;

interface ButtonElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
  actionHandler: ActionHandler;
}

export function ButtonElement({ node, resolvedStyle, actionHandler }: ButtonElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const fontCtx = useFontContext();
  const layout = node.layout ?? {};
  const lastTapAt = useRef<number>(0);

  const label = node.bindings?.text ?? '';
  const layoutStyle = resolveLayoutStyle(layout, rootHeight);
  const nodeStyle = resolveNodeStyle(resolvedStyle, rootHeight);

  const fontFamily = resolveFont(resolvedStyle.fontFamily, fontCtx);
  if (fontFamily) {
    nodeStyle.fontFamily = fontFamily;
  }

  // Always emit explicit lineHeight
  if (nodeStyle.lineHeight == null && resolvedStyle.fontSize) {
    const fs = resolveTextDim(resolvedStyle.fontSize, rootHeight) ?? 14;
    nodeStyle.lineHeight = fs * 1.3;
  }

  const textStyle: TextStyle = { ...nodeStyle };

  const handlePress = useCallback(() => {
    const now = Date.now();
    const gap = now - lastTapAt.current;
    lastTapAt.current = now;

    // Always fire unit-clicked system event - matches Android which fires
    // "Notification Clicked" on every button press regardless of action.
    actionHandler.fireClickedEvent(node.id);

    // Double-tap: second tap within the window fires onDoubleTap action.
    // Single-tap always fires onClick action (same-tap semantics as Android
    // combinedClickable which fires both click and doubleClick independently).
    if (gap > 0 && gap < DOUBLE_TAP_WINDOW_MS) {
      const doubleTapAction = node.actions?.onDoubleTap;
      if (doubleTapAction) {
        actionHandler.handle(doubleTapAction, node.id, 'doubleTap');
        return; // skip onClick on the tap that completes a double-tap
      }
    }

    const clickAction = node.actions?.onClick;
    if (clickAction) {
      actionHandler.handle(clickAction, node.id, 'click');
    }
  }, [node, actionHandler]);

  const handleLongPress = useCallback(() => {
    const action = node.actions?.onLongPress;
    if (action) {
      actionHandler.handle(action, node.id, 'longPress');
    }
  }, [node, actionHandler]);

  return (
    <Pressable
      style={[layoutStyle, { alignItems: 'center', justifyContent: 'center' }]}
      onPress={handlePress}
      onLongPress={handleLongPress}
    >
      <Text style={textStyle}>{label}</Text>
    </Pressable>
  );
}
