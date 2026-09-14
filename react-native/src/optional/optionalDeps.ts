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

// Why eval('require') for every optional peer below:
// Metro reads a plain require('pkg') at bundle time. If the package is not
// installed, the bundle fails to build. That happens before any code runs, so
// the tryLoad try/catch never gets a chance to catch it. eval('require') hides
// the module name from Metro's static analyser. Metro no longer tries to
// resolve the package at bundle time. A missing package now fails only at
// runtime, where tryLoad catches it and the feature degrades gracefully. This
// removes the need for a client-side Metro resolver stub.

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getLinearGradient = (): any | null => {
  // Prefer react-native-linear-gradient, fall back to expo-linear-gradient for
  // Expo. Both have the same API so BackgroundRenderer doesn't care which.
  // eslint-disable-next-line no-eval
  const rn = tryLoad('react-native-linear-gradient', () => eval('require')('react-native-linear-gradient').default);
  if (rn) return rn;
  // Only try the Expo package in an Expo env.
  if (!process.env.EXPO_OS) return null;
  // eslint-disable-next-line no-eval
  return tryLoad('expo-linear-gradient', () => eval('require')('expo-linear-gradient').LinearGradient);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getSvg = (): any | null =>
  // eslint-disable-next-line no-eval
  tryLoad('react-native-svg', () => eval('require')('react-native-svg'));

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getReanimated = (): any | null =>
  // eslint-disable-next-line no-eval
  tryLoad('react-native-reanimated', () => eval('require')('react-native-reanimated'));

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getWebView = (): any | null =>
  // eslint-disable-next-line no-eval
  tryLoad('react-native-webview', () => eval('require')('react-native-webview').WebView);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getVideo = (): any | null =>
  // eslint-disable-next-line no-eval
  tryLoad('react-native-video', () => eval('require')('react-native-video').default);

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getMaskedView = (): any | null =>
  tryLoad(
    '@react-native-masked-view/masked-view',
    // eslint-disable-next-line no-eval
    () => eval('require')('@react-native-masked-view/masked-view').default,
  );

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getBlurView = (): any | null =>
  tryLoad(
    '@react-native-community/blur',
    // eslint-disable-next-line no-eval
    () => eval('require')('@react-native-community/blur').BlurView,
  );

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getExpoImage = (): any | null => {
  // expo-image only loads correctly in an Expo project (it needs
  // babel-preset-expo to inline process.env.EXPO_OS). In a plain RN project it
  // throws on load in a way our try/catch can't catch, crashing Metro. So we
  // check the same env var: if it isn't set, skip loading entirely.
  if (!process.env.EXPO_OS) return null;
  // eslint-disable-next-line no-eval
  return tryLoad('expo-image', () => eval('require')('expo-image').Image);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getFastImage = (): any | null =>
  // eslint-disable-next-line no-eval
  tryLoad('react-native-fast-image', () => eval('require')('react-native-fast-image').default);

export function clearOptionalDepsCache(): void {
  cache.clear();
}
