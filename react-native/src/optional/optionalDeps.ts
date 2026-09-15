import { getRegisteredComponent } from './componentRegistry';

// Optional peer libraries reach the SDK through registerComponents, not through
// a require. The SDK never imports these libraries itself. The client imports
// the ones it uses. The client passes each one to registerComponents once at
// app startup. Each getter below reads the value back from that registry.
// A missing key means the feature is not wired. The feature then degrades
// gracefully at its use site (BackgroundRenderer, VideoElement, ImageElement).
//
// Why not require the packages here: Metro reads a plain require('pkg') at
// bundle time and never bundles the JS of a package it resolved through a
// hidden path. A runtime require then throws "unknown module" even when the
// package and its native pod are both installed. The registry side-steps the
// bundler completely. It works on Metro of any version, on Expo, and on
// Re.Pack.

// Each getter returns the value the consumer expects. The shape is decided by
// the client at registration time. See example index.js for the exact values.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getLinearGradient = (): any | null =>
  getRegisteredComponent('LinearGradient');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getSvg = (): any | null => getRegisteredComponent('Svg');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getReanimated = (): any | null =>
  getRegisteredComponent('Reanimated');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getWebView = (): any | null => getRegisteredComponent('WebView');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getVideo = (): any | null => getRegisteredComponent('Video');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getMaskedView = (): any | null =>
  getRegisteredComponent('MaskedView');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getBlurView = (): any | null => getRegisteredComponent('BlurView');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getExpoImage = (): any | null =>
  getRegisteredComponent('ExpoImage');

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getFastImage = (): any | null =>
  getRegisteredComponent('FastImage');
