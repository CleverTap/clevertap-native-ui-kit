import React, { useState, useEffect } from 'react';
import { View, Text, Pressable, StatusBar, StyleSheet, Platform, Linking } from 'react-native';
import { SafeAreaProvider, SafeAreaView } from 'react-native-safe-area-context';
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
import { parseAutomationUrl, triggerAutomation } from './screenshotAutomation';
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

    // Register for push so the device token reaches the CleverTap dashboard.
    // "Preview and test" for Native Display sends a push to that token.
    // iOS: registerForPush asks for notification permission, then registers
    //   for remote notifications. autoIntegrate forwards the APNs token.
    // Android: registerForPush is a no-op in the SDK. The runtime
    //   POST_NOTIFICATIONS dialog comes from promptForPushPermission. The FCM
    //   token is captured and forwarded by the SDK once Firebase is set up.
    if (Platform.OS === 'ios') {
      CleverTap.registerForPush();
    } else {
      CleverTap.promptForPushPermission(true);
    }

    // "Preview and test" delivers the config inside the push, under the
    // `wzrk_adunit` key, not through the server display-units pipeline. When
    // the user taps the push, this handler pulls that config out and hands it
    // to the renderer. The bridge parser reads the "advanced-builder" wrapper
    // and its `native_display_config` on its own.
    const onPushClicked = (payload: Record<string, unknown> | null): void => {
      if (!payload) return;
      const adunit = payload.wzrk_adunit;
      if (typeof adunit === 'string' && adunit.length > 0) {
        NativeDisplayBridge.shared.processDisplayUnit(adunit);
      }
    };
    CleverTap.addListener(CleverTap.CleverTapPushNotificationClicked, onPushClicked);

    return () => {
      CleverTap.removeListener(CleverTap.CleverTapPushNotificationClicked);
    };
  // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // ─── Screenshot automation deep link ──────────────────────────────────────
  // Opening `ndautomation://events?settle=<seconds>` drives the app for the
  // cross-platform screenshot comparison: switch to the Events tab, then let
  // that screen fire the 22 canonical CleverTap events one every `settle`
  // seconds. Handles both cold start (getInitialURL) and warm foreground
  // (Linking 'url' event). This is inert unless the URL is opened, so it has no
  // effect on normal usage.
  useEffect(() => {
    const handleUrl = (url: string | null): void => {
      const request = parseAutomationUrl(url);
      if (!request) return;
      setScreen('ct');
      triggerAutomation(request);
    };

    Linking.getInitialURL().then(handleUrl).catch(() => {});
    const sub = Linking.addEventListener('url', ({ url }) => handleUrl(url));
    return () => sub.remove();
  }, []);

  return (
    <SafeAreaProvider>
      <StatusBar barStyle="dark-content" translucent backgroundColor="transparent" />
      {/* SafeAreaView from safe-area-context pads for the status bar (top) and the
          navigation / gesture bar (bottom) on both platforms. With edge-to-edge
          on Android, content draws behind the system bars, so these insets keep
          the header and tab bar clear of them. */}
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
    </SafeAreaProvider>
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
