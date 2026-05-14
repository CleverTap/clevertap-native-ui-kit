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
    // eslint-disable-next-line no-console
    console.info(
      `[NativeDisplay] optional peer "${name}" not installed - related features will degrade gracefully.`,
    );
    return null;
  }
}

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getLinearGradient = (): any | null => {
  // Prefer react-native-linear-gradient; fall back to expo-linear-gradient for Expo clients.
  // Both expose the same start/end/colors API so BackgroundRenderer works unchanged.
  const rn = tryLoad('react-native-linear-gradient', () => require('react-native-linear-gradient').default);
  if (rn) return rn;
  // expo-linear-gradient uses expo-modules-core and requires the Expo env (same guard as expo-image).
  if (!process.env.EXPO_OS) return null;
  // eval('require') is the standard Metro escape hatch: Metro's static analyser
  // does not follow requires inside eval, so bare-RN projects that don't have
  // expo-linear-gradient installed will never see a bundle-time resolution error.
  // The tryLoad wrapper catches any runtime error if the package is absent.
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
  // expo-image needs babel-preset-expo to inline process.env.EXPO_OS at build
  // time. In a bare React Native project that transform is missing, so the
  // module throws on load - before our try/catch can catch it - and Metro
  // reports a fatal error. We guard with the same env var expo itself checks:
  // if it was never inlined, the value is the literal string 'undefined' which
  // is falsy, so we skip the load entirely.
  //
  // In an Expo-managed or bare-with-expo-modules project the var is inlined to
  // 'ios', 'android', or 'web', so the load proceeds normally.
  if (!process.env.EXPO_OS) return null;
  return tryLoad('expo-image', () => require('expo-image').Image);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getFastImage = (): any | null =>
  tryLoad('react-native-fast-image', () => require('react-native-fast-image').default);

export function clearOptionalDepsCache(): void {
  cache.clear();
}
