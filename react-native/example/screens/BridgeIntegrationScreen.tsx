import React, { useEffect, useRef, useState } from 'react';
import {
  Button,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  View,
} from 'react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
import type {
  NativeDisplayBridgeListener,
  NativeDisplayUnit,
} from '@clevertap/native-display-sdk';

// Load test configs from the shared test-configs/ directory at the repo root.
// Each file contains a bare NativeDisplayConfig (no wzrk_id/slot_id).
// We wrap them with the required envelope fields before feeding to the bridge.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const config1 = require('../../../test-configs/test-001-vertical-simple.json') as Record<string, unknown>;
// eslint-disable-next-line @typescript-eslint/no-require-imports
const config2 = require('../../../test-configs/test-002-horizontal-simple.json') as Record<string, unknown>;
// eslint-disable-next-line @typescript-eslint/no-require-imports
const config3 = require('../../../test-configs/test-003-box-simple.json') as Record<string, unknown>;

const MOCK_UNIT_1 = JSON.stringify({ wzrk_id: 'demo_unit_1', slot_id: 'banner', ...config1 });
const MOCK_UNIT_2 = JSON.stringify({ wzrk_id: 'demo_unit_2', slot_id: 'card',   ...config2 });
const MOCK_UNIT_3 = JSON.stringify({ wzrk_id: 'demo_unit_3', slot_id: 'promo',  ...config3 });

export function BridgeIntegrationScreen(): React.ReactElement {
  const [units, setUnits] = useState<NativeDisplayUnit[]>([]);

  const listenerRef = useRef<NativeDisplayBridgeListener>({
    onNativeDisplaysLoaded(incoming: NativeDisplayUnit[]) {
      for (const u of incoming) {
        console.log(
          `[BridgeIntegrationScreen] Received unit: ${u.unitId}\n` +
          `  slotId: ${u.slotId ?? '—'}\n` +
          `  config.root.type: ${u.config.root.type} / ${(u.config.root as unknown as Record<string,unknown>).containerType ?? (u.config.root as unknown as Record<string,unknown>).elementType}\n` +
          `  resolvedStyles keys: ${Object.keys(u.resolvedStyles).join(', ')}\n` +
          `  resolvedStyles:\n${JSON.stringify(u.resolvedStyles, null, 4)}\n` +
          `  config.root:\n${JSON.stringify(u.config.root, null, 4)}`,
        );
      }
      setUnits(prev => {
        const map = new Map(prev.map(u => [u.unitId, u]));
        for (const u of incoming) {
          map.set(u.unitId, u);
        }
        return Array.from(map.values());
      });
    },
  });

  useEffect(() => {
    const listener = listenerRef.current;
    NativeDisplayBridge.shared.addListener(listener);
    return () => {
      NativeDisplayBridge.shared.removeListener(listener);
    };
  }, []);

  function simulate1Unit(): void {
    NativeDisplayBridge.shared.processDisplayUnit(MOCK_UNIT_1);
  }

  function simulate3Units(): void {
    NativeDisplayBridge.shared.processDisplayUnits([MOCK_UNIT_1, MOCK_UNIT_2, MOCK_UNIT_3]);
  }

  function clear(): void {
    setUnits([]);
  }

  return (
    <SafeAreaView style={styles.safeArea}>
      <ScrollView contentContainerStyle={styles.scroll}>
        <Text style={styles.heading}>Bridge Integration</Text>
        <Text style={styles.subtitle}>
          Feed mock JSON into NativeDisplayBridge and render the parsed units below.
        </Text>

        <View style={styles.buttons}>
          <View style={styles.buttonWrap}>
            <Button title="Simulate 1 Unit" onPress={simulate1Unit} />
          </View>
          <View style={styles.buttonWrap}>
            <Button title="Simulate 3 Units" onPress={simulate3Units} />
          </View>
          <View style={styles.buttonWrap}>
            <Button title="Clear" color="#E53935" onPress={clear} />
          </View>
        </View>

        {units.length === 0 ? (
          <Text style={styles.empty}>No units yet. Tap a button above.</Text>
        ) : (
          units.map(unit => (
            <View key={unit.unitId} style={styles.unitWrap}>
              <NativeDisplayView unit={unit} />
              <Text style={styles.meta}>
                {unit.unitId} {unit.slotId ? `· slot: ${unit.slotId}` : ''}
              </Text>
            </View>
          ))
        )}
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  safeArea: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  scroll: {
    padding: 16,
    gap: 16,
  },
  heading: {
    fontSize: 24,
    fontWeight: 'bold',
    color: '#212121',
  },
  subtitle: {
    fontSize: 14,
    color: '#616161',
    lineHeight: 20,
  },
  buttons: {
    gap: 8,
  },
  buttonWrap: {
    borderRadius: 8,
    overflow: 'hidden',
  },
  empty: {
    fontSize: 14,
    color: '#9E9E9E',
    textAlign: 'center',
    marginTop: 32,
  },
  unitWrap: {
    borderRadius: 8,
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
    shadowColor: '#000',
    shadowOffset: { width: 0, height: 2 },
    shadowOpacity: 0.08,
    shadowRadius: 4,
    elevation: 2,
  },
  meta: {
    fontSize: 11,
    color: '#9E9E9E',
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#FAFAFA',
  },
});
