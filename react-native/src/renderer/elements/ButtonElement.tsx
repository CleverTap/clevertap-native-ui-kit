import React, { useCallback, useRef } from 'react';
import { Pressable, Text } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { ActionHandler } from '../../handler/ActionHandler';
import { useRootSize } from '../../context/RootSizeContext';
import { useFontContext, resolveFont } from '../../context/FontContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { splitNodeStyle } from '../styleSplit';
import { resolveTextDim } from '../../utils/dimension';

// Two taps within this window count as a double-tap (matches Android's 300 ms default).
const DOUBLE_TAP_WINDOW_MS = 300;

interface ButtonElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
  actionHandler: ActionHandler;
}

export const ButtonElement = React.memo(function ButtonElement({ node, resolvedStyle, actionHandler }: ButtonElementProps): React.ReactElement {
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

  // Always set an explicit lineHeight.
  if (nodeStyle.lineHeight == null && resolvedStyle.fontSize) {
    const fs = resolveTextDim(resolvedStyle.fontSize, rootHeight) ?? 14;
    nodeStyle.lineHeight = fs * 1.3;
  }

  // Split the style: view props (background, border, shadow, etc.) go on the
  // Pressable, text props (color, font, etc.) go on the inner Text. Without this,
  // the border would wrap the label text instead of the whole button.
  const { viewStyle, textStyle } = splitNodeStyle(nodeStyle as Record<string, unknown>);

  const handlePress = useCallback(() => {
    const now = Date.now();
    const gap = now - lastTapAt.current;
    lastTapAt.current = now;

    // Fire the clicked event on every tap (matches Android). Pass the onClick
    // action so element-attribution extras (action_type, wzrk_*, etc.) tag along.
    const clickAction = node.actions?.onClick;
    actionHandler.fireClickedEvent(node.id, clickAction);

    // If this tap completes a double-tap, run onDoubleTap and skip onClick.
    if (gap > 0 && gap < DOUBLE_TAP_WINDOW_MS) {
      const doubleTapAction = node.actions?.onDoubleTap;
      if (doubleTapAction) {
        actionHandler.handle(doubleTapAction, node.id, 'doubleTap');
        return;
      }
    }

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

  const pressableStyle: ViewStyle = {
    ...layoutStyle,
    ...viewStyle,
    alignItems: 'center',
    justifyContent: 'center',
  };

  return (
    <Pressable
      style={pressableStyle}
      onPress={handlePress}
      onLongPress={handleLongPress}
    >
      <Text style={textStyle}>{label}</Text>
    </Pressable>
  );
});
