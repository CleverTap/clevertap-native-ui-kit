import React, { useCallback } from 'react';
import { Pressable, Text } from 'react-native';
import type { TextStyle } from 'react-native';
import type { NativeDisplayElement } from '../../models/NativeDisplayNode';
import type { Style } from '../../models/Style';
import { ActionHandler } from '../../handler/ActionHandler';
import { useRootSize } from '../../context/RootSizeContext';
import { useFontContext, resolveFont } from '../../context/FontContext';
import { resolveLayoutStyle, resolveNodeStyle } from '../layoutModifier';
import { resolveTextDim } from '../../utils/dimension';

interface ButtonElementProps {
  node: NativeDisplayElement;
  resolvedStyle: Partial<Style>;
  actionHandler: ActionHandler;
}

export function ButtonElement({ node, resolvedStyle, actionHandler }: ButtonElementProps): React.ReactElement {
  const { height: rootHeight } = useRootSize();
  const fontCtx = useFontContext();
  const layout = node.layout ?? {};

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
    const action = node.actions?.onClick;
    if (action) {
      actionHandler.handle(action, node.id, 'click');
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
