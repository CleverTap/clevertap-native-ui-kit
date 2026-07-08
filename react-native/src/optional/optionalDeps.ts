import { NDLogger } from '../internal/NDLogger';

const cache = new Map<string, unknown>();
const NOT_INSTALLED = Symbol('not-installed');

type Loader<T> = () => T;

function tryLoad<T>(name: string, loader: Loader<T>): T | null {
  if (cache.has(name)) {
    const cached = cache.get(name);
    return cached === NOT_INSTALLED ? null : (cached as T);
  }
  try {
    const mod = loader();
    cache.set(name, mod);
    return mod;
  } catch {
    cache.set(name, NOT_INSTALLED);
    // Debug level, not warn: the useful, feature-specific warning is logged
    // where the feature is actually used (BackgroundRenderer, VideoElement).
    // Keeping this at debug avoids double-logging at the default INFO level.
    NDLogger.d(
      'NativeDisplay',
      `optional peer "${name}" not installed - related features will degrade gracefully.`,
    );
    return null;
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getLinearGradient = (): any | null => {
  // Prefer react-native-linear-gradient, fall back to expo-linear-gradient for
  // Expo. Both have the same API so BackgroundRenderer doesn't care which.
  const rn = tryLoad('react-native-linear-gradient', () => require('react-native-linear-gradient').default);
  if (rn) return rn;
  // Only try the Expo package in an Expo env.
  if (!process.env.EXPO_OS) return null;
  // eval('require') hides this require from Metro's static analyser, so a plain
  // RN project without expo-linear-gradient won't fail at bundle time. tryLoad
  // catches the runtime error if the package isn't there.
  // eslint-disable-next-line no-eval
  return tryLoad('expo-linear-gradient', () => eval('require')('expo-linear-gradient').LinearGradient);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getSvg = (): any | null =>
  tryLoad('react-native-svg', () => require('react-native-svg'));

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getReanimated = (): any | null =>
  tryLoad('react-native-reanimated', () => require('react-native-reanimated'));

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getWebView = (): any | null =>
  tryLoad('react-native-webview', () => require('react-native-webview').WebView);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getVideo = (): any | null =>
  tryLoad('react-native-video', () => require('react-native-video').default);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getMaskedView = (): any | null =>
  tryLoad(
    '@react-native-masked-view/masked-view',
    () => require('@react-native-masked-view/masked-view').default,
  );

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getBlurView = (): any | null =>
  tryLoad(
    '@react-native-community/blur',
    () => require('@react-native-community/blur').BlurView,
  );

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getExpoImage = (): any | null => {
  // expo-image only loads correctly in an Expo project (it needs
  // babel-preset-expo to inline process.env.EXPO_OS). In a plain RN project it
  // throws on load in a way our try/catch can't catch, crashing Metro. So we
  // check the same env var: if it isn't set, skip loading entirely.
  if (!process.env.EXPO_OS) return null;
  return tryLoad('expo-image', () => require('expo-image').Image);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getFastImage = (): any | null =>
  tryLoad('react-native-fast-image', () => require('react-native-fast-image').default);

export function clearOptionalDepsCache(): void {
  cache.clear();
}
