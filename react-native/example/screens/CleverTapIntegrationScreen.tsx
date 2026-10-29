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
  useWindowDimensions,
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
import { fireEvent, isCanonicalEvent, runSequence, subscribeAutomation } from '../screenshotAutomation';

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
  const { width, height } = useWindowDimensions();
  const isLandscape = width > height;

  const ctAvailable = typeof (CleverTap as unknown as Record<string, unknown>).recordEvent === 'function';

  const appendLog = useCallback((message: string) => {
    setLog((prev) => [`[${timestamp()}] ${message}`, ...prev]);
  }, []);

  // Bridge is bound once in App.tsx. Just track whether it's available.
  useEffect(() => {
    setBridgeBound(true);
    appendLog('Bridge ready');
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Register bridge listener
  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(incoming: NativeDisplayUnit[]) {
        // Show all units like Android/iOS - no filtering
        setUnits(incoming);
        appendLog(`Received ${incoming.length} display unit(s)`);
        incoming.forEach((u) => appendLog(`  unit: ${u.unitId}`));
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    appendLog('Bridge listener registered');
    // A push-tapped unit may reach the bridge before this screen is mounted
    // (e.g. the app opened on another tab). Seed from the cache so it still
    // shows once the user lands on this tab.
    const cached = NativeDisplayBridge.shared.getAllNativeDisplays();
    if (cached.length > 0) {
      setUnits(cached);
      appendLog(`Seeded ${cached.length} cached display unit(s)`);
    }
    return () => {
      NativeDisplayBridge.shared.removeListener(listener);
      appendLog('Bridge listener removed');
    };
  }, [appendLog]);

  // Screenshot automation: App.tsx publishes a request when an automation deep
  // link is opened. We fire through the same recordEvent path as the Send Event
  // button, logging each event so screenshots show which event is active.
  //   - single   → ndautomation://event?name=<eventName>   (fire one event)
  //   - sequence → ndautomation://events?settle=<seconds>  (fire all 22)
  useEffect(() => {
    return subscribeAutomation((request) => {
      if (request.kind === 'single') {
        // Guard against typos in the deep link — only canonical events fire.
        if (!isCanonicalEvent(request.name)) {
          appendLog(`AUTOMATION WARNING unknown event '${request.name}' ignored`);
          return;
        }
        fireEvent(request.name);
        appendLog(`AUTOMATION EVENT ${request.name}`);
        return;
      }
      appendLog(`AUTOMATION start (settle ${request.settleSeconds}s, 22 events)`);
      runSequence(request.settleSeconds, (name, index, total) => {
        appendLog(`AUTOMATION ${index + 1}/${total} EVENT ${name}`);
      }).catch((e) => appendLog(`AUTOMATION ERROR ${String(e)}`));
    });
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

  // The SDK routes a close button through onCustomAction(key="close", ...) with
  // no unitId (close is a custom action, not a distinct action type - matches
  // Android/iOS). Dismissing a unit is a client responsibility by design, so
  // here we wrap the shared listener per unit. The wrapper closes over the
  // unit's own id, so onCustomAction knows which unit to remove when key ===
  // "close". All other custom keys fall through to the shared handler.
  const makeUnitActionListener = (unitId: string): NativeDisplayActionListener => ({
    ...actionListener,
    onCustomAction(key: string, value: unknown, metadata?: Record<string, string>): void {
      if (key === 'close') {
        appendLog(`ACTION close: dismissing unit ${unitId}`);
        setUnits((prev) => prev.filter((u) => u.unitId !== unitId));
        return;
      }
      actionListener.onCustomAction(key, value, metadata);
    },
  });

  function sendEvent() {
    const name = eventName.trim();
    if (!name || !ctAvailable) return;
    (CleverTap as unknown as { recordEvent: (n: string) => void }).recordEvent(name);
    appendLog(`Sent EVENT: ${name}`);
    setEventName('');
  }

  // Header block: mirrors Android `FireEventHeader` (padding 16dp, spacedBy 12dp,
  // input Row with spacedBy 8dp, then a HorizontalDivider + "Native Display Canvas"
  // label in portrait only). Badges are tucked below the input row as a subtle
  // status line so the parent layout still matches Android visually.
  const headerBlock = (showCanvasLabel: boolean): React.ReactElement => (
    <View style={styles.fireEventHeader}>
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
      <View style={styles.statusRow}>
        <StatusBadge label="CleverTap" ok={ctAvailable} />
        <StatusBadge label="Bridge" ok={bridgeBound} />
      </View>
      {showCanvasLabel && (
        <>
          <View style={styles.divider} />
          <Text style={styles.canvasLabel}>Native Display Canvas</Text>
        </>
      )}
    </View>
  );

  // Event log block: mirrors Android `EventLogFooter` (HorizontalDivider inside
  // the block, title row, then a dark Card with monospace log lines).
  const eventLogBlock = (fillHeight: boolean): React.ReactElement => (
    <View style={[styles.eventLogFooter, fillHeight && styles.eventLogFooterFill]}>
      <View style={styles.divider} />
      <View style={styles.logHeader}>
        <Text style={styles.logTitle}>Event Log</Text>
        {log.length > 0 && (
          <Button title="Clear" onPress={() => setLog([])} />
        )}
      </View>
      <ScrollView
        style={[styles.logScroll, fillHeight && styles.logScrollFill]}
        contentContainerStyle={styles.logContent}
      >
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
  );

  const canvasBlock = (
    <View style={styles.canvas}>
      {units.length === 0 ? (
        <View style={styles.emptyState}>
          <Text style={styles.emptyText}>Waiting for Native Display response...</Text>
        </View>
      ) : (
        <ScrollView contentContainerStyle={styles.canvasScroll}>
          {units.map((unit) => (
            <NativeDisplayView
              key={unit.unitId}
              unit={unit}
              actionListener={makeUnitActionListener(unit.unitId)}
              style={styles.unitView}
            />
          ))}
        </ScrollView>
      )}
    </View>
  );

  // ─── Landscape layout (33/67 split) - mirrors Android landscape branch ────
  if (isLandscape) {
    return (
      <SafeAreaView style={styles.root}>
        <KeyboardAvoidingView
          style={styles.landscapeRow}
          behavior={Platform.OS === 'ios' ? 'padding' : undefined}
        >
          {/* Left panel ~33%: event input + log (no canvas label in landscape,
              matching Android's `showCanvasLabel = false`) */}
          <View style={styles.leftPanel}>
            {headerBlock(false)}
            {eventLogBlock(true)}
          </View>

          <View style={styles.verticalDivider} />

          {/* Right panel ~67%: canvas only - matches Android right column */}
          <View style={styles.rightPanel}>{canvasBlock}</View>
        </KeyboardAvoidingView>
      </SafeAreaView>
    );
  }

  // ─── Portrait layout (vertical stack) - mirrors Android portrait branch ───
  // Column { FireEventHeader, CanvasContent(weight 1), EventLogFooter }
  return (
    <SafeAreaView style={styles.root}>
      <KeyboardAvoidingView
        style={styles.root}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        {headerBlock(true)}
        {canvasBlock}
        {eventLogBlock(false)}
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

  // ── Landscape split ─────────────────────────────────────────────────────
  // Android: Row(fillMaxSize) { Column(weight 0.33) ... VerticalDivider ...
  //          Column(weight 0.67) }
  landscapeRow: {
    flex: 1,
    flexDirection: 'row',
  },
  leftPanel: {
    flex: 1, // 33% (1 of 1+2)
  },
  rightPanel: {
    flex: 2, // 67% (2 of 1+2)
  },
  verticalDivider: {
    width: 1,
    backgroundColor: '#E5E7EB',
  },

  // ── FireEventHeader ─────────────────────────────────────────────────────
  // iOS: VStack(alignment: .leading, spacing: 12).padding(10) - uniform 10pt
  // padding matches CleverTapIntegrationView.fireEventSection so the header
  // footprint (and by extension the top of the canvas below) lines up when
  // eyeballing screenshots side-by-side.
  fireEventHeader: {
    padding: 10,
    gap: 12,
  },
  // Android: Row(fillMaxWidth, spacedBy(8.dp), verticalAlignment Center)
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
  // RN-only: status badges tucked below the input row. Android's
  // FireEventHeader doesn't render these because CleverTap availability is
  // implicit on Android; here we keep them for parity with the existing RN
  // UX but make them subtle so they don't dominate the comparison.
  statusRow: {
    flexDirection: 'row',
    gap: 8,
  },
  // Android: Text("Native Display Canvas", titleSmall, FontWeight.SemiBold)
  // titleSmall is ~14sp / SemiBold.
  canvasLabel: {
    fontSize: 14,
    fontWeight: '600',
    color: '#374151',
  },

  // ── CanvasContent (the parent of NativeDisplayView) ─────────────────────
  // Matches iOS exactly (the reference for cross-platform screenshot diffs):
  //   ScrollView { VStack(spacing: 12) { ForEach(units) { ... } }
  //     .frame(maxWidth: .infinity)
  //     .padding(.horizontal, 10) }
  // No vertical inset - the first unit sits flush against the divider above.
  // A 16dp horizontal / 8dp vertical inset (matching Android) would make
  // every percent-computed layout.width on RN 12pt narrower than iOS and
  // shift the first unit down by 8pt, so we align to iOS instead.
  canvas: {
    flex: 1,
  },
  canvasScroll: {
    paddingHorizontal: 10,
    paddingVertical: 0,
    gap: 12,
  },
  // Android: NativeDisplayView(modifier = Modifier.fillMaxWidth())
  unitView: {
    width: '100%',
  },
  emptyState: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 8,
    padding: 32,
  },
  emptyText: {
    fontSize: 14,
    color: '#9CA3AF',
    textAlign: 'center',
  },

  // ── EventLogFooter ──────────────────────────────────────────────────────
  // Android: Column(fillMaxWidth, padding(horizontal=16.dp).padding(bottom=8.dp),
  //                 spacedBy(4.dp))
  //   - HorizontalDivider at the top (inside the footer, NOT before it)
  //   - Row(title + Clear button)
  //   - Card(bg #263238, RoundedCornerShape(8), heightIn(min=80, max=160))
  //     containing the LazyColumn(padding(10), spacedBy(2)) of log lines.
  eventLogFooter: {
    paddingHorizontal: 16,
    paddingBottom: 8,
    gap: 4,
  },
  // In landscape Android's EventLogFooter is `Modifier.weight(1f)` inside the
  // left column - the log Card uses `fillMaxHeight()` instead of the
  // min/max heightIn. fillHeight: true flips to that behaviour.
  eventLogFooterFill: {
    flex: 1,
  },
  divider: {
    height: 1,
    backgroundColor: '#E5E7EB',
  },
  logHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  logTitle: {
    fontSize: 14, // titleSmall on Android
    fontWeight: '600',
    color: '#374151',
  },
  logScroll: {
    backgroundColor: '#263238', // matches Android Card containerColor
    borderRadius: 8,
    minHeight: 80,
    maxHeight: 160,
  },
  logScrollFill: {
    flex: 1,
    minHeight: undefined,
    maxHeight: undefined,
  },
  logContent: {
    padding: 10,
    gap: 2, // matches Android Arrangement.spacedBy(2.dp)
  },
  logEmpty: {
    fontSize: 12, // bodySmall on Android
    color: '#607D8B', // matches Android empty state
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
  },
  logEntry: {
    fontSize: 12, // bodySmall on Android
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    lineHeight: 16, // matches Android lineHeight = 16.sp
  },
});
