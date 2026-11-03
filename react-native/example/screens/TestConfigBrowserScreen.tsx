import React, { useState, useEffect, useRef } from 'react';
import {
  View,
  Text,
  ScrollView,
  SafeAreaView,
  StyleSheet,
  TouchableOpacity,
  useWindowDimensions,
} from 'react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
import type { NativeDisplayBridgeListener, NativeDisplayUnit } from '@clevertap/native-display-sdk';
import { NativeDisplayView } from '@clevertap/native-display-sdk';
import { ALL_CONFIGS } from '../testConfigs/configRegistry';

// Material3 default light theme colors, mirroring the Android sample app's
// MaterialTheme so this screen renders 1:1 with android-sample's TestBrowserScreen.kt.
const M3 = {
  primary: '#6750A4',
  onPrimary: '#FFFFFF',
  surface: '#FFFBFE',
  surfaceVariant: '#E7E0EC',
  onSurfaceVariant: '#49454F',
};

// Chip metrics - mirror Android's ChipStrip dp values exactly.
const CHIP_MIN_WIDTH = 40;            //  Modifier.widthIn(min = 40.dp)
const CHIP_HEIGHT = 32;               //  Modifier.height(32.dp)
const CHIP_GAP = 4;                   //  Arrangement.spacedBy(4.dp)
const CHIP_PADDING_HORIZONTAL = 8;    //  contentPadding = PaddingValues(horizontal = 8.dp)

// 1:1 port of android-sample TestBrowserScreen.kt. Structure mirrors Android:
//   Column { NavigationRow, ChipStrip, ContentArea(verticalScroll(NativeDisplayView)) }
export function TestConfigBrowserScreen(): React.ReactElement {
  const { width: screenWidth } = useWindowDimensions();
  const [index, setIndex] = useState(0);
  const [unit, setUnit] = useState<NativeDisplayUnit | null>(null);
  const chipScrollRef = useRef<ScrollView>(null);

  const entry = ALL_CONFIGS[index]!;
  const total = ALL_CONFIGS.length;

  // Push current config into the bridge whenever index changes.
  useEffect(() => {
    setUnit(null);
    const json = JSON.stringify({
      wzrk_id: entry.id,
      slot_id: 'browser',
      ...entry.config,
    });
    NativeDisplayBridge.shared.processDisplayUnit(json);
  }, [index, entry.id, entry.config]);

  // Listen for the bridge to return the unit matching the current entry.
  useEffect(() => {
    const listener: NativeDisplayBridgeListener = {
      onNativeDisplaysLoaded(units: NativeDisplayUnit[]) {
        const match = units.find((u) => u.unitId === entry.id);
        if (match) setUnit(match);
      },
    };
    NativeDisplayBridge.shared.addListener(listener);
    return () => {
      NativeDisplayBridge.shared.removeListener(listener);
    };
  }, [index, entry.id]);

  // Auto-scroll the chip strip to keep the active chip centred -
  // mirrors Android: chipListState.animateScrollToItem(currentIndex,
  //   -(screenWidthPx/2 - chipWidthPx/2)).
  useEffect(() => {
    const chipStride = CHIP_MIN_WIDTH + CHIP_GAP;
    const leftEdge = CHIP_PADDING_HORIZONTAL + index * chipStride;
    const targetX = leftEdge - (screenWidth / 2 - CHIP_MIN_WIDTH / 2);
    chipScrollRef.current?.scrollTo({ x: Math.max(0, targetX), animated: true });
  }, [index, screenWidth]);

  // Loop navigation: prev/next wrap around at the ends - matches Android.
  function goToPrevious(): void {
    setIndex((i) => (i > 0 ? i - 1 : total - 1));
  }

  function goToNext(): void {
    setIndex((i) => (i < total - 1 ? i + 1 : 0));
  }

  const filename = entry.filename;
  const counter = `${index + 1}/${total}`;

  return (
    <SafeAreaView style={styles.container}>
      {/* Navigation row - mirrors Android NavigationRow: Surface(surfaceVariant)
          { Row { IconButton(ArrowBack), Text(filename + counter), IconButton(ArrowForward) } }. */}
      <View style={styles.navRow}>
        <TouchableOpacity onPress={goToPrevious} style={styles.iconButton}>
          <Text style={styles.iconArrow}>←</Text>
        </TouchableOpacity>
        <Text
          style={styles.filename}
          numberOfLines={1}
          ellipsizeMode="tail"
        >
          {filename}
          <Text> </Text>
          <Text style={styles.counter}>({counter})</Text>
        </Text>
        <TouchableOpacity onPress={goToNext} style={styles.iconButton}>
          <Text style={styles.iconArrow}>→</Text>
        </TouchableOpacity>
      </View>

      {/* Chip strip - LazyRow on Android, ScrollView here.
          Padding/gap/sizing copied verbatim from Android ChipStrip. */}
      <ScrollView
        ref={chipScrollRef}
        horizontal
        showsHorizontalScrollIndicator={false}
        style={styles.chipStrip}
        contentContainerStyle={styles.chipContent}
      >
        {ALL_CONFIGS.map((cfg, i) => {
          const active = i === index;
          const label = String(i + 1).padStart(3, '0');
          return (
            <TouchableOpacity
              key={cfg.id}
              style={[styles.chip, active && styles.chipActive]}
              onPress={() => setIndex(i)}
              activeOpacity={0.7}
            >
              <Text style={[styles.chipText, active && styles.chipTextActive]}>
                {label}
              </Text>
            </TouchableOpacity>
          );
        })}
      </ScrollView>

      {/* Content area - light gray background, scrollable vertically.
          Android: Box(bg #F5F5F5) { Box(verticalScroll) { NativeDisplayView(fillMaxWidth) } }.
          No horizontal padding - the unit renders edge-to-edge inside the gray area. */}
      <View style={styles.contentArea}>
        {unit && (
          <ScrollView style={styles.contentScroll}>
            <NativeDisplayView unit={unit} />
          </ScrollView>
        )}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: M3.surface,
  },
  navRow: {
    flexDirection: 'row',
    alignItems: 'center',
    backgroundColor: M3.surfaceVariant,
    minHeight: 48,
  },
  // 48dp x 48dp - matches Material3 IconButton's default size.
  iconButton: {
    width: 48,
    height: 48,
    alignItems: 'center',
    justifyContent: 'center',
  },
  iconArrow: {
    fontSize: 22,
    color: M3.onSurfaceVariant,
    lineHeight: 24,
  },
  // Filename: bodySmall 13sp, centred, ellipsised - matches Android.
  filename: {
    flex: 1,
    fontSize: 13,
    textAlign: 'center',
    color: M3.onSurfaceVariant,
  },
  // Counter: 11sp at 60% alpha - matches Android SpanStyle.
  counter: {
    fontSize: 11,
    color: 'rgba(73, 69, 79, 0.6)',
  },
  chipStrip: {
    backgroundColor: M3.surface,
    flexGrow: 0,
    paddingVertical: 6,
  },
  chipContent: {
    paddingHorizontal: CHIP_PADDING_HORIZONTAL,
    gap: CHIP_GAP,
    flexDirection: 'row',
    alignItems: 'center',
  },
  chip: {
    height: CHIP_HEIGHT,
    minWidth: CHIP_MIN_WIDTH,
    borderRadius: 4,
    backgroundColor: M3.surfaceVariant,
    paddingHorizontal: 4,
    alignItems: 'center',
    justifyContent: 'center',
  },
  chipActive: {
    backgroundColor: M3.primary,
  },
  // labelSmall (~11sp) regular weight, onSurfaceVariant.
  chipText: {
    fontSize: 11,
    color: M3.onSurfaceVariant,
    fontWeight: '400',
  },
  chipTextActive: {
    color: M3.onPrimary,
    fontWeight: '700',
  },
  contentArea: {
    flex: 1,
    backgroundColor: '#F5F5F5',
  },
  // Cyan tint on the scroll wrapper so any space around the NativeDisplayView
  // is obvious. Mirrors Android's content scroll Box background.
  contentScroll: {
    flex: 1,
    backgroundColor: '#80DEEA',
  },
});
