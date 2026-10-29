import React, { useEffect, useRef, useState, useCallback } from 'react';
import {
  Button,
  Platform,
  SafeAreaView,
  ScrollView,
  StyleSheet,
  Text,
  TextInput,
  TouchableOpacity,
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

// Mock units match the Android bridge_mock_product.json / bridge_mock_notification.json
// and the iOS BridgeIntegrationView inline JSON strings.
// They are inlined here (same pattern as iOS) rather than loaded from assets.

const MOCK_UNIT_1 = JSON.stringify({
  wzrk_id: 'demo_unit_1',
  type: 'native_display',
  native_display_config: {
    theme: { id: 'product-card', defaultStyle: { textColor: '#1F2937', fontSize: 14, lineHeight: 20 } },
    root: {
      type: 'container',
      id: 'product-card-container',
      containerType: 'vertical',
      layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { all: 16 } },
      style: { backgroundColor: '#FFFFFF', borderRadius: 16, shadowRadius: 12, shadowColor: '#000000', shadowOpacity: 0.1, shadowOffsetY: 4 },
      children: [
        {
          type: 'element',
          id: 'product-image',
          elementType: 'image',
          bindings: { url: 'https://yavuzceliker.github.io/sample-images/image-83.jpg' },
          layout: { width: { value: 100, unit: 'percent' }, height: { value: 200, unit: 'dp' } },
          style: { borderRadius: 12 },
        },
        {
          type: 'element',
          id: 'product-name',
          elementType: 'text',
          bindings: { text: 'Premium Wireless Headphones' },
          layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' } },
          style: { fontSize: 20, fontWeight: 'bold', textColor: '#111827', lineHeight: 28 },
        },
        {
          type: 'element',
          id: 'product-price',
          elementType: 'text',
          bindings: { text: '$299.99' },
          layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' } },
          style: { fontSize: 24, fontWeight: 'bold', textColor: '#10B981', lineHeight: 34 },
        },
        {
          type: 'element',
          id: 'buy-button',
          elementType: 'button',
          bindings: { text: 'Add to Cart' },
          layout: { width: { value: 100, unit: 'percent' }, height: { value: 48, unit: 'dp' } },
          style: { backgroundColor: '#3B82F6', borderRadius: 12, textColor: '#FFFFFF', fontSize: 16, fontWeight: 'bold', lineHeight: 22 },
        },
      ],
    },
    styleClasses: [],
    variables: {},
  },
  custom_kv: { campaign: 'summer_sale', category: 'electronics' },
});

const MOCK_UNIT_2 = JSON.stringify({
  wzrk_id: 'demo_unit_2',
  type: 'native_display',
  native_display_config: {
    theme: { id: 'notification', defaultStyle: { textColor: '#1F2937', fontSize: 14, lineHeight: 20 } },
    root: {
      type: 'container',
      id: 'notification-card',
      containerType: 'horizontal',
      layout: {
        width: { value: 100, unit: 'percent' },
        height: { value: -2, unit: 'dp' },
        padding: { all: 16 },
        arrangement: { spacing: 12, strategy: 'spaced' },
      },
      style: { backgroundColor: '#FFFFFF', borderRadius: 12, shadowRadius: 8, shadowColor: '#000000', shadowOpacity: 0.08, shadowOffsetY: 2, borderWidth: 1, borderColor: '#E5E7EB' },
      children: [
        {
          type: 'element',
          id: 'avatar',
          elementType: 'image',
          bindings: { url: 'https://yavuzceliker.github.io/sample-images/image-750.jpg' },
          layout: { width: { value: 48, unit: 'dp' }, height: { value: 48, unit: 'dp' } },
          style: { borderRadius: 24 },
        },
        {
          type: 'container',
          id: 'content',
          containerType: 'vertical',
          layout: { width: { value: -1, unit: 'dp' }, arrangement: { spacing: 4, strategy: 'spaced' } },
          children: [
            {
              type: 'element',
              id: 'sender',
              elementType: 'text',
              bindings: { text: 'Sarah Johnson' },
              layout: { width: { value: 100, unit: 'percent' } },
              style: { fontSize: 16, fontWeight: 'bold', textColor: '#111827', lineHeight: 22 },
            },
            {
              type: 'element',
              id: 'message',
              elementType: 'text',
              bindings: { text: 'Hey! Just wanted to check in about our meeting tomorrow.' },
              layout: { width: { value: 100, unit: 'percent' } },
              style: { fontSize: 14, textColor: '#6B7280', lineHeight: 20 },
            },
            {
              type: 'element',
              id: 'time',
              elementType: 'text',
              bindings: { text: '2 minutes ago' },
              layout: { width: { value: 100, unit: 'percent' } },
              style: { fontSize: 12, textColor: '#9CA3AF', lineHeight: 17 },
            },
          ],
        },
      ],
    },
    styleClasses: [],
    variables: {},
  },
  custom_kv: { campaign: 're_engagement', sender_id: 'user_42' },
});

const MOCK_UNIT_3 = JSON.stringify({
  wzrk_id: 'demo_unit_3',
  type: 'native_display',
  native_display_config: {
    theme: { id: 'stats-card', defaultStyle: { textColor: '#1F2937', fontSize: 14, lineHeight: 20 } },
    root: {
      type: 'container',
      id: 'stats-card',
      containerType: 'vertical',
      layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { all: 16 } },
      style: { backgroundColor: '#FFFFFF', borderRadius: 12, shadowRadius: 8, shadowColor: '#000000', shadowOpacity: 0.08, shadowOffsetY: 2 },
      children: [
        {
          type: 'element',
          id: 'stats-title',
          elementType: 'text',
          bindings: { text: 'Your Weekly Stats' },
          layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' } },
          style: { fontSize: 18, fontWeight: 'bold', textColor: '#111827', lineHeight: 26 },
        },
        {
          type: 'container',
          id: 'stats-row',
          containerType: 'horizontal',
          layout: {
            width: { value: 100, unit: 'percent' },
            height: { value: -2, unit: 'dp' },
            arrangement: { spacing: 8, strategy: 'spaced' },
          },
          children: [
            {
              type: 'container',
              id: 'stat-visits',
              containerType: 'vertical',
              layout: { width: { value: -1, unit: 'dp' }, height: { value: -2, unit: 'dp' } },
              style: { backgroundColor: '#EFF6FF', borderRadius: 8 },
              children: [
                {
                  type: 'element',
                  id: 'visits-value',
                  elementType: 'text',
                  bindings: { text: '142' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { top: 12, left: 12, right: 12, bottom: 4 } },
                  style: { fontSize: 24, fontWeight: 'bold', textColor: '#1D4ED8' },
                },
                {
                  type: 'element',
                  id: 'visits-label',
                  elementType: 'text',
                  bindings: { text: 'Visits' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { bottom: 12, left: 12, right: 12 } },
                  style: { fontSize: 12, textColor: '#3B82F6' },
                },
              ],
            },
            {
              type: 'container',
              id: 'stat-orders',
              containerType: 'vertical',
              layout: { width: { value: -1, unit: 'dp' }, height: { value: -2, unit: 'dp' } },
              style: { backgroundColor: '#F0FDF4', borderRadius: 8 },
              children: [
                {
                  type: 'element',
                  id: 'orders-value',
                  elementType: 'text',
                  bindings: { text: '8' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { top: 12, left: 12, right: 12, bottom: 4 } },
                  style: { fontSize: 24, fontWeight: 'bold', textColor: '#15803D' },
                },
                {
                  type: 'element',
                  id: 'orders-label',
                  elementType: 'text',
                  bindings: { text: 'Orders' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { bottom: 12, left: 12, right: 12 } },
                  style: { fontSize: 12, textColor: '#22C55E' },
                },
              ],
            },
            {
              type: 'container',
              id: 'stat-saved',
              containerType: 'vertical',
              layout: { width: { value: -1, unit: 'dp' }, height: { value: -2, unit: 'dp' } },
              style: { backgroundColor: '#FFF7ED', borderRadius: 8 },
              children: [
                {
                  type: 'element',
                  id: 'saved-value',
                  elementType: 'text',
                  bindings: { text: '$47' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { top: 12, left: 12, right: 12, bottom: 4 } },
                  style: { fontSize: 24, fontWeight: 'bold', textColor: '#C2410C' },
                },
                {
                  type: 'element',
                  id: 'saved-label',
                  elementType: 'text',
                  bindings: { text: 'Saved' },
                  layout: { width: { value: 100, unit: 'percent' }, height: { value: -2, unit: 'dp' }, padding: { bottom: 12, left: 12, right: 12 } },
                  style: { fontSize: 12, textColor: '#F97316' },
                },
              ],
            },
          ],
        },
      ],
    },
    styleClasses: [],
    variables: {},
  },
  custom_kv: { campaign: 'engagement_stats', period: 'weekly' },
});

// ─── Helpers ─────────────────────────────────────────────────────────────────

function timestamp(): string {
  return new Date().toLocaleTimeString('en-GB', {
    hour12: false,
    // @ts-ignore - fractionalSecondDigits is valid but some TS libs lack it
    fractionalSecondDigits: 3,
  });
}

type LogEntry = {
  id: number;
  text: string;
  color: string;
};

let _logId = 0;

function makeEntry(text: string, color: string): LogEntry {
  return { id: _logId++, text: `[${timestamp()}] ${text}`, color };
}

const GREEN = '#A8D5A2';
const RED = '#F0A0A0';
const YELLOW = '#FFD700';
const CYAN = '#80CCC4';

// ─── Screen ───────────────────────────────────────────────────────────────────

export function BridgeIntegrationScreen(): React.ReactElement {
  const [units, setUnits] = useState<NativeDisplayUnit[]>([]);
  const [registered, setRegistered] = useState(false);
  const [pullIdInput, setPullIdInput] = useState('');
  const [logEntries, setLogEntries] = useState<LogEntry[]>([]);

  const appendLog = useCallback((text: string, color: string = CYAN) => {
    setLogEntries((prev) => [makeEntry(text, color), ...prev]);
  }, []);

  const listenerRef = useRef<NativeDisplayBridgeListener>({
    onNativeDisplaysLoaded(incoming: NativeDisplayUnit[]) {
      setUnits((prev) => {
        const map = new Map(prev.map((u) => [u.unitId, u]));
        for (const u of incoming) {
          map.set(u.unitId, u);
        }
        return Array.from(map.values());
      });
      appendLog(`Received ${incoming.length} unit(s): ${incoming.map((u) => u.unitId).join(', ')}`, GREEN);
    },
  });

  function registerListener(): void {
    if (registered) return;
    NativeDisplayBridge.shared.addListener(listenerRef.current);
    setRegistered(true);
    appendLog('Listener registered', GREEN);
  }

  function unregisterListener(): void {
    if (!registered) return;
    NativeDisplayBridge.shared.removeListener(listenerRef.current);
    setRegistered(false);
    appendLog('Listener unregistered');
  }

  // Clean up on unmount
  useEffect(() => {
    return () => {
      if (registered) {
        NativeDisplayBridge.shared.removeListener(listenerRef.current);
      }
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function simulate1Unit(): void {
    appendLog('Processing 1 unit...');
    NativeDisplayBridge.shared.processDisplayUnit(MOCK_UNIT_1);
  }

  function simulate3Units(): void {
    appendLog('Processing 3 units...');
    NativeDisplayBridge.shared.processDisplayUnits([MOCK_UNIT_1, MOCK_UNIT_2, MOCK_UNIT_3]);
  }

  function clearUnits(): void {
    setUnits([]);
    appendLog('Units cleared');
  }

  function getAllDisplays(): void {
    const all = NativeDisplayBridge.shared.getAllNativeDisplays();
    appendLog(`getAllNativeDisplays() → ${all.length} unit(s)`, YELLOW);
    all.forEach((u) => appendLog(`  ${u.unitId}`, YELLOW));
  }

  function getDisplayForId(): void {
    const id = pullIdInput.trim();
    if (!id) return;
    const unit = NativeDisplayBridge.shared.getNativeDisplayForId(id);
    if (unit) {
      appendLog(`getNativeDisplayForId("${id}") → found`, YELLOW);
    } else {
      appendLog(`getNativeDisplayForId("${id}") → not found`, RED);
    }
  }

  return (
    <SafeAreaView style={styles.root}>
      <ScrollView contentContainerStyle={styles.scroll}>

        {/* Section 1 - Listener */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Listener</Text>
          <View style={styles.badgeRow}>
            <View style={[styles.badge, registered ? styles.badgeGreen : styles.badgeGrey]}>
              <Text style={[styles.badgeText, registered ? styles.badgeTextGreen : styles.badgeTextGrey]}>
                {registered ? 'Registered' : 'Not registered'}
              </Text>
            </View>
          </View>
          <View style={styles.buttonRow}>
            <View style={styles.buttonFlex}>
              <TouchableOpacity
                style={[styles.btn, registered && styles.btnDisabled]}
                onPress={registerListener}
                disabled={registered}
                activeOpacity={0.7}
              >
                <Text style={[styles.btnText, registered && styles.btnTextDisabled]}>
                  Register Listener
                </Text>
              </TouchableOpacity>
            </View>
            <View style={styles.buttonFlex}>
              <TouchableOpacity
                style={[styles.btn, styles.btnOutline, !registered && styles.btnDisabled]}
                onPress={unregisterListener}
                disabled={!registered}
                activeOpacity={0.7}
              >
                <Text style={[styles.btnText, styles.btnTextOutline, !registered && styles.btnTextDisabled]}>
                  Unregister Listener
                </Text>
              </TouchableOpacity>
            </View>
          </View>
        </View>

        {/* Section 2 - Simulate server response */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Simulate server response</Text>
          <Text style={styles.sectionDesc}>
            Process mock JSON directly - simulates what the Core SDK does when it receives a server payload.
          </Text>
          <View style={styles.buttonColumn}>
            <TouchableOpacity style={styles.btn} onPress={simulate1Unit} activeOpacity={0.7}>
              <Text style={styles.btnText}>Process 1 unit</Text>
            </TouchableOpacity>
            <TouchableOpacity style={styles.btn} onPress={simulate3Units} activeOpacity={0.7}>
              <Text style={styles.btnText}>Process 3 units</Text>
            </TouchableOpacity>
            <TouchableOpacity style={[styles.btn, styles.btnDestructive]} onPress={clearUnits} activeOpacity={0.7}>
              <Text style={styles.btnText}>Clear units</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Section 3 - Pull API */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Pull API</Text>
          <TouchableOpacity style={styles.btn} onPress={getAllDisplays} activeOpacity={0.7}>
            <Text style={styles.btnText}>getAllNativeDisplays()</Text>
          </TouchableOpacity>
          <View style={styles.inputRow}>
            <TextInput
              style={styles.input}
              placeholder="Unit ID"
              placeholderTextColor="#999"
              value={pullIdInput}
              onChangeText={setPullIdInput}
              onSubmitEditing={getDisplayForId}
              returnKeyType="search"
            />
            <TouchableOpacity
              style={[styles.btn, styles.btnCompact]}
              onPress={getDisplayForId}
              activeOpacity={0.7}
            >
              <Text style={styles.btnText}>getNativeDisplayForId()</Text>
            </TouchableOpacity>
          </View>
        </View>

        {/* Section 4 - Rendered units */}
        <View style={styles.section}>
          <Text style={styles.sectionTitle}>Rendered units</Text>
          {units.length === 0 ? (
            <Text style={styles.empty}>No units yet. Process some above.</Text>
          ) : (
            units.map((unit) => (
              <View key={unit.unitId} style={styles.unitWrap}>
                <NativeDisplayView unit={unit} />
                <Text style={styles.meta}>
                  {unit.unitId}{unit.slotId ? ` · slot: ${unit.slotId}` : ''}
                </Text>
              </View>
            ))
          )}
        </View>

      </ScrollView>

      {/* Event log */}
      <View style={styles.logSection}>
        <View style={styles.logHeader}>
          <Text style={styles.logTitle}>Event Log</Text>
          {logEntries.length > 0 && (
            <Button title="Clear" onPress={() => setLogEntries([])} />
          )}
        </View>
        <ScrollView style={styles.logScroll} contentContainerStyle={styles.logContent}>
          {logEntries.length === 0 ? (
            <Text style={styles.logEmpty}>No events yet</Text>
          ) : (
            logEntries.map((entry) => (
              <Text key={entry.id} style={[styles.logEntry, { color: entry.color }]}>
                {entry.text}
              </Text>
            ))
          )}
        </ScrollView>
      </View>
    </SafeAreaView>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  scroll: {
    padding: 16,
    gap: 16,
    paddingBottom: 8,
  },
  section: {
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 16,
    gap: 10,
    ...Platform.select({
      ios: {
        shadowColor: '#000',
        shadowOffset: { width: 0, height: 1 },
        shadowOpacity: 0.06,
        shadowRadius: 3,
      },
      android: { elevation: 1 },
    }),
  },
  sectionTitle: {
    fontSize: 16,
    fontWeight: '700',
    color: '#111827',
  },
  sectionDesc: {
    fontSize: 13,
    color: '#6B7280',
    lineHeight: 18,
  },
  badgeRow: {
    flexDirection: 'row',
  },
  badge: {
    paddingHorizontal: 10,
    paddingVertical: 4,
    borderRadius: 12,
  },
  badgeGreen: {
    backgroundColor: '#DCFCE7',
  },
  badgeGrey: {
    backgroundColor: '#F3F4F6',
  },
  badgeText: {
    fontSize: 12,
    fontWeight: '600',
  },
  badgeTextGreen: {
    color: '#16A34A',
  },
  badgeTextGrey: {
    color: '#6B7280',
  },
  buttonRow: {
    flexDirection: 'row',
    gap: 8,
  },
  buttonFlex: {
    flex: 1,
  },
  buttonColumn: {
    gap: 8,
  },
  btn: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 10,
    paddingHorizontal: 14,
    alignItems: 'center',
  },
  btnOutline: {
    backgroundColor: 'transparent',
    borderWidth: 1,
    borderColor: '#007AFF',
  },
  btnDestructive: {
    backgroundColor: '#EF4444',
  },
  btnCompact: {
    paddingVertical: 8,
    paddingHorizontal: 10,
  },
  btnDisabled: {
    backgroundColor: '#D1D5DB',
    borderColor: '#D1D5DB',
  },
  btnText: {
    color: '#FFFFFF',
    fontSize: 13,
    fontWeight: '600',
  },
  btnTextOutline: {
    color: '#007AFF',
  },
  btnTextDisabled: {
    color: '#9CA3AF',
  },
  inputRow: {
    flexDirection: 'row',
    gap: 8,
    alignItems: 'center',
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
  empty: {
    fontSize: 14,
    color: '#9E9E9E',
    textAlign: 'center',
    marginVertical: 8,
  },
  unitWrap: {
    borderRadius: 8,
    overflow: 'hidden',
    backgroundColor: '#FFFFFF',
    borderWidth: 1,
    borderColor: '#E5E7EB',
  },
  meta: {
    fontSize: 11,
    color: '#9E9E9E',
    paddingHorizontal: 12,
    paddingVertical: 6,
    backgroundColor: '#FAFAFA',
  },
  // Log
  logSection: {
    maxHeight: 180,
    paddingHorizontal: 12,
    paddingTop: 6,
    paddingBottom: 8,
    backgroundColor: '#F5F5F5',
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
