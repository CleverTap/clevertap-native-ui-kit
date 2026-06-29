//
//  NativeDisplaySdkVersion.ts
//  @clevertap/native-display-sdk (React Native)
//
//  Runtime version constants for the React Native Native Display SDK. These
//  are stamped onto every Notification Clicked / Notification Viewed event
//  the bridge forwards to the CleverTap Core SDK so the server can attribute
//  analytics back to a specific SDK build.
//
//  Mirrors `ios/Sources/CleverTapNativeDisplay/NativeDisplaySDKVersion.swift`
//  and Android's `BuildConfig.ND_LIB_VERSION_NAME` / `ND_LIB_VERSION_CODE`.
//  Each platform owns its own value; bump these whenever
//  `react-native/package.json` `version` changes.
//
//  We hard-code instead of dynamically reading `package.json` so the constants
//  don't depend on Metro bundling JSON files at runtime.
//

/**
 * Semver name. Keep in lockstep with `react-native/package.json` `version`.
 *
 * iOS and Android version this SDK independently; this value need not match
 * theirs. Used as the `nd_lib_v_name` event-attribution stamp on
 * Notification Viewed / Notification Clicked payloads.
 */
export const NAME: string = '0.1.0';

/**
 * Monotonic integer derived as `major * 10000 + minor * 100 + patch`.
 * For `0.1.0` this is `100`. Bump whenever `NAME` changes. Used as the
 * `nd_lib_v_code` event-attribution stamp.
 */
export const CODE: number = 100;

/**
 * Identity tag passed to the Core SDK's `setCustomSdkVersion(name, code)`
 * at bind time so Core SDK can attribute events back to "Native Display"
 * rather than the host's wrapper (`clevertap-react-native` tags itself as
 * `"React-Native"` at module load). Mirrors Android's `CUSTOM_SDK_NAME`
 * and iOS's equivalent autowire constant.
 */
export const LIBRARY_NAME: string = 'Native Display';

/**
 * Field names used in `additionalProperties` on Core SDK events. Identical
 * across iOS / Android / RN so the dashboard can slice events by SDK build
 * without per-platform forking.
 */
export const KEY_ND_LIB_VERSION_NAME = 'nd_lib_v_name';
export const KEY_ND_LIB_VERSION_CODE = 'nd_lib_v_code';
