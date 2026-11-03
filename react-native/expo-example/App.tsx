import React, { useState, useEffect } from 'react';
import { View, Text, Pressable, SafeAreaView, StyleSheet } from 'react-native';
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
// Screens are imported from the bare-RN example via a Metro alias so both
// example apps render the SAME UI 1:1 - changes in one show up in both.
// See `metro.config.js` and `tsconfig.json` for the `@bare-example/*` mapping.
import { CleverTapIntegrationScreen } from '@bare-example/screens/CleverTapIntegrationScreen';
import { BridgeIntegrationScreen } from '@bare-example/screens/BridgeIntegrationScreen';
import { TestConfigBrowserScreen } from '@bare-example/screens/TestConfigBrowserScreen';
import { SlotDemoScreen } from '@bare-example/screens/SlotDemoScreen';
import { BannerShowcaseScreen } from '@bare-example/screens/BannerShowcaseScreen';
import { FontDemoScreen } from '@bare-example/screens/FontDemoScreen';

type Screen = 'ct' | 'bridge' | 'browser' | 'slots' | 'banners' | 'font';

// Same tab order as the bare example so chip strip indices line up across apps.
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

  // Identical bridge wiring to the bare example - clevertap-expo-plugin handles
  // CleverTap initialization at prebuild + native-app-launch time, so by the
  // time this useEffect runs, the SDK is already up and ready to bind.
  useEffect(() => {
    NativeDisplayBridge.shared.bind(CleverTap);
    NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.content}>
        {screen === 'ct'      && <CleverTapIntegrationScreen />}
        {screen === 'bridge'  && <BridgeIntegrationScreen />}
        {screen === 'browser' && <TestConfigBrowserScreen />}
        {screen === 'slots'   && <SlotDemoScreen />}
        {screen === 'banners' && <BannerShowcaseScreen />}
        {screen === 'font'    && <FontDemoScreen />}
      </View>
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
