import React, { useState, useEffect } from 'react';
import {
  View,
  Text,
  Button,
  ScrollView,
  SafeAreaView,
  StyleSheet,
  ActivityIndicator,
  TouchableOpacity,
} from 'react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
import type { NativeDisplayBridgeListener, NativeDisplayUnit } from '@clevertap/native-display-sdk';
import { NativeDisplayView } from '@clevertap/native-display-sdk';
import { ALL_CONFIGS } from '../testConfigs/configRegistry';
import { describeConfig } from '../testConfigs/describeConfig';

// ─── Spec panel ──────────────────────────────────────────────────────────────

function SpecPanel({ config }: { config: Record<string, unknown> }): React.ReactElement {
  const [expanded, setExpanded] = useState(false);
  const description = describeConfig(config);

  return (
    <View style={spec.container}>
      <TouchableOpacity
        style={spec.header}
        onPress={() => setExpanded((v) => !v)}
        activeOpacity={0.7}
      >
        <Text style={spec.headerText}>Expected layout {expanded ? '▲' : '▼'}</Text>
      </TouchableOpacity>
      {expanded && (
        <ScrollView
          style={spec.body}
          nestedScrollEnabled
          showsVerticalScrollIndicator={false}
        >
          <Text style={spec.descText}>{description}</Text>
        </ScrollView>
      )}
    </View>
  );
}

const spec = StyleSheet.create({
  container: {
    marginBottom: 12,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    overflow: 'hidden',
    backgroundColor: '#F9FAFB',
  },
  header: {
    paddingHorizontal: 12,
    paddingVertical: 8,
    backgroundColor: '#F3F4F6',
  },
  headerText: {
    fontSize: 14,
    fontWeight: '600',
    color: '#6B7280',
    letterSpacing: 0.3,
  },
  body: {
    maxHeight: 260,
    paddingHorizontal: 12,
    paddingVertical: 8,
  },
  descText: {
    fontSize: 13,
    color: '#374151',
    fontFamily: 'monospace',
    lineHeight: 20,
  },
});

// ─── Main screen ─────────────────────────────────────────────────────────────

export function TestConfigBrowserScreen(): React.ReactElement {
  const [index, setIndex] = useState(0);
  const [unit, setUnit] = useState<NativeDisplayUnit | null>(null);
  const [loading, setLoading] = useState(true);

  const entry = ALL_CONFIGS[index];

  useEffect(() => {
    setUnit(null);
    setLoading(true);

    const json = JSON.stringify({
      wzrk_id: entry.id,
      slot_id: 'browser',
      ...entry.config,
    });

    NativeDisplayBridge.shared.processDisplayUnit(json);
  }, [index, entry.id, entry.config]);

  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(units: NativeDisplayUnit[]) {
        const match = units.find((u) => u.unitId === entry.id);
        if (match) {
          setUnit(match);
          setLoading(false);
        }
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    return () => {
      NativeDisplayBridge.shared.removeListener(listener);
    };
  }, [index, entry.id]);

  return (
    <SafeAreaView style={styles.container}>
      <View style={styles.header}>
        <Text style={styles.filename}>{entry.filename}</Text>
        <Text style={styles.counter}>
          {index + 1} / {ALL_CONFIGS.length}
        </Text>
      </View>

      <View style={styles.nav}>
        <View style={styles.navButton}>
          <Button
            title="← Prev"
            disabled={index === 0}
            onPress={() => setIndex((i) => i - 1)}
          />
        </View>
        <View style={styles.navButton}>
          <Button
            title="Next →"
            disabled={index === ALL_CONFIGS.length - 1}
            onPress={() => setIndex((i) => i + 1)}
          />
        </View>
      </View>

      <ScrollView style={styles.scroll} contentContainerStyle={styles.scrollContent}>
        {loading && (
          <View style={styles.loadingRow}>
            <ActivityIndicator size="small" />
            <Text style={styles.loadingText}>Loading…</Text>
          </View>
        )}
        {unit && <NativeDisplayView unit={unit} />}

        <SpecPanel config={entry.config} />
      </ScrollView>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: '#f5f5f5',
  },
  header: {
    paddingHorizontal: 16,
    paddingTop: 12,
    paddingBottom: 4,
  },
  filename: {
    fontSize: 14,
    fontWeight: '600',
    color: '#333',
  },
  counter: {
    fontSize: 12,
    color: '#888',
    marginTop: 2,
  },
  nav: {
    flexDirection: 'row',
    paddingHorizontal: 12,
    paddingBottom: 12,
    gap: 12,
  },
  navButton: {
    flex: 1,
  },
  scroll: {
    flex: 1,
  },
  scrollContent: {
    padding: 16,
  },
  loadingRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
    padding: 16,
  },
  loadingText: {
    fontSize: 13,
    color: '#888',
  },
});
