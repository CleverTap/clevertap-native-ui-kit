import React, { useEffect, useRef, useState } from 'react';
import { View } from 'react-native';
import type { ViewStyle } from 'react-native';
import type { NativeDisplayUnit } from '../bridge/NativeDisplayUnit';
import type { NativeDisplayActionListener } from '../listener/NativeDisplayActionListener';
import type { NativeDisplayComponentListener } from '../listener/NativeDisplayComponentListener';
import type { NativeDisplaySlotObserver } from './NativeDisplaySlotManager';
import { NativeDisplaySlotManager } from './NativeDisplaySlotManager';
import { NativeDisplayView } from '../renderer/NativeDisplayView';

export interface NativeDisplaySlotProps {
  slotId: string;
  placeholder?: React.ReactNode;
  actionListener?: NativeDisplayActionListener;
  componentListener?: NativeDisplayComponentListener;
  fontResolver?: (fontFamily: string) => string;
  style?: ViewStyle;
}

export function NativeDisplaySlot({
  slotId,
  placeholder,
  actionListener,
  componentListener,
  fontResolver,
  style,
}: NativeDisplaySlotProps): React.ReactElement {
  const [unit, setUnit] = useState<NativeDisplayUnit | null>(() =>
    NativeDisplaySlotManager.shared.getUnit(slotId),
  );

  const observerRef = useRef<NativeDisplaySlotObserver>({
    onUnitAvailable(incoming: NativeDisplayUnit) {
      setUnit(incoming);
    },
    onUnitCleared(_slotId: string) {
      setUnit(null);
    },
  });

  useEffect(() => {
    const observer = observerRef.current;
    NativeDisplaySlotManager.shared.registerSlot(slotId, observer);
    return () => {
      NativeDisplaySlotManager.shared.unregisterSlot(slotId, observer);
    };
  }, [slotId]);

  if (!unit) {
    if (placeholder) {
      return <View style={style}>{placeholder}</View>;
    }
    return <View style={style} />;
  }

  return (
    <NativeDisplayView
      unit={unit}
      actionListener={actionListener}
      componentListener={componentListener}
      fontResolver={fontResolver}
      style={style}
    />
  );
}
