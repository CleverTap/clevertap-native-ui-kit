/**
 * @format
 */

import { AppRegistry } from 'react-native';
import Video from 'react-native-video';
import LinearGradient from 'react-native-linear-gradient';
import * as Svg from 'react-native-svg';
import * as Reanimated from 'react-native-reanimated';
import { WebView } from 'react-native-webview';
import MaskedView from '@react-native-masked-view/masked-view';
import { BlurView } from '@react-native-community/blur';
import FastImage from 'react-native-fast-image';
import { registerComponents } from '@clevertap/native-display-sdk';
import App from './App';
import { name as appName } from './app.json';

// Register the optional components this app provides.
// The SDK does not import these native libraries itself.
// This app imports each one and hands it to the SDK before any content renders.
// Each value matches the shape the SDK reads back:
//   Video, LinearGradient, MaskedView, FastImage - default export.
//   WebView, BlurView - named export.
//   Svg, Reanimated - the whole module namespace.
registerComponents({
  Video,
  LinearGradient,
  Svg,
  Reanimated,
  WebView,
  MaskedView,
  BlurView,
  FastImage,
});

AppRegistry.registerComponent(appName, () => App);
