import React, { useState, useEffect } from 'react';
import { View, Button, SafeAreaView, StyleSheet } from 'react-native';
import CleverTap from 'clevertap-react-native';
import { NativeDisplayBridge } from '@clevertap/native-display-sdk';
import { CleverTapIntegrationScreen } from './screens/CleverTapIntegrationScreen';
import { BridgeIntegrationScreen } from './screens/BridgeIntegrationScreen';
import { TestConfigBrowserScreen } from './screens/TestConfigBrowserScreen';
import { SlotDemoScreen } from './screens/SlotDemoScreen';
import { BannerShowcaseScreen } from './screens/BannerShowcaseScreen';
import { FontDemoScreen } from './screens/FontDemoScreen';

type Screen = 'ct' | 'bridge' | 'browser' | 'slots' | 'banners' | 'font';

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
      <View style={styles.tabs}>
        <View style={styles.tab}>
          <Button
            title="CT"
            onPress={() => setScreen('ct')}
            color={screen === 'ct' ? '#007AFF' : '#999'}
          />
        </View>
        <View style={styles.tab}>
          <Button
            title="Bridge"
            onPress={() => setScreen('bridge')}
            color={screen === 'bridge' ? '#007AFF' : '#999'}
          />
        </View>
        <View style={styles.tab}>
          <Button
            title="Browser"
            onPress={() => setScreen('browser')}
            color={screen === 'browser' ? '#007AFF' : '#999'}
          />
        </View>
        <View style={styles.tab}>
          <Button
            title="Slots"
            onPress={() => setScreen('slots')}
            color={screen === 'slots' ? '#007AFF' : '#999'}
          />
        </View>
        <View style={styles.tab}>
          <Button
            title="Banners"
            onPress={() => setScreen('banners')}
            color={screen === 'banners' ? '#007AFF' : '#999'}
          />
        </View>
        <View style={styles.tab}>
          <Button
            title="Fonts"
            onPress={() => setScreen('font')}
            color={screen === 'font' ? '#007AFF' : '#999'}
          />
        </View>
      </View>
      <View style={styles.content}>
        {screen === 'ct'      && <CleverTapIntegrationScreen />}
        {screen === 'bridge'  && <BridgeIntegrationScreen />}
        {screen === 'browser' && <TestConfigBrowserScreen />}
        {screen === 'slots'   && <SlotDemoScreen />}
        {screen === 'banners' && <BannerShowcaseScreen />}
        {screen === 'font'    && <FontDemoScreen />}
      </View>
    </SafeAreaView>
  );
}

const styles = StyleSheet.create({
  root: {
    flex: 1,
    backgroundColor: '#fff',
  },
  tabs: {
    flexDirection: 'row',
    borderBottomWidth: 1,
    borderBottomColor: '#e0e0e0',
    paddingHorizontal: 4,
    paddingVertical: 6,
    gap: 4,
  },
  tab: {
    flex: 1,
  },
  content: {
    flex: 1,
  },
});
