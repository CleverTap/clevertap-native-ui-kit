import { NativeDisplayBridge } from './NativeDisplayBridge';

/**
 * Connect a CleverTap SDK instance to NativeDisplayBridge. Checks for the
 * methods it needs at runtime, so we don't import the CT SDK. Call once
 * from App.tsx after CleverTap is set up.
 *
 * @param cleverTap The default export from @clevertap/clevertap-react-native
 */
export function wireCleverTap(cleverTap: unknown): void {
  NativeDisplayBridge.shared.bind(cleverTap);
}
