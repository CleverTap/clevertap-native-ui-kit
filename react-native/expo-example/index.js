// Expo entrypoint. `registerRootComponent` mirrors `AppRegistry.registerComponent`
// but pulls the app name from `app.json` automatically and sets up `expo-asset`,
// font loading, etc. Equivalent role to the bare example's index.js.
import { registerRootComponent } from 'expo';
import Video from 'react-native-video';
import LinearGradient from 'react-native-linear-gradient';
import * as Svg from 'react-native-svg';
import * as Reanimated from 'react-native-reanimated';
import { WebView } from 'react-native-webview';
import MaskedView from '@react-native-masked-view/masked-view';
import { BlurView } from '@react-native-community/blur';
import { Image as ExpoImage } from 'expo-image';
import { registerComponents } from '@clevertap/native-display-sdk';
import App from './App';

// Register the optional components this app provides.
// The SDK does not import these native libraries itself.
// This app imports each one and hands it to the SDK before any content renders.
// Each value matches the shape the SDK reads back:
//   Video, LinearGradient, MaskedView - default export.
//   WebView, BlurView, ExpoImage - named export.
//   Svg, Reanimated - the whole module namespace.
// This app has both react-native-linear-gradient and expo-linear-gradient.
// Both share the same API. We register the react-native one.
registerComponents({
  Video,
  LinearGradient,
  Svg,
  Reanimated,
  WebView,
  MaskedView,
  BlurView,
  ExpoImage,
});

registerRootComponent(App);
