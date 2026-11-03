// Client-provided optional components live here.
// The SDK does not import the optional native libraries itself.
// The client imports the libraries it uses. The client registers them once at
// app startup. Each getter in optionalDeps.ts reads from this map.
// A missing key means the feature is not wired. The feature then degrades
// gracefully.

export type OptionalComponentKey =
  | 'Video'
  | 'LinearGradient'
  | 'Svg'
  | 'WebView'
  | 'MaskedView'
  | 'BlurView'
  | 'FastImage'
  | 'ExpoImage'
  | 'Reanimated';

const registry = new Map<OptionalComponentKey, unknown>();

// Register optional components the app provides.
// Call this once at startup, before any Native Display content renders.
// Pass the value each library expects the SDK to use. For example, pass the
// default export of react-native-video under the "Video" key.
export function registerComponents(
  components: Partial<Record<OptionalComponentKey, unknown>>,
): void {
  for (const key of Object.keys(components) as OptionalComponentKey[]) {
    const value = components[key];
    if (value != null) registry.set(key, value);
  }
}

export function getRegisteredComponent(key: OptionalComponentKey): unknown | null {
  return registry.get(key) ?? null;
}
