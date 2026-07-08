//
//  NativeDisplaySdkVersion.ts
//  @clevertap/native-display-sdk (React Native)
//
//  Version constants stamped onto every Notification Viewed / Clicked event so
//  the server knows which SDK build sent it. Each platform has its own copy;
//  bump these when react-native/package.json `version` changes.
//
//  Hard-coded instead of read from package.json so we don't rely on Metro
//  bundling JSON at runtime.
//

/**
 * Semver string. Keep in sync with `react-native/package.json` `version`.
 * Sent as the `nd_lib_v_name` stamp on events; matches iOS/Android so the
 * dashboard reads the same value everywhere.
 */
export const NAME: string = '1.0.0';

/**
 * Integer version: `major * 10000 + minor * 100 + patch` (1.0.0 -> 10000).
 * Matches iOS/Android. Bump when `NAME` changes. Sent as the `nd_lib_v_code`
 * stamp on events.
 */
export const CODE: number = 10000;

/**
 * Name passed to the Core SDK's `setCustomSdkVersion(name, code)` so events are
 * attributed to "Native Display" rather than the host wrapper
 * (clevertap-react-native tags itself as "React-Native"). Matches iOS/Android.
 */
export const LIBRARY_NAME: string = 'Native Display';

/**
 * Property keys added to Core SDK events. Same on iOS/Android/RN so the
 * dashboard can filter events by SDK build.
 */
export const KEY_ND_LIB_VERSION_NAME = 'nd_lib_v_name';
export const KEY_ND_LIB_VERSION_CODE = 'nd_lib_v_code';
