import React, { useCallback, useRef } from 'react';
import { View, Pressable } from 'react-native';
import type { StyleProp, ViewStyle, LayoutChangeEvent } from 'react-native';
import type { NativeDisplayContainer } from '../models/NativeDisplayNode';
import type { ActionHandler } from '../handler/ActionHandler';

// Two taps within this window count as a double-tap (matches Android's 300 ms default).
const DOUBLE_TAP_WINDOW_MS = 300;

interface TappableContainerProps {
  node: NativeDisplayContainer;
  actionHandler: ActionHandler;
  style?: StyleProp<ViewStyle>;
  onLayout?: (e: LayoutChangeEvent) => void;
  children: React.ReactNode;
}

/**
 * Root view for a container node. It fires the container's own onClick /
 * onDoubleTap / onLongPress actions, the same way ButtonElement does for a
 * button. This matches the native SDKs, where a container with an `actions`
 * map gets a clickable modifier on Android and a tappable modifier on iOS.
 *
 * When the node declares no interaction action, it renders a plain View. So a
 * non-interactive container has no press handler. A scrolling gallery keeps its
 * normal touch behavior unless it opts in with an action.
 *
 * Taps on a child that has its own press handler do not reach this view. React
 * Native grants the touch to the innermost handler. So the child action wins,
 * and the container action fires only on a tap of the container background.
 */
export function TappableContainer({
  node,
  actionHandler,
  style,
  onLayout,
  children,
}: TappableContainerProps): React.ReactElement {
  const lastTapAt = useRef<number>(0);

  const clickAction = node.actions?.onClick;
  const doubleTapAction = node.actions?.onDoubleTap;
  const longPressAction = node.actions?.onLongPress;
  const hasTap = clickAction != null || doubleTapAction != null;
  const hasLongPress = longPressAction != null;

  const handlePress = useCallback(() => {
    const now = Date.now();
    const gap = now - lastTapAt.current;
    lastTapAt.current = now;

    // Fire the clicked event on every tap (matches Android). Pass the onClick
    // action so element-attribution extras (action_type, wzrk_*, etc.) tag along.
    actionHandler.fireClickedEvent(node.id, clickAction);

    // If this tap completes a double-tap, run onDoubleTap and skip onClick.
    if (gap > 0 && gap < DOUBLE_TAP_WINDOW_MS && doubleTapAction) {
      actionHandler.handle(doubleTapAction, node.id, 'doubleTap');
      return;
    }

    if (clickAction) {
      actionHandler.handle(clickAction, node.id, 'click');
    }
  }, [node.id, clickAction, doubleTapAction, actionHandler]);

  const handleLongPress = useCallback(() => {
    if (longPressAction) {
      actionHandler.handle(longPressAction, node.id, 'longPress');
    }
  }, [node.id, longPressAction, actionHandler]);

  if (!hasTap && !hasLongPress) {
    return (
      <View style={style} onLayout={onLayout}>
        {children}
      </View>
    );
  }

  return (
    <Pressable
      style={style}
      onLayout={onLayout}
      onPress={hasTap ? handlePress : undefined}
      onLongPress={hasLongPress ? handleLongPress : undefined}
    >
      {children}
    </Pressable>
  );
}
