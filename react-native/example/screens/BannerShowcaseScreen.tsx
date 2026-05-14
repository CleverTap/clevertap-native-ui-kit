import React, { useState, useEffect, useCallback } from 'react';
import {
  View,
  Text,
  TouchableOpacity,
  ScrollView,
  StyleSheet,
  Platform,
  SafeAreaView,
  ActivityIndicator,
  TextInput,
  Modal,
  KeyboardAvoidingView,
} from 'react-native';
import {
  NativeDisplayBridge,
  NativeDisplayView,
} from '@clevertap/native-display-sdk';
import type {
  NativeDisplayBridgeListener,
  NativeDisplayUnit,
  NativeDisplayActionListener,
  NativeDisplayComponentListener,
  InteractionType,
} from '@clevertap/native-display-sdk';

// ─── Data ────────────────────────────────────────────────────────────────────

interface BannerItem {
  id: string;
  emoji: string;
  title: string;
  description: string;
}

const BANNERS: BannerItem[] = [
  { id: 'banner-01', emoji: '🌞', title: 'Summer Sale',        description: 'Hero banner with gradient' },
  { id: 'banner-02', emoji: '📱', title: 'iPhone 15 Pro',      description: 'Product showcase' },
  { id: 'banner-03', emoji: '🎉', title: 'New Features',       description: 'App update announcement' },
  { id: 'banner-04', emoji: '✈️', title: 'Travel Deals',       description: 'Multi-button travel banner' },
  { id: 'banner-05', emoji: '👗', title: 'Fashion Collection', description: 'Image banner' },
  { id: 'banner-06', emoji: '💳', title: 'Cashback Offer',     description: 'Credit card with GIF' },
  { id: 'banner-07', emoji: '⭐', title: 'App Rating',         description: 'Social proof' },
  { id: 'banner-08', emoji: '⚡', title: 'Flash Sale',         description: 'Urgency banner' },
  { id: 'banner-09', emoji: '💎', title: 'Go Premium',         description: 'Typography showcase' },
  { id: 'banner-10', emoji: '👋', title: 'Welcome',            description: 'Onboarding banner' },
];

// Metro needs static string literals in require() - use a switch to satisfy it.
/* eslint-disable @typescript-eslint/no-require-imports */
function loadBannerConfig(id: string): Record<string, unknown> | null {
  switch (id) {
    case 'banner-01': return require('../../../test-configs/banner-01-summer-sale.json') as Record<string, unknown>;
    case 'banner-02': return require('../../../test-configs/banner-02-iphone.json') as Record<string, unknown>;
    case 'banner-03': return require('../../../test-configs/banner-03-feature-highlights.json') as Record<string, unknown>;
    case 'banner-04': return require('../../../test-configs/banner-04-travel.json') as Record<string, unknown>;
    case 'banner-05': return require('../../../test-configs/banner-05-fashion.json') as Record<string, unknown>;
    case 'banner-06': return require('../../../test-configs/banner-06-cashback.json') as Record<string, unknown>;
    case 'banner-07': return require('../../../test-configs/banner-07-rating.json') as Record<string, unknown>;
    case 'banner-08': return require('../../../test-configs/banner-08-flash-sale.json') as Record<string, unknown>;
    case 'banner-09': return require('../../../test-configs/banner-09-premium-subscription.json') as Record<string, unknown>;
    case 'banner-10': return require('../../../test-configs/banner-10-welcome.json') as Record<string, unknown>;
    default: return null;
  }
}
/* eslint-enable @typescript-eslint/no-require-imports */

// ─── Interaction log ──────────────────────────────────────────────────────────

interface LogEntry {
  id: number;
  timestamp: Date;
  nodeId: string | null;
  interactionType: InteractionType | null;
  actionData: string;
}

let _logId = 0;

function makeLog(
  nodeId: string | null,
  interactionType: InteractionType | null,
  actionData: string,
): LogEntry {
  return { id: _logId++, timestamp: new Date(), nodeId, interactionType, actionData };
}

function formatTime(d: Date): string {
  return d.toLocaleTimeString('en-GB', {
    hour12: false,
    // @ts-ignore
    fractionalSecondDigits: 3,
  });
}

function interactionTypeLabel(t: InteractionType | null): string {
  if (!t) return 'ACTION';
  switch (t) {
    case 'click':     return 'CLICK';
    case 'longPress': return 'LONG_PRESS';
    case 'doubleTap': return 'DOUBLE_TAP';
  }
}

// ─── Banner detail view ───────────────────────────────────────────────────────

interface BannerDetailViewProps {
  banner: BannerItem;
  onBack: () => void;
  /** Pre-built JSON string to use instead of loading from the test-configs. */
  preloadedJson?: string;
}

function BannerDetailView({ banner, onBack, preloadedJson }: BannerDetailViewProps): React.ReactElement {
  const [unit, setUnit] = useState<NativeDisplayUnit | null>(null);
  const [loading, setLoading] = useState(true);
  const [error, setError] = useState<string | null>(null);
  const [logs, setLogs] = useState<LogEntry[]>([]);

  const appendLog = useCallback((log: LogEntry) => {
    setLogs((prev) => [log, ...prev]);
  }, []);

  // Load the banner config and process it via the bridge
  useEffect(() => {
    setUnit(null);
    setLoading(true);
    setError(null);
    setLogs([]);

    let json: string;
    if (preloadedJson) {
      json = preloadedJson;
    } else {
      const config = loadBannerConfig(banner.id);
      if (!config) {
        setError(`Could not load config for ${banner.id}`);
        setLoading(false);
        return;
      }
      json = JSON.stringify({ wzrk_id: banner.id, ...config });
    }

    NativeDisplayBridge.shared.processDisplayUnit(json);
  }, [banner.id, preloadedJson]);

  // Register a listener to receive the processed unit
  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(units: NativeDisplayUnit[]) {
        const match = units.find((u) => u.unitId === banner.id);
        if (match) {
          setUnit(match);
          setLoading(false);
        }
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    return () => NativeDisplayBridge.shared.removeListener(listener);
  }, [banner.id]);

  // Action listener - logs all actions
  const actionListener: NativeDisplayActionListener = {
    onOpenUrl(url: string): boolean {
      appendLog(makeLog(null, null, `Open URL: ${url}`));
      return false;
    },
    onCustomAction(key: string, value: unknown): void {
      appendLog(makeLog(null, null, `Custom Action: ${key}\nValue: ${JSON.stringify(value)}`));
    },
    onNavigate(destination: string, params?: Record<string, string>): void {
      appendLog(makeLog(null, null, `Navigate: ${destination}\nParams: ${JSON.stringify(params ?? {})}`));
    },
    onTrackEvent(eventName: string, properties?: Record<string, unknown>): void {
      appendLog(makeLog(null, null, `Track Event: ${eventName}\nProperties: ${JSON.stringify(properties ?? {})}`));
    },
    onDisplayUnitViewed(unitId: string): void {
      appendLog(makeLog(null, null, `Unit viewed: ${unitId}`));
    },
    onDisplayUnitClicked(unitId: string): void {
      appendLog(makeLog(null, null, `Unit clicked: ${unitId}`));
    },
  };

  // Component listener - logs all interactions
  const componentListener: NativeDisplayComponentListener = {
    getInterestedNodeIds() {
      return null; // Listen to all nodes
    },
    onComponentInteraction(nodeId: string, interactionType: InteractionType, hasServerAction: boolean): boolean {
      const actionData = hasServerAction ? 'Has server action' : 'No server action';
      appendLog(makeLog(nodeId, interactionType, actionData));
      return false; // Don't consume - let server actions proceed
    },
  };

  return (
    <SafeAreaView style={detail.root}>
      {/* Header */}
      <View style={detail.header}>
        <TouchableOpacity onPress={onBack} style={detail.backBtn} activeOpacity={0.7}>
          <Text style={detail.backText}>← Back</Text>
        </TouchableOpacity>
        <Text style={detail.headerTitle} numberOfLines={1}>{banner.emoji} {banner.title}</Text>
        <View style={detail.headerRight} />
      </View>

      {/* 70 / 30 split */}
      <View style={detail.bannerArea}>
        {loading && (
          <View style={detail.center}>
            <ActivityIndicator size="small" />
            <Text style={detail.loadingText}>Loading banner...</Text>
          </View>
        )}
        {error && !loading && (
          <View style={detail.center}>
            <Text style={detail.errorText}>{error}</Text>
          </View>
        )}
        {unit && !loading && (
          <ScrollView contentContainerStyle={detail.bannerScroll}>
            <NativeDisplayView
              unit={unit}
              actionListener={actionListener}
              componentListener={componentListener}
              style={detail.unitView}
            />
          </ScrollView>
        )}
      </View>

      <View style={detail.divider} />

      {/* Interaction log (bottom 30%) */}
      <View style={detail.logArea}>
        <View style={detail.logHeader}>
          <Text style={detail.logTitle}>Interaction log</Text>
          <Text style={detail.logCount}>{logs.length} events</Text>
        </View>
        <View style={detail.divider} />
        {logs.length === 0 ? (
          <View style={detail.center}>
            <Text style={detail.emptyText}>Tap banner elements to see interactions here</Text>
          </View>
        ) : (
          <ScrollView contentContainerStyle={detail.logScroll}>
            {logs.map((log) => (
              <LogRow key={log.id} log={log} />
            ))}
          </ScrollView>
        )}
      </View>
    </SafeAreaView>
  );
}

function LogRow({ log }: { log: LogEntry }): React.ReactElement {
  const typeLabel = interactionTypeLabel(log.interactionType);
  const isAction = log.nodeId === null;

  return (
    <View style={logRow.container}>
      <View style={logRow.badges}>
        <View style={[logRow.badge, isAction ? logRow.badgeGreen : logRow.badgeBlue]}>
          <Text style={logRow.badgeText}>{typeLabel}</Text>
        </View>
        {isAction && (
          <View style={logRow.badgeExecuted}>
            <Text style={logRow.badgeText}>EXECUTED</Text>
          </View>
        )}
      </View>
      {log.nodeId && (
        <Text style={logRow.nodeId}>Node: {log.nodeId}</Text>
      )}
      <Text style={logRow.actionData} numberOfLines={3}>{log.actionData}</Text>
      <Text style={logRow.time}>{formatTime(log.timestamp)}</Text>
    </View>
  );
}

// ─── Banner list ──────────────────────────────────────────────────────────────

interface BannerListViewProps {
  onSelectBanner: (banner: BannerItem) => void;
  onPasteJson: () => void;
}

function BannerListView({ onSelectBanner, onPasteJson }: BannerListViewProps): React.ReactElement {
  return (
    <ScrollView style={list.root} contentContainerStyle={list.content}>

      {/* Upload / Paste JSON card */}
      <TouchableOpacity style={list.uploadCard} onPress={onPasteJson} activeOpacity={0.7}>
        <View style={list.uploadIcon}>
          <Text style={list.uploadIconText}>+</Text>
        </View>
        <View style={list.uploadText}>
          <Text style={list.uploadTitle}>Paste custom JSON</Text>
          <Text style={list.uploadDesc}>Paste any NativeDisplay JSON to preview it</Text>
        </View>
        <Text style={list.chevron}>›</Text>
      </TouchableOpacity>

      {/* Pre-defined banners */}
      {BANNERS.map((banner) => (
        <TouchableOpacity
          key={banner.id}
          style={list.card}
          onPress={() => onSelectBanner(banner)}
          activeOpacity={0.7}
        >
          <Text style={list.emoji}>{banner.emoji}</Text>
          <View style={list.textBlock}>
            <Text style={list.title}>{banner.title}</Text>
            <Text style={list.desc}>{banner.description}</Text>
          </View>
          <Text style={list.chevron}>›</Text>
        </TouchableOpacity>
      ))}
    </ScrollView>
  );
}

// ─── Paste JSON modal ─────────────────────────────────────────────────────────

interface PasteJsonModalProps {
  visible: boolean;
  onClose: () => void;
  onSubmit: (json: string) => void;
}

function PasteJsonModal({ visible, onClose, onSubmit }: PasteJsonModalProps): React.ReactElement {
  const [text, setText] = useState('');
  const [parseError, setParseError] = useState<string | null>(null);

  function handleSubmit() {
    setParseError(null);
    const trimmed = text.trim();
    if (!trimmed) return;
    try {
      JSON.parse(trimmed);
      onSubmit(trimmed);
      setText('');
    } catch {
      setParseError('Invalid JSON - check your input');
    }
  }

  return (
    <Modal visible={visible} animationType="slide" transparent onRequestClose={onClose}>
      <KeyboardAvoidingView
        style={paste.overlay}
        behavior={Platform.OS === 'ios' ? 'padding' : undefined}
      >
        <View style={paste.sheet}>
          <View style={paste.sheetHeader}>
            <Text style={paste.sheetTitle}>Paste JSON</Text>
            <TouchableOpacity onPress={onClose} activeOpacity={0.7}>
              <Text style={paste.closeBtn}>✕</Text>
            </TouchableOpacity>
          </View>
          <TextInput
            style={paste.input}
            multiline
            placeholder={'Paste NativeDisplay JSON here...\n\n{ "wzrk_id": "...", "root": { ... } }'}
            placeholderTextColor="#9CA3AF"
            value={text}
            onChangeText={(v) => { setText(v); setParseError(null); }}
            autoCapitalize="none"
            autoCorrect={false}
          />
          {parseError && <Text style={paste.error}>{parseError}</Text>}
          <TouchableOpacity
            style={[paste.submitBtn, !text.trim() && paste.submitBtnDisabled]}
            onPress={handleSubmit}
            disabled={!text.trim()}
            activeOpacity={0.8}
          >
            <Text style={paste.submitText}>Preview</Text>
          </TouchableOpacity>
        </View>
      </KeyboardAvoidingView>
    </Modal>
  );
}

// ─── Custom banner detail ─────────────────────────────────────────────────────

const CUSTOM_BANNER_ID = '__custom_banner__';

interface CustomBannerViewProps {
  json: string;
  onBack: () => void;
}

function CustomBannerView({ json, onBack }: CustomBannerViewProps): React.ReactElement {
  return (
    <BannerDetailView
      banner={{ id: CUSTOM_BANNER_ID, emoji: '📄', title: 'Custom JSON', description: '' }}
      preloadedJson={json}
      onBack={onBack}
    />
  );
}

// ─── Top-level screen (manages list ↔ detail navigation) ─────────────────────

export function BannerShowcaseScreen(): React.ReactElement {
  const [selectedBanner, setSelectedBanner] = useState<BannerItem | null>(null);
  const [pasteModalVisible, setPasteModalVisible] = useState(false);
  const [customJson, setCustomJson] = useState<string | null>(null);

  function handlePasteSubmit(json: string) {
    setPasteModalVisible(false);
    // Add wzrk_id if missing so the parser can handle it.
    // BannerDetailView will call processDisplayUnit when it mounts.
    try {
      const obj = JSON.parse(json) as Record<string, unknown>;
      if (!obj['wzrk_id']) {
        obj['wzrk_id'] = CUSTOM_BANNER_ID;
        json = JSON.stringify(obj);
      }
      setCustomJson(json);
    } catch {
      // invalid JSON - already handled in the modal
    }
  }

  if (customJson) {
    return (
      <CustomBannerView
        json={customJson}
        onBack={() => setCustomJson(null)}
      />
    );
  }

  if (selectedBanner) {
    return (
      <BannerDetailView
        banner={selectedBanner}
        onBack={() => setSelectedBanner(null)}
      />
    );
  }

  return (
    <>
      <BannerListView
        onSelectBanner={setSelectedBanner}
        onPasteJson={() => setPasteModalVisible(true)}
      />
      <PasteJsonModal
        visible={pasteModalVisible}
        onClose={() => setPasteModalVisible(false)}
        onSubmit={handlePasteSubmit}
      />
    </>
  );
}

// ─── Styles ───────────────────────────────────────────────────────────────────

const list = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  content: {
    padding: 16,
    gap: 10,
  },
  uploadCard: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 14,
    gap: 12,
    borderWidth: 1.5,
    borderColor: '#007AFF',
    borderStyle: 'dashed',
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.05, shadowRadius: 2 },
      android: { elevation: 1 },
    }),
  },
  uploadIcon: {
    width: 44,
    height: 44,
    borderRadius: 22,
    backgroundColor: '#EFF6FF',
    alignItems: 'center',
    justifyContent: 'center',
  },
  uploadIconText: {
    fontSize: 24,
    color: '#007AFF',
    fontWeight: '300',
  },
  uploadText: {
    flex: 1,
  },
  uploadTitle: {
    fontSize: 15,
    fontWeight: '600',
    color: '#007AFF',
  },
  uploadDesc: {
    fontSize: 12,
    color: '#6B7280',
    marginTop: 2,
  },
  card: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: '#FFFFFF',
    borderRadius: 12,
    padding: 14,
    gap: 12,
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.06, shadowRadius: 3 },
      android: { elevation: 1 },
    }),
  },
  emoji: {
    fontSize: 28,
    width: 44,
    textAlign: 'center',
  },
  textBlock: {
    flex: 1,
  },
  title: {
    fontSize: 15,
    fontWeight: '600',
    color: '#111827',
  },
  desc: {
    fontSize: 13,
    color: '#6B7280',
    marginTop: 2,
  },
  chevron: {
    fontSize: 20,
    color: '#C7CAD1',
    fontWeight: '300',
  },
});

const detail = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  header: {
    flexDirection: 'row',
    alignItems: 'center',
    paddingHorizontal: 12,
    paddingVertical: 10,
    backgroundColor: '#FFFFFF',
    borderBottomWidth: 1,
    borderBottomColor: '#E5E7EB',
  },
  backBtn: {
    paddingRight: 12,
    paddingVertical: 4,
  },
  backText: {
    fontSize: 15,
    color: '#007AFF',
    fontWeight: '500',
  },
  headerTitle: {
    flex: 1,
    fontSize: 15,
    fontWeight: '600',
    color: '#111827',
    textAlign: 'center',
  },
  headerRight: {
    width: 56, // balance the back button
  },
  divider: {
    height: 1,
    backgroundColor: '#E5E7EB',
  },
  // Top 70%
  bannerArea: {
    flex: 7,
    backgroundColor: '#FFFFFF',
  },
  bannerScroll: {
    padding: 16,
  },
  unitView: {
    width: '100%',
  },
  center: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    padding: 24,
    gap: 8,
  },
  loadingText: {
    fontSize: 13,
    color: '#9CA3AF',
  },
  errorText: {
    fontSize: 13,
    color: '#EF4444',
    textAlign: 'center',
  },
  // Bottom 30%
  logArea: {
    flex: 3,
    backgroundColor: '#FAFAFA',
  },
  logHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
    paddingHorizontal: 14,
    paddingVertical: 10,
    backgroundColor: '#EEEEEE',
  },
  logTitle: {
    fontSize: 13,
    fontWeight: '700',
    color: '#333333',
  },
  logCount: {
    fontSize: 12,
    color: '#6B7280',
  },
  logScroll: {
    padding: 8,
    gap: 4,
  },
  emptyText: {
    fontSize: 13,
    color: '#9CA3AF',
    textAlign: 'center',
  },
});

const logRow = StyleSheet.create({
  container: {
    backgroundColor: '#FFFFFF',
    borderRadius: 8,
    padding: 10,
    gap: 4,
    ...Platform.select({
      ios: { shadowColor: '#000', shadowOffset: { width: 0, height: 1 }, shadowOpacity: 0.04, shadowRadius: 2 },
      android: { elevation: 1 },
    }),
  },
  badges: {
    flexDirection: 'row',
    gap: 6,
    marginBottom: 2,
  },
  badge: {
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
  },
  badgeBlue: {
    backgroundColor: '#2196F3',
  },
  badgeGreen: {
    backgroundColor: '#4CAF50',
  },
  badgeExecuted: {
    borderRadius: 4,
    paddingHorizontal: 6,
    paddingVertical: 2,
    backgroundColor: '#00C853',
  },
  badgeText: {
    fontSize: 10,
    fontWeight: '700',
    color: '#FFFFFF',
  },
  nodeId: {
    fontSize: 12,
    fontWeight: '600',
    color: '#333333',
  },
  actionData: {
    fontSize: 11,
    color: '#666666',
    lineHeight: 16,
  },
  time: {
    fontSize: 11,
    color: '#999999',
  },
});

const paste = StyleSheet.create({
  overlay: {
    flex: 1,
    justifyContent: 'flex-end',
    backgroundColor: 'rgba(0,0,0,0.4)',
  },
  sheet: {
    backgroundColor: '#FFFFFF',
    borderTopLeftRadius: 16,
    borderTopRightRadius: 16,
    padding: 20,
    gap: 12,
  },
  sheetHeader: {
    flexDirection: 'row',
    alignItems: 'center',
    justifyContent: 'space-between',
  },
  sheetTitle: {
    fontSize: 17,
    fontWeight: '700',
    color: '#111827',
  },
  closeBtn: {
    fontSize: 18,
    color: '#6B7280',
    paddingHorizontal: 4,
  },
  input: {
    borderWidth: 1,
    borderColor: '#D1D5DB',
    borderRadius: 8,
    padding: 12,
    fontSize: 12,
    fontFamily: Platform.OS === 'ios' ? 'Menlo' : 'monospace',
    color: '#111827',
    backgroundColor: '#F9FAFB',
    minHeight: 200,
    textAlignVertical: 'top',
  },
  error: {
    fontSize: 12,
    color: '#EF4444',
  },
  submitBtn: {
    backgroundColor: '#007AFF',
    borderRadius: 8,
    paddingVertical: 13,
    alignItems: 'center',
  },
  submitBtnDisabled: {
    backgroundColor: '#A0AABA',
  },
  submitText: {
    color: '#FFFFFF',
    fontSize: 15,
    fontWeight: '600',
  },
});
