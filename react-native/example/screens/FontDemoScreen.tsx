import React, { useEffect, useState } from 'react';
import {
  View,
  Text,
  ScrollView,
  StyleSheet,
  Platform,
} from 'react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
import type {
  NativeDisplayBridgeListener,
  NativeDisplayUnit,
} from '@clevertap/native-display-sdk';

// The "Go Premium" banner showcases rich typography - same banner used on Android and iOS.
// eslint-disable-next-line @typescript-eslint/no-require-imports
const BANNER_CONFIG = require('../../../test-configs/banner-09-premium-subscription.json') as Record<string, unknown>;

// Three different unit IDs so the bridge treats them as separate cached units.
const UNIT_ID_A = 'font-demo-a';
const UNIT_ID_B = 'font-demo-b';
const UNIT_ID_C = 'font-demo-c';

// ─── Font demo section ────────────────────────────────────────────────────────

interface SectionProps {
  title: string;
  note: string;
  unitId: string;
  fontResolver?: (fontFamily: string) => string;
}

function FontDemoSection({ title, note, unitId, fontResolver }: SectionProps): React.ReactElement {
  const [unit, setUnit] = useState<NativeDisplayUnit | null>(null);

  useEffect(() => {
    // Process the banner with a unique unit ID so each section is independent
    const json = JSON.stringify({ wzrk_id: unitId, ...BANNER_CONFIG });
    NativeDisplayBridge.shared.processDisplayUnit(json);
  }, [unitId]);

  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(units: NativeDisplayUnit[]) {
        const match = units.find((u) => u.unitId === unitId);
        if (match) setUnit(match);
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    return () => NativeDisplayBridge.shared.removeListener(listener);
  }, [unitId]);

  return (
    <View style={styles.section}>
      <View style={styles.sectionHeader}>
        <Text style={styles.sectionTitle}>{title}</Text>
        <Text style={styles.sectionNote}>{note}</Text>
      </View>
      <View style={styles.bannerWrap}>
        {unit ? (
          <NativeDisplayView
            unit={unit}
            fontResolver={fontResolver}
            style={styles.unitView}
          />
        ) : (
          <View style={styles.placeholder}>
            <Text style={styles.placeholderText}>Loading...</Text>
          </View>
        )}
      </View>
    </View>
  );
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export function FontDemoScreen(): React.ReactElement {
  return (
    <ScrollView style={styles.root} contentContainerStyle={styles.content}>

      <Text style={styles.heading}>Font resolver</Text>
      <Text style={styles.subheading}>
        The same banner rendered with three different font configurations.
        Matches the FontDemo screen in the Android and iOS sample apps.
      </Text>

      {/* Section A - system default */}
      <FontDemoSection
        title="A - System default"
        note="No fontResolver - uses the device's default font."
        unitId={UNIT_ID_A}
      />

      {/* Section B - single override */}
      <FontDemoSection
        title="B - Client override"
        note={`fontResolver returns "${Platform.OS === 'ios' ? 'Georgia' : 'serif'}" for every family.`}
        unitId={UNIT_ID_B}
        fontResolver={() => Platform.OS === 'ios' ? 'Georgia' : 'serif'}
      />

      {/* Section C - per-family mapping */}
      <FontDemoSection
        title="C - Per-family mapping"
        note='fontResolver maps "mono" → monospace font, everything else → serif.'
        unitId={UNIT_ID_C}
        fontResolver={(family: string) => {
          if (family.toLowerCase().includes('mono')) {
            return Platform.OS === 'ios' ? 'Courier' : 'monospace';
          }
          return Platform.OS === 'ios' ? 'Georgia' : 'serif';
        }}
      />

    </ScrollView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  content: {
    padding: 16,
    gap: 16,
    paddingBottom: 32,
  },
  heading: {
    fontSize: 20,
    fontWeight: '700',
    color: '#111827',
  },
  subheading: {
    fontSize: 13,
    color: '#6B7280',
    lineHeight: 18,
  },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    overflow: 'hidden',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.06, shadowRadius: 3 },
      android: { elevation: 1 },
    }),
  },
  sectionHeader: {
    padding: 14,
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
    backgroundColor: '#F9FAFB',
  },
  sectionTitle: {
    fontSize: 14,
    fontWeight: '700',
    color: '#111827',
    marginBottom: 2,
  },
  sectionNote: {
    fontSize: 12,
    color: '#6B7280',
    lineHeight: 17,
  },
  bannerWrap: {
    padding: 12,
  },
  unitView: {
    width: '100%',
  },
  placeholder: {
    height: 80,
    alignItems: 'center',
    justifyContent: 'center',
  },
  placeholderText: {
    fontSize: 13,
    color: '#9CA3AF',
  },
});
