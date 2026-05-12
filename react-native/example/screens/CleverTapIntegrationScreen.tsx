import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  TextInput,
  Button,
  ScrollView,
  SafeAreaView,
  StyleSheet,
  Linking,
  KeyboardAvoidingView,
  Platform,
} from 'react-native';
import CleverTap from 'clevertap-react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
import type {
  NativeDisplayBridgeListener,
  NativeDisplayUnit,
  NativeDisplayActionListener,
} from '@clevertap/native-display-sdk';

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timestamp(): string {
  return new Date().toLocaleTimeString('en-GB', {
    hour12: false,
    // @ts-ignore - fractionalSecondDigits is valid but some TS libs lack it
    fractionalSecondDigits: 3,
  });
}

function logColor(entry: string): string {
  if (entry.includes('Received')) return '#A8D5A2';
  if (entry.includes('EVENT')) return '#FFD700';
  if (entry.includes('ACTION')) return '#82CFFD';
  if (entry.includes('ERROR')) return '#F0A0A0';
  return '#80CCC4';
}

// ─── Screen ───────────────────────────────────────────────────────────────────

export function CleverTapIntegrationScreen(): React.ReactElement {
  const [units, setUnits] = useState<NativeDisplayUnit[]>([]);
  const [log, setLog] = useState<string[]>([]);
  const [eventName, setEventName] = useState('');
  const [bridgeBound, setBridgeBound] = useState(false);

  const ctAvailable = typeof (CleverTap as unknown as Record<string, unknown>).recordEvent === 'function';

  const appendLog = useCallback((message: string) => {
    setLog((prev) => [`[${timestamp()}] ${message}`, ...prev]);
  }, []);

  // Wire CleverTap to the bridge once on mount
  useEffect(() => {
    try {
      NativeDisplayBridge.shared.bind(CleverTap);
      setBridgeBound(true);
      appendLog('Bridge bound to CleverTap');
    } catch (e) {
      appendLog(`ERROR binding bridge: ${String(e)}`);
    }
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Register bridge listener
  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(incoming: NativeDisplayUnit[]) {
        setUnits(incoming);
        appendLog(`Received ${incoming.length} display unit(s)`);
        incoming.forEach((u) => appendLog(`  unit: ${u.unitId}`));
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    appendLog('Bridge listener registered');
    return () => {
      NativeDisplayBridge.shared.removeListener(listener);
      appendLog('Bridge listener removed');
    };
  }, [appendLog]);

  const actionListener: NativeDisplayActionListener = {
    onOpenUrl(url: string): boolean {
      appendLog(`ACTION openUrl: ${url}`);
      Linking.openURL(url).catch(() => appendLog(`ERROR could not open URL: ${url}`));
      return true;
    },
    onCustomAction(key: string, value: unknown): void {
      appendLog(`ACTION custom: ${key} = ${JSON.stringify(value)}`);
    },
    onNavigate(destination: string): void {
      appendLog(`ACTION navigate: ${destination}`);
    },
    onTrackEvent(name: string, properties?: Record<string, unknown>): void {
      appendLog(`EVENT ${name}${properties ? ` ${JSON.stringify(properties)}` : ''}`);
      (CleverTap as unknown as { recordEvent: (n: string, p?: Record<string, unknown>) => void })
        .recordEvent(name, properties ?? {});
    },
    onDisplayUnitViewed(unitId: string): void {
      appendLog(`Viewed unit: ${unitId}`);
    },
    onDisplayUnitClicked(unitId: string): void {
      appendLog(`Clicked unit: ${unitId}`);
    },
  };

  function sendEvent() {
    const name = eventName.trim();
    if (!name || !ctAvailable) return;
    (CleverTap as unknown as { recordEvent: (n: string) => void }).recordEvent(name);
    appendLog(`Sent EVENT: ${name}`);
    setEventName('');
  }

  return (
    <SafeAreaView style={styles.root}>
      <KeyboardAvoidingView
        style={styles.root}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {/* Status row */}
        <View style={styles.statusRow}>
          <StatusBadge label="CleverTap" ok={ctAvailable} />
          <StatusBadge label="Bridge" ok={bridgeBound} />
        </View>

        <View style={styles.divider} />

        {/* Event input */}
        <View style={styles.eventSection}>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Enter event name"
              placeholderTextColor="#999"
              value={eventName}
              onChangeText={setEventName}
              onSubmitEditing={sendEvent}
              returnKeyType="send"
            />
            <View style={styles.sendBtn}>
              <Button
                title="Send Event"
                onPress={sendEvent}
                disabled={!eventName.trim() || !ctAvailable}
              />
            </View>
          </View>
          <Text style={styles.canvasLabel}>Native Display Canvas</Text>
        </View>

        <View style={styles.divider} />

        {/* Display canvas */}
        <View style={styles.canvas}>
          {units.length === 0 ? (
            <View style={styles.emptyState}>
              <Text style={styles.emptyIcon}>📥</Text>
              <Text style={styles.emptyText}>Waiting for Native Display response...</Text>
            </View>
          ) : (
            <ScrollView contentContainerStyle={styles.canvasScroll}>
              {units.map((unit) => (
                <NativeDisplayView
                  key={unit.unitId}
                  unit={unit}
                  actionListener={actionListener}
                  style={styles.unitView}
                />
              ))}
            </ScrollView>
          )}
        </View>

        <View style={styles.divider} />

        {/* Event log */}
        <View style={styles.logSection}>
          <View style={styles.logHeader}>
            <Text style={styles.logTitle}>📄 Event Log</Text>
            {log.length > 0 && (
              <Button title="Clear" onPress={() => setLog([])} />
            )}
          </View>
          <ScrollView style={styles.logScroll} contentContainerStyle={styles.logContent}>
            {log.length === 0 ? (
              <Text style={styles.logEmpty}>No events yet</Text>
            ) : (
              log.map((entry, i) => (
                <Text key={i} style={[styles.logEntry, { color: logColor(entry) }]}>
                  {entry}
                </Text>
              ))
            )}
          </ScrollView>
        </View>
      </KeyboardAvoidingView>
    </SafeAreaView>
  );
}

// ─── Status badge ─────────────────────────────────────────────────────────────

function StatusBadge({ label, ok }: { label: string; ok: boolean }): React.ReactElement {
  return (
    <View style={badge.container}>
      <Text style={[badge.dot, ok ? badge.dotOk : badge.dotErr]}>{ok ? '✓' : '✗'}</Text>
      <Text style={badge.label}>{label}</Text>
      <Text style={[badge.status, ok ? badge.statusOk : badge.statusErr]}>
        {ok ? 'Available' : 'Not configured'}
      </Text>
    </View>
  );
}

const badge = StyleSheet.create({
  container: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 4,
    paddingHorizontal: 12,
    paddingVertical: 4,
    backgroundColor: '#F3F4F6',
    borderRadius: 6,
  },
  dot: { fontSize: 13, fontWeight: '700' },
  dotOk: { color: '#22C55E' },
  dotErr: { color: '#EF4444' },
  label: { fontSize: 12, fontWeight: '600', color: '#374151' },
  status: { fontSize: 12 },
  statusOk: { color: '#22C55E' },
  statusErr: { color: '#EF4444' },
});

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F9FAFB',
  },
  divider: {
    height: 1,
    backgroundColor: '#E5E7EB',
  },
  statusRow: {
    flexDirection: 'row',
    gap: 8,
    padding: 10,
  },
  eventSection: {
    padding: 10,
    gap: 8,
  },
  inputRow: {
    flexDirection: 'row',
    alignItems: 'center',
    gap: 8,
  },
  input: {
    flex: 1,
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    paddingHorizontal: 12,
    paddingVertical: 8,
    fontSize: 14,
    color: '#111827',
    backgroundColor: '#FFFFFF',
  },
  sendBtn: {
    minWidth: 100,
  },
  canvasLabel: {
    fontSize: 13,
    fontWeight: '600',
    color: '#374151',
  },
  canvas: {
    flex: 1,
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 32,
  },
  emptyIcon: {
    fontSize: 28,
  },
  emptyText: {
    fontSize: 14,
    color: '#9CA3AF',
    textAlign: 'center',
  },
  canvasScroll: {
    padding: 12,
    gap: 12,
  },
  unitView: {
    width: '100%',
  },
  logSection: {
    maxHeight: 180,
    paddingHorizontal: 12,
    paddingTop: 6,
    paddingBottom: 8,
  },
  logHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    marginBottom: 4,
  },
  logTitle: {
    fontSize: 13,
    fontWeight: '600',
    color: '#374151',
  },
  logScroll: {
    backgroundColor: '#1E2A33',
    borderRadius: 8,
    maxHeight: 140,
  },
  logContent: {
    padding: 10,
    gap: 1,
  },
  logEmpty: {
    fontSize: 11,
    color: '#6B7280',
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  logEntry: {
    fontSize: 11,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    lineHeight: 17,
  },
});
