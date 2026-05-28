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

// Two taps within this window count as a double-tap.
// Matches Android's default ViewConfiguration.DOUBLE_TAP_TIMEOUT (300 ms).
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

  // Always set an explicit lineHeight
  if (nodeStyle.lineHeight == null && resolvedStyle.fontSize) {
    const fs = resolveTextDim(resolvedStyle.fontSize, rootHeight) ?? 14;
    nodeStyle.lineHeight = fs * 1.3;
  }

  // Split nodeStyle: view-level props (backgroundColor, borderRadius*,
  // borderWidth, borderColor, overflow, opacity, shadow*, elevation) go on
  // the Pressable; text-level props (color, font*, letterSpacing, textAlign,
  // textShadow*, etc) go on the inner Text. Without this split, borderColor/
  // borderWidth paint a stroke around the label's glyph box instead of
  // around the button's full layout footprint.
  const { viewStyle, textStyle } = splitNodeStyle(nodeStyle as Record<string, unknown>);

  const handlePress = useCallback(() => {
    const now = Date.now();
    const gap = now - lastTapAt.current;
    lastTapAt.current = now;

    // Always fire the unit-clicked event - matches Android which fires
    // "Notification Clicked" on every button press regardless of action type.
    actionHandler.fireClickedEvent(node.id);

    // Double-tap: if the second tap lands within the window, fire onDoubleTap.
    // A single tap always fires onClick (matches Android combinedClickable
    // which fires both click and doubleClick independently on the same tap).
    if (gap > 0 && gap < DOUBLE_TAP_WINDOW_MS) {
      const doubleTapAction = node.actions?.onDoubleTap;
      if (doubleTapAction) {
        actionHandler.handle(doubleTapAction, node.id, 'doubleTap');
        return; // skip onClick for the tap that completes the double-tap
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
