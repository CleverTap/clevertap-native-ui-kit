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
export const getLinearGradient = (): any | null =>
  tryLoad('react-native-linear-gradient', () => require('react-native-linear-gradient').default);

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
  // expo-image requires babel-preset-expo to inline process.env.EXPO_OS at
  // build time. In a bare React Native project that transform is absent, so
  // the module throws at initialisation — before our try/catch can intercept
  // it — causing Metro to report a fatal error. Guard with the same env var
  // check expo itself uses: if it was never inlined the string is literally
  // 'undefined', which is falsy, so we skip the load entirely.
  //
  // In an Expo-managed/bare-with-expo-modules project the var is inlined to
  // 'ios' / 'android' / 'web', so the load proceeds normally.
  if (!process.env.EXPO_OS) return null;
  return tryLoad('expo-image', () => require('expo-image').Image);
};

// eslint-disable-next-line @typescript-eslint/no-explicit-any
export const getFastImage = (): any | null =>
  tryLoad('react-native-fast-image', () => require('react-native-fast-image').default);

export function clearOptionalDepsCache(): void {
  cache.clear();
}
