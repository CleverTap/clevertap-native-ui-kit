import React, { useState, useEffect } from 'react';
import { View, Text, Pressable, SafeAreaView, StyleSheet } from 'react-native';
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
import { CleverTapIntegrationScreen } from './screens/CleverTapIntegrationScreen';
import { BridgeIntegrationScreen } from './screens/BridgeIntegrationScreen';
import { TestConfigBrowserScreen } from './screens/TestConfigBrowserScreen';
import { SlotDemoScreen } from './screens/SlotDemoScreen';
import { BannerShowcaseScreen } from './screens/BannerShowcaseScreen';
import { FontDemoScreen } from './screens/FontDemoScreen';

type Screen = 'ct' | 'bridge' | 'browser' | 'slots' | 'banners' | 'font';

// Mirrors Android `NavigationBarItem`: emoji icon stacked above text label,
// with the active tab tinted in the primary accent color. Order is kept aligned
// with `MainActivity.kt`'s NavigationBar (Events first), with RN-only screens
// (Bridge, Banners, Fonts) appended after the shared ones.
const TABS: ReadonlyArray<{ key: Screen; icon: string; label: string }> = [
  { key: 'ct',      icon: '📡', label: 'Events'  },
  { key: 'slots',   icon: '🎰', label: 'Slots'   },
  { key: 'browser', icon: '🧪', label: 'Browser' },
  { key: 'bridge',  icon: '🔗', label: 'Bridge'  },
  { key: 'banners', icon: '🖼️', label: 'Banners' },
  { key: 'font',    icon: '🔤', label: 'Fonts'   },
];

export default function App(): React.ReactElement {
  const [screen, setScreen] = useState<Screen>('ct');

  // Initialize the bridge at startup - mirrors the native app pattern exactly:
  //   iOS AppDelegate:        bridge.bind(ct);  bridge.fetchNativeDisplays(ct)
  //   Android Application:    bridge.bind(ct);  bridge.fetchNativeDisplays(ct)
  useEffect(() => {
    NativeDisplayBridge.shared.bind(CleverTap);
    NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <SafeAreaView style={styles.root}>
      {/* Content sits ABOVE the tab bar, matching Android's Scaffold(bottomBar=...). */}
      <View style={styles.content}>
        {screen === 'ct'      && <CleverTapIntegrationScreen />}
        {screen === 'bridge'  && <BridgeIntegrationScreen />}
        {screen === 'browser' && <TestConfigBrowserScreen />}
        {screen === 'slots'   && <SlotDemoScreen />}
        {screen === 'banners' && <BannerShowcaseScreen />}
        {screen === 'font'    && <FontDemoScreen />}
      </View>
      {/* Bottom navigation bar - mirrors Android NavigationBar in MainActivity.kt */}
      <View style={styles.tabs}>
        {TABS.map((t) => {
          const active = screen === t.key;
          return (
            <Pressable
              key={t.key}
              style={styles.tab}
              onPress={() => setScreen(t.key)}
              android_ripple={{ color: '#e0e0e0', borderless: true }}
            >
              <Text style={[styles.tabIcon, active && styles.tabIconActive]}>{t.icon}</Text>
              <Text style={[styles.tabLabel, active && styles.tabLabelActive]} numberOfLines={1}>
                {t.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#fff',
  },
  content: {
    flex: 1,
  },
  // Bottom nav bar - approximates Material3 NavigationBar:
  //   - 80dp tall, surface background, top divider
  //   - icon (24sp) above 12sp label, both tinted with accent when active
  tabs: {
    flexDirection: 'row',
    borderTopWidth: 1,
    borderTopColor: '#e0e0e0',
    backgroundColor: '#fff',
    height: 64,
    paddingVertical: 6,
  },
  tab: {
    flex: 1,
    alignItems: 'center',
    justifyContent: 'center',
    gap: 2,
  },
  tabIcon: {
    fontSize: 22,
    color: '#999',
  },
  tabIconActive: {
    color: '#007AFF',
  },
  tabLabel: {
    fontSize: 11,
    color: '#999',
  },
  tabLabelActive: {
    color: '#007AFF',
    fontWeight: '600',
  },
});
