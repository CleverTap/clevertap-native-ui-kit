import { NativeDisplayBridge } from './NativeDisplayBridge';

/**
 * Wire a CleverTap React Native SDK instance to NativeDisplayBridge.
 *
 * Checks at runtime for the required methods without importing the CT SDK.
 * Call this once from App.tsx after CleverTap is initialised.
 *
 * @param cleverTap  The default export from @clevertap/clevertap-react-native
 */
export function wireCleverTap(cleverTap: unknown): void {
  NativeDisplayBridge.shared.bind(cleverTap);
}
