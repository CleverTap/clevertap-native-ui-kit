import { NativeModules } from 'react-native';
import { NativeDisplayUnit } from './NativeDisplayUnit';
import { NativeDisplayConfigParser } from './NativeDisplayConfigParser';
import { NativeDisplayUnitCache } from './NativeDisplayUnitCache';
import { deferToIdleAsync } from '../utils/threading';
import { sanitizeExtras } from '../handler/ActionAttributionExtras';
import { CODE as ND_LIB_VERSION_CODE, LIBRARY_NAME } from '../NativeDisplaySdkVersion';

export interface NativeDisplayBridgeListener {
  onNativeDisplaysLoaded(units: NativeDisplayUnit[]): void;
}

/**
 * Process-scoped set of unit IDs that have already fired "Notification
 * Viewed" in this JS context.
 *
 * The renderer calls `markViewedIfNew(unitId)` before pushing the viewed
 * event; it returns `true` only the first time we see that unitId in the
 * lifetime of the JS context. After that, repeat calls no-op so we don't
 * double-count impressions when a `NativeDisplayView` remounts (FlatList
 * virtualization recycling, react-navigation blur/focus, conditional
 * rendering toggles, hot reload).
 *
 * Mirrors `android/sdk/.../bridge/ViewedUnitsTracker.kt`; the RN flavour is
 * simpler because RN has no Activity-style configuration changes to wait
 * out before pruning. Hosts that want a unit to re-fire Viewed (e.g. after
 * `onUserLogin`, or after a manual "show me this fresh" gesture) can call
 * `NativeDisplayBridge.shared.resetViewedTracker(unitId?)` - omit the
 * arg to clear everything.
 */
const _viewedUnits = new Set<string>();

/**
 * Identity reference to the `NativeModules.CleverTapReact` module instance
 * we last stamped with `setLibrary('Native Display', CODE)`. Guards against
 * re-tagging when `bind()` runs more than once for the same instance (Fast
 * Refresh during dev, host re-binding, etc.). When a different instance
 * arrives (rare in production), the tag fires again.
 *
 * Mirrors Android `CleverTapAutoWire.taggedInstance` semantics.
 */
let _taggedCleverTapNativeModule: unknown = null;

/**
 * Tag the underlying CleverTap Core SDK instance with this wrapper SDK's
 * identity (`"Native Display"`) and version code via
 * `clevertap-react-native`'s native module surface so Core SDK can attribute
 * subsequent analytics back to ND - matches Android's `setCustomSdkVersion`
 * tagging in `CleverTapAutoWire`.
 *
 * Why we reach into `NativeModules.CleverTapReact` directly:
 *
 *   `clevertap-react-native` exposes `setLibrary(name, version)` on the
 *   underlying TurboModule (which calls Core SDK's
 *   `setCustomSdkVersion` internally on both platforms), but it does NOT
 *   re-export it on the public `CleverTap` JS object that `bind()`
 *   receives. The module-load bootstrap call at the top of
 *   `clevertap-react-native/src/index.js` is the only place it's invoked
 *   today (it tags itself as `"React-Native"`).
 *
 *   So to overwrite that tag with `"Native Display"`, we have to go through
 *   the native module by name. This is stable - the module name has been
 *   `CleverTapReact` since `clevertap-react-native` 1.x. If the name ever
 *   changes upstream, this no-ops (try/catch) and the click attribution
 *   still works, just without the wrapper-SDK identity tag.
 *
 * One-shot per native-module reference: re-binding the same CleverTap is
 * a no-op. Wrapped in try/catch so any unexpected runtime issue (missing
 * NativeModules in a non-RN environment, host SDK on a fork that renamed
 * the module, etc.) degrades silently with a warning instead of crashing
 * `bind()`.
 */
function _tagNativeDisplayLibrary(): void {
  try {
    const modules = NativeModules as Record<string, unknown> | null | undefined;
    const ctRaw = modules?.['CleverTapReact'];
    if (!ctRaw || typeof ctRaw !== 'object') return;
    if (_taggedCleverTapNativeModule === ctRaw) return;
    const ctMod = ctRaw as Record<string, unknown>;
    if (typeof ctMod['setLibrary'] !== 'function') {
      console.warn(
        '[NativeDisplayBridge] Cannot tag Core SDK with "Native Display": ' +
        'NativeModules.CleverTapReact.setLibrary not found. ' +
        'Update `@clevertap/clevertap-react-native` to enable wrapper SDK attribution.',
      );
      return;
    }
    (ctMod['setLibrary'] as (name: string, version: number) => void)(
      LIBRARY_NAME,
      ND_LIB_VERSION_CODE,
    );
    _taggedCleverTapNativeModule = ctRaw;
    console.log(
      `[NativeDisplayBridge] Tagged Core SDK as "${LIBRARY_NAME}" version ${ND_LIB_VERSION_CODE}`,
    );
  } catch (e) {
    console.warn('[NativeDisplayBridge] setLibrary tagging failed:', e);
  }
}

export class NativeDisplayBridge {
  private static _instance: NativeDisplayBridge | null = null;

  static get shared(): NativeDisplayBridge {
    if (!this._instance) {
      this._instance = new NativeDisplayBridge();
    }
    return this._instance;
  }

  private readonly _parser = new NativeDisplayConfigParser();
  private readonly _cache = new NativeDisplayUnitCache();
  private readonly _listeners = new Set<NativeDisplayBridgeListener>();
  private _cleverTap: Record<string, unknown> | null = null;
  private _ctListener: ((event: unknown) => void) | null = null;

  bind(cleverTap: unknown): void {
    if (!cleverTap || typeof cleverTap !== 'object') {
      console.warn('[NativeDisplayBridge] bind() received a non-object. Ignoring.');
      return;
    }

    const ct = cleverTap as Record<string, unknown>;

    const missing = ['addListener', 'pushDisplayUnitViewedEventForID', 'pushDisplayUnitClickedEventForID']
      .filter((key) => typeof ct[key] !== 'function');

    if (missing.length > 0) {
      console.warn(
        `[NativeDisplayBridge] CleverTap instance is missing: ${missing.join(', ')}. ` +
        'Minimum supported version is @clevertap/clevertap-react-native >= 0.4.0.',
      );
    }

    this._cleverTap = ct;

    // Stamp the Core SDK with this wrapper's identity (`"Native Display"`)
    // so subsequent analytics events get attributed to ND rather than the
    // host's generic `"React-Native"` tag. See `_tagNativeDisplayLibrary`
    // for why this goes through `NativeModules` directly.
    _tagNativeDisplayLibrary();

    if (typeof ct['addListener'] === 'function') {
      const eventName = this._resolveDisplayUnitsLoadedEvent(ct);
      if (eventName) {
        this._ctListener = (event: unknown) => {
          this._handleCleverTapDisplayUnitsEvent(event);
        };
        (ct['addListener'] as (name: string, handler: (e: unknown) => void) => void)(
          eventName,
          this._ctListener,
        );
      }
    }
  }

  /**
   * Fetch any display units already cached by the CleverTap SDK and deliver
   * them to all registered listeners.
   *
   * Call this once at startup, right after bind() - same as the native apps:
   *   iOS:     bridge.bind(ct); bridge.fetchNativeDisplays(ct)
   *   Android: bridge.bind(ct); bridge.fetchNativeDisplays(ct)
   */
  fetchNativeDisplays(cleverTap: unknown): void {
    const ct = cleverTap as Record<string, unknown>;
    if (!ct || typeof ct !== 'object') return;

    if (typeof ct['getAllDisplayUnits'] === 'function') {
      (ct['getAllDisplayUnits'] as (cb: (err: unknown, res: unknown) => void) => void)(
        (err, res) => {
          if (err || !res) return;
          const jsonStrings = this._extractJsonStrings(res);
          if (jsonStrings.length > 0) {
            this.processDisplayUnits(jsonStrings);
          }
        },
      );
    } else {
      console.warn('[NativeDisplayBridge] fetchNativeDisplays: getAllDisplayUnits not available on CleverTap instance.');
    }
  }

  processDisplayUnit(jsonString: string): void {
    deferToIdleAsync(() => {
      const unit = this._parser.tryParse(jsonString);
      if (!unit) {
        console.warn('[NativeDisplayBridge] Failed to parse display unit. Check JSON format.');
        return;
      }
      this._cache.put(unit);
      console.log(`[NativeDisplayBridge] Processed 1 display unit: ${unit.unitId}`);
      this._notifyListeners([unit]);
    });
  }

  processDisplayUnits(jsonStrings: string[]): void {
    deferToIdleAsync(() => {
      const units: NativeDisplayUnit[] = [];
      for (const json of jsonStrings) {
        const unit = this._parser.tryParse(json);
        if (unit) units.push(unit);
      }
      if (units.length === 0) {
        console.warn('[NativeDisplayBridge] No display units could be parsed from the provided JSON strings.');
        return;
      }
      for (const unit of units) this._cache.put(unit);
      console.log(`[NativeDisplayBridge] Processed ${units.length} display unit(s).`);
      this._notifyListeners(units);
    });
  }

  addListener(listener: NativeDisplayBridgeListener): void {
    this._listeners.add(listener);
  }

  removeListener(listener: NativeDisplayBridgeListener): void {
    this._listeners.delete(listener);
  }

  getAllNativeDisplays(): NativeDisplayUnit[] {
    return this._cache.getAll();
  }

  getNativeDisplayForId(unitId: string): NativeDisplayUnit | null {
    return this._cache.get(unitId) ?? null;
  }

  /**
   * Forget that the given unit (or all units, if omitted) has already
   * fired `Notification Viewed`, so the next mount will re-fire the event.
   *
   * Typical use: call from a host's `onUserLogin` / logout / identity-change
   * handler so post-login impressions get counted again. Tests can also
   * call `resetViewedTracker()` with no args to clear the whole set
   * between cases.
   */
  resetViewedTracker(unitId?: string): void {
    if (unitId) {
      _viewedUnits.delete(unitId);
    } else {
      _viewedUnits.clear();
    }
  }

  /**
   * Push a "Notification Viewed" event to CleverTap. Always sanitizes and
   * stamps the ND SDK version (`nd_lib_v_name` / `nd_lib_v_code`) onto the
   * payload, then prefers the extras-aware Core SDK method
   * (`pushDisplayUnitViewedEventForIDWithProperties(id, props)`) when it's
   * exposed by the installed `clevertap-react-native` version, falling back
   * to the legacy 1-arg `pushDisplayUnitViewedEventForID(id)` otherwise.
   *
   * `extras` is currently always empty at call sites - the SDK version
   * stamp is the only attribution we attach to a Viewed event - but the
   * parameter is there so we don't have to widen the signature again the
   * next time we want to carry more data (matches Android + iOS).
   */
  pushViewedEvent(unitId: string, extras?: Record<string, unknown>): void {
    const ct = this._cleverTap;
    if (!ct) return;

    // Dedupe across remounts. Anonymous units (no unitId - preview / raw-JSON
    // paths) skip the check and fire every time, matching native behavior.
    // Hosts that need a unit to re-fire (e.g. on logout / identity change)
    // call `resetViewedTracker(unitId?)` to evict it from the set first.
    if (unitId) {
      if (_viewedUnits.has(unitId)) {
        return;
      }
      _viewedUnits.add(unitId);
    }

    const props = sanitizeExtras(extras);

    if (typeof ct['pushDisplayUnitViewedEventForIDWithProperties'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing viewed event (with extras) for unit: ${unitId}`);
      (ct['pushDisplayUnitViewedEventForIDWithProperties'] as (id: string, p: Record<string, unknown>) => void)(
        unitId,
        props,
      );
      return;
    }

    if (typeof ct['pushDisplayUnitViewedEventForID'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing viewed event for unit: ${unitId}`);
      (ct['pushDisplayUnitViewedEventForID'] as (id: string) => void)(unitId);
    } else {
      console.warn(`[NativeDisplayBridge] pushDisplayUnitViewedEventForID not available. Viewed event for ${unitId} not sent.`);
    }
  }

  /**
   * Push a "Notification Clicked" event to CleverTap with optional
   * element-level attribution extras.
   *
   * Extras are always routed through `sanitizeExtras`, which (a) drops
   * non-transportable values and (b) unconditionally stamps the ND SDK
   * version (`nd_lib_v_name` / `nd_lib_v_code`). Result: every click
   * reaching Core SDK can be attributed to a specific SDK build, matching
   * Android + iOS.
   *
   * Prefers the element-aware Core SDK method
   * (`pushDisplayUnitElementClickedEventForID(id, additionalProperties)`).
   * Falls back to the legacy `pushDisplayUnitClickedEventForID(id)` with a
   * warning if the host SDK is too old to know about the new method - the
   * click still records, just without the extras.
   */
  pushClickedEvent(unitId: string, extras?: Record<string, unknown>): void {
    const ct = this._cleverTap;
    if (!ct) return;
    const props = sanitizeExtras(extras);

    if (typeof ct['pushDisplayUnitElementClickedEventForID'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing element-clicked event for unit: ${unitId}`);
      (ct['pushDisplayUnitElementClickedEventForID'] as (id: string, p: Record<string, unknown>) => void)(
        unitId,
        props,
      );
      return;
    }

    if (typeof ct['pushDisplayUnitClickedEventForID'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing clicked event for unit: ${unitId}`);
      (ct['pushDisplayUnitClickedEventForID'] as (id: string) => void)(unitId);
      console.warn(
        '[NativeDisplayBridge] pushDisplayUnitElementClickedEventForID not available; ' +
        'element attribution + SDK version stamp were not forwarded to Core SDK. ' +
        'Update `@clevertap/clevertap-react-native` to receive attribution data.',
      );
    } else {
      console.warn(`[NativeDisplayBridge] pushDisplayUnitClickedEventForID not available. Clicked event for ${unitId} not sent.`);
    }
  }

  private _notifyListeners(units: NativeDisplayUnit[]): void {
    for (const listener of this._listeners) {
      try {
        listener.onNativeDisplaysLoaded(units);
      } catch (e) {
        console.error('[NativeDisplayBridge] Listener threw an exception:', e);
      }
    }
  }

  private _resolveDisplayUnitsLoadedEvent(ct: Record<string, unknown>): string | null {
    // Use the event name constant if the CT instance exposes it
    if (typeof ct['CleverTapDisplayUnitsLoaded'] === 'string') {
      return ct['CleverTapDisplayUnitsLoaded'];
    }
    // Fall back to the known string value
    return 'CleverTapDisplayUnitsLoaded';
  }

  private _handleCleverTapDisplayUnitsEvent(event: unknown): void {
    if (!event || typeof event !== 'object') return;
    const e = event as Record<string, unknown>;
    // The CT RN SDK sends the event as { displayUnits: [...] } or as a plain array
    const units = Array.isArray(e) ? e : (e['displayUnits'] as unknown[] | undefined);
    if (!Array.isArray(units)) return;
    const jsonStrings = this._extractJsonStrings(units);
    if (jsonStrings.length > 0) {
      this.processDisplayUnits(jsonStrings);
    }
  }

  private _extractJsonStrings(raw: unknown): string[] {
    if (typeof raw === 'string') {
      try {
        const parsed = JSON.parse(raw);
        return Array.isArray(parsed)
          ? (parsed as unknown[]).map((item) =>
              typeof item === 'string' ? item : JSON.stringify(item),
            )
          : [raw];
      } catch {
        return [raw];
      }
    }
    if (Array.isArray(raw)) {
      return (raw as unknown[]).map((item) =>
        typeof item === 'string' ? item : JSON.stringify(item),
      );
    }
    return [];
  }
}
