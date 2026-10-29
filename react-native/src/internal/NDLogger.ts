//
//  NDLogger.ts
//  @clevertap/native-display-sdk (React Native)
//
//  Level-gated logger for the Native Display SDK. Matches the Android and iOS
//  loggers so output looks the same on every platform. Levels use the same
//  integer values as the Core SDK's setDebugLevel, so syncFromCoreSdk can map
//  a Core level straight across.
//

/**
 * Log levels for the SDK. Values match the Core SDK's setDebugLevel numbers:
 *   OFF (-1)     - no logs
 *   INFO (0)     - warnings + errors only (production default)
 *   DEBUG (2)    - dev-level detail
 *   VERBOSE (3)  - everything
 *
 * Higher value = more logs (VERBOSE > DEBUG > INFO). Warnings and errors always
 * show at INFO and above.
 *
 * ```ts
 * NativeDisplayBridge.shared.setLogLevel(NDLogLevel.DEBUG); // verbose dev builds
 * NativeDisplayBridge.shared.setLogLevel(NDLogLevel.OFF);   // silence in production
 * ```
 */
export enum NDLogLevel {
  OFF = -1,
  INFO = 0,
  DEBUG = 2,
  VERBOSE = 3,
}

/**
 * Maps a Core SDK debug level number to an {@link NDLogLevel}. Unknown values
 * fall back to `DEBUG` (e.g. a level added by a newer Core SDK).
 */
function levelFromInt(v: number): NDLogLevel {
  switch (v) {
    case NDLogLevel.OFF:
      return NDLogLevel.OFF;
    case NDLogLevel.INFO:
      return NDLogLevel.INFO;
    case NDLogLevel.DEBUG:
      return NDLogLevel.DEBUG;
    case NDLogLevel.VERBOSE:
      return NDLogLevel.VERBOSE;
    default:
      return NDLogLevel.DEBUG;
  }
}

// JS is single-threaded, so no lock is needed here (Android/iOS synchronize).
let _level: NDLogLevel = NDLogLevel.INFO;
let _explicitlySet = false;

// console has no separate tag argument like logcat/Xcode do, so we put the
// CleverTap namespace in the message prefix. Format matches iOS exactly so log
// lines look the same on every platform.
function format(tag: string, msg: string): string {
  return `[CleverTap]: [NativeDisplay]: ${tag}: ${msg}`;
}

/**
 * Internal logger. SDK code calls `NDLogger.d(...)` etc. Clients don't use it
 * directly; they set the level via `NativeDisplayBridge.shared.setLogLevel`.
 */
export const NDLogger = {
  /** Set the active level. Marks the preference as explicitly client-set. */
  setLevel(level: NDLogLevel): void {
    _level = level;
    _explicitlySet = true;
  },

  /** Currently active level. */
  getLevel(): NDLogLevel {
    return _level;
  },

  /** True once a client has called {@link setLevel}. */
  isExplicitlySet(): boolean {
    return _explicitlySet;
  },

  /**
   * Adopts a Core SDK debug level. Does NOT mark the level as explicitly set,
   * so a later re-sync can still change it - until the client calls
   * {@link setLevel}, which then wins for good.
   */
  syncFromCoreSdk(coreLevel: number): void {
    if (!_explicitlySet) {
      _level = levelFromInt(coreLevel);
    }
  },

  // Trailing args (an Error, an info object, etc.) are passed straight to
  // console so error objects keep their stack traces instead of becoming
  // "[object Object]". Like the native loggers' `throwable` parameter.

  v(tag: string, msg: string, ...args: unknown[]): void {
    if (_level >= NDLogLevel.VERBOSE) console.debug(format(tag, msg), ...args);
  },

  d(tag: string, msg: string, ...args: unknown[]): void {
    if (_level >= NDLogLevel.DEBUG) console.log(format(tag, msg), ...args);
  },

  i(tag: string, msg: string, ...args: unknown[]): void {
    if (_level >= NDLogLevel.INFO) console.info(format(tag, msg), ...args);
  },

  /** Warnings surface at INFO and above - they are always significant. */
  w(tag: string, msg: string, ...args: unknown[]): void {
    if (_level >= NDLogLevel.INFO) console.warn(format(tag, msg), ...args);
  },

  /** Errors surface at INFO and above - they are always significant. */
  e(tag: string, msg: string, ...args: unknown[]): void {
    if (_level >= NDLogLevel.INFO) console.error(format(tag, msg), ...args);
  },
};
