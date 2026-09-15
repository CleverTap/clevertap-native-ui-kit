/**
 * RN 0.76 test app for the Native Display SDK.
 * Two tabs. Events records a CleverTap event and shows the bridge log.
 * Browser renders local ND template JSON through the on-device browser screen.
 */

import React, {useState, useEffect} from 'react';
import {
  View,
  Text,
  Pressable,
  StatusBar,
  SafeAreaView,
  StyleSheet,
} from 'react-native';
import CleverTap from 'clevertap-react-native';
import {NativeDisplayBridge, NDLogLevel} from '@clevertap/native-display-sdk';
import {CleverTapIntegrationScreen} from './screens/CleverTapIntegrationScreen';
import {TestConfigBrowserScreen} from './screens/TestConfigBrowserScreen';

type Screen = 'events' | 'browser';

const TABS: ReadonlyArray<{key: Screen; icon: string; label: string}> = [
  {key: 'events', icon: '📡', label: 'Events'},
  {key: 'browser', icon: '🧪', label: 'Browser'},
];

function App(): React.JSX.Element {
  const [screen, setScreen] = useState<Screen>('events');

  useEffect(() => {
    NativeDisplayBridge.shared.setLogLevel(NDLogLevel.DEBUG);
    // Bind the bridge to CleverTap and fetch display units.
    // This mirrors the 0.85 example and the native apps.
    NativeDisplayBridge.shared.bind(CleverTap);
    NativeDisplayBridge.shared.fetchNativeDisplays(CleverTap);
  }, []);

  return (
    <SafeAreaView style={styles.root}>
      <StatusBar barStyle="dark-content" />
      <View style={styles.content}>
        {screen === 'events' && <CleverTapIntegrationScreen />}
        {screen === 'browser' && <TestConfigBrowserScreen />}
      </View>
      <View style={styles.tabs}>
        {TABS.map(t => {
          const active = screen === t.key;
          return (
            <Pressable
              key={t.key}
              style={styles.tab}
              onPress={() => setScreen(t.key)}
              android_ripple={{color: '#e0e0e0', borderless: true}}>
              <Text style={[styles.tabIcon, active && styles.tabIconActive]}>
                {t.icon}
              </Text>
              <Text
                style={[styles.tabLabel, active && styles.tabLabelActive]}
                numberOfLines={1}>
                {t.label}
              </Text>
            </Pressable>
          );
        })}
      </View>
    </SafeAreaView>
  );
}

export default App;

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
