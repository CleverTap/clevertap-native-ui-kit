import React, { useState } from 'react';
import { View, Button, SafeAreaView, StyleSheet } from 'react-native';
import { CleverTapIntegrationScreen } from './screens/CleverTapIntegrationScreen';
import { BridgeIntegrationScreen } from './screens/BridgeIntegrationScreen';
import { TestConfigBrowserScreen } from './screens/TestConfigBrowserScreen';

type Screen = 'ct' | 'bridge' | 'browser';

export default function App(): React.ReactElement {
  const [screen, setScreen] = useState<Screen>('ct');

  return (
    <SafeAreaView style={styles.root}>
      <View style={styles.tabs}>
        <View style={styles.tab}>
          <Button
            title="CT Integration"
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
      </View>
      <View style={styles.content}>
        {screen === 'ct'     && <CleverTapIntegrationScreen />}
        {screen === 'bridge' && <BridgeIntegrationScreen />}
        {screen === 'browser' && <TestConfigBrowserScreen />}
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
