import { NativeModules } from 'react-native';
import { NativeDisplayUnit } from './NativeDisplayUnit';
import { NativeDisplayConfigParser } from './NativeDisplayConfigParser';
import { NativeDisplayUnitCache } from './NativeDisplayUnitCache';
import { deferToIdleAsync } from '../utils/threading';
import { sanitizeExtras } from '../handler/ActionAttributionExtras';
import { CODE as ND_LIB_VERSION_CODE, LIBRARY_NAME } from '../NativeDisplaySdkVersion';
import { NDLogger, NDLogLevel } from '../internal/NDLogger';

export interface NativeDisplayBridgeListener {
  onNativeDisplaysLoaded(units: NativeDisplayUnit[]): void;
}

/**
 * Unit IDs that already fired "Notification Viewed" in this JS context.
 * We track them so a view remounting (list recycling, navigation, hot
 * reload) doesn't count the same impression twice. Call
 * `resetViewedTracker(unitId?)` to let a unit fire again.
 */
const _viewedUnits = new Set<string>();

/**
 * The CleverTap native module we last tagged with setLibrary(). We keep it
 * so re-running bind() on the same instance (e.g. Fast Refresh) doesn't
 * tag it again. A new instance gets tagged fresh.
 */
let _taggedCleverTapNativeModule: unknown = null;

/**
 * Tell the CleverTap Core SDK that events come from "Native Display" (with
 * our version) so analytics get attributed to us.
 *
 * We call setLibrary() straight on NativeModules.CleverTapReact because the
 * public CleverTap JS object doesn't expose it - only the native module
 * does. The module name has been stable since v1.x. If anything is missing
 * or fails, the try/catch just warns and clicks still work, only without
 * our identity tag.
 */
function _tagNativeDisplayLibrary(): void {
  try {
    const modules = NativeModules as Record<string, unknown> | null | undefined;
    const ctRaw = modules?.['CleverTapReact'];
    if (!ctRaw || typeof ctRaw !== 'object') return;
    if (_taggedCleverTapNativeModule === ctRaw) return;
    const ctMod = ctRaw as Record<string, unknown>;
    if (typeof ctMod['setLibrary'] !== 'function') {
      NDLogger.w(
        'NativeDisplayBridge',
        'Cannot tag Core SDK with "Native Display": ' +
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
    NDLogger.d(
      'NativeDisplayBridge',
      `Tagged Core SDK as "${LIBRARY_NAME}" version ${ND_LIB_VERSION_CODE}`,
    );
  } catch (e) {
    NDLogger.w('NativeDisplayBridge', 'setLibrary tagging failed:', e);
  }
}

/**
 * Copy the Core SDK's debug level so our logs follow the same setting the
 * host already picked, with no second logger to configure. This stops
 * applying once the client calls setLogLevel() themselves.
 *
 * getDebugLevel() isn't stable across versions, so we probe for it and
 * handle all three shapes it might have: a plain number, an (err, level)
 * callback, or a Promise. Anything unexpected is ignored and we keep our
 * INFO default.
 */
function _syncLogLevelFromCoreSdk(ct: Record<string, unknown>): void {
  try {
    const getter = ct['getDebugLevel'];
    if (typeof getter !== 'function') return;

    const apply = (raw: unknown): void => {
      const n = typeof raw === 'number' ? raw : Number(raw);
      if (Number.isFinite(n)) {
        NDLogger.syncFromCoreSdk(n);
      }
    };

    // Callback form: getDebugLevel((err, level) => ...)
    const result = (getter as (cb?: (err: unknown, level: unknown) => void) => unknown)(
      (err, level) => {
        if (!err) apply(level);
      },
    );

    // Plain-number form: getDebugLevel() returns the level directly.
    if (typeof result === 'number') {
      apply(result);
      return;
    }

    // Promise form: getDebugLevel().then(level => ...)
    if (result && typeof (result as { then?: unknown }).then === 'function') {
      (result as Promise<unknown>).then(apply).catch(() => {
        /* ignore - keep ND default */
      });
    }
  } catch {
    // Method missing or an unexpected shape - keep ND default.
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
      NDLogger.w('NativeDisplayBridge', 'bind() received a non-object. Ignoring.');
      return;
    }

    const ct = cleverTap as Record<string, unknown>;

    const missing = ['addListener', 'pushDisplayUnitViewedEventForID', 'pushDisplayUnitClickedEventForID']
      .filter((key) => typeof ct[key] !== 'function');

    if (missing.length > 0) {
      NDLogger.w(
        'NativeDisplayBridge',
        `CleverTap instance is missing: ${missing.join(', ')}. ` +
        'Minimum supported version is @clevertap/clevertap-react-native >= 0.4.0.',
      );
    }

    this._cleverTap = ct;

    // Tag Core SDK events as "Native Display" for attribution.
    _tagNativeDisplayLibrary();

    // Follow the host's debug level unless the client set our own.
    _syncLogLevelFromCoreSdk(ct);

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
   * Set the log level for our internal logger. Once the client calls this,
   * the chosen level sticks and overrides the one copied from Core SDK.
   */
  setLogLevel(level: NDLogLevel): void {
    NDLogger.setLevel(level);
  }

  /**
   * Get the display units CleverTap already cached and hand them to
   * listeners. Call once at startup, right after bind().
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
      NDLogger.w('NativeDisplayBridge', 'fetchNativeDisplays: getAllDisplayUnits not available on CleverTap instance.');
    }
  }

  processDisplayUnit(jsonString: string): void {
    deferToIdleAsync(() => {
      const unit = this._parser.tryParse(jsonString);
      if (!unit) {
        NDLogger.w('NativeDisplayBridge', 'Failed to parse display unit. Check JSON format.');
        return;
      }
      this._cache.put(unit);
      NDLogger.d('NativeDisplayBridge', `Processed 1 display unit: ${unit.unitId}`);
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
        NDLogger.w('NativeDisplayBridge', 'No display units could be parsed from the provided JSON strings.');
        return;
      }
      for (const unit of units) this._cache.put(unit);
      NDLogger.d('NativeDisplayBridge', `Processed ${units.length} display unit(s).`);
      this._notifyListeners(units);
    });
  }

  addListener(listener: NativeDisplayBridgeListener): void {
    const isNew = !this._listeners.has(listener);
    this._listeners.add(listener);
    // Mirror the native bridges: a listener that registers after units are
    // cached gets them replayed at once, so it does not miss earlier units.
    if (isNew) {
      const cached = this._cache.getAll();
      if (cached.length > 0) {
        try {
          listener.onNativeDisplaysLoaded(cached);
        } catch (e) {
          NDLogger.e('NativeDisplayBridge', 'Listener threw during cache replay:', e);
        }
      }
    }
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
   * Forget that a unit (or all units, if omitted) already fired
   * `Notification Viewed`, so the next mount fires it again. Handy from a
   * login/logout handler so post-login impressions get counted.
   */
  resetViewedTracker(unitId?: string): void {
    if (unitId) {
      _viewedUnits.delete(unitId);
    } else {
      _viewedUnits.clear();
    }
  }

  /**
   * Drop a unit from the viewed tracker when its view is destroyed, so a
   * later remount fires `Notification Viewed` again (e.g. scrolling it back
   * into view). Called from NativeDisplayView cleanup. This is the SDK's own
   * bookkeeping, unlike resetViewedTracker which the host calls.
   */
  releaseViewedUnit(unitId: string): void {
    if (unitId) _viewedUnits.delete(unitId);
  }

  /**
   * Push a "Notification Viewed" event to CleverTap. Sanitizes extras and
   * stamps our SDK version, then uses the newer extras-aware Core SDK method
   * if the installed version has it, else the older 1-arg one.
   *
   * `extras` is empty at call sites today, but the param stays so we can
   * carry more data later without changing the signature.
   */
  pushViewedEvent(unitId: string, extras?: Record<string, unknown>): void {
    const ct = this._cleverTap;
    if (!ct) return;

    // Skip if already viewed. Units with no id (preview / raw JSON) always
    // fire. Call resetViewedTracker() to make a unit fire again.
    if (unitId) {
      if (_viewedUnits.has(unitId)) {
        return;
      }
      _viewedUnits.add(unitId);
    }

    const props = sanitizeExtras(extras);

    if (typeof ct['pushDisplayUnitViewedEventForIDWithProperties'] === 'function') {
      NDLogger.d('NativeDisplayBridge', `Pushing viewed event (with extras) for unit: ${unitId}`);
      (ct['pushDisplayUnitViewedEventForIDWithProperties'] as (id: string, p: Record<string, unknown>) => void)(
        unitId,
        props,
      );
      return;
    }

    if (typeof ct['pushDisplayUnitViewedEventForID'] === 'function') {
      NDLogger.d('NativeDisplayBridge', `Pushing viewed event for unit: ${unitId}`);
      (ct['pushDisplayUnitViewedEventForID'] as (id: string) => void)(unitId);
    } else {
      NDLogger.w('NativeDisplayBridge', `pushDisplayUnitViewedEventForID not available. Viewed event for ${unitId} not sent.`);
    }
  }

  /**
   * Push a "Notification Clicked" event to CleverTap with optional extras.
   * sanitizeExtras drops values that can't be sent and stamps our SDK
   * version, so each click can be traced to an SDK build.
   *
   * Uses the element-aware Core SDK method if available, else the older
   * 1-arg one with a warning - the click still records, just no extras.
   */
  pushClickedEvent(unitId: string, extras?: Record<string, unknown>): void {
    const ct = this._cleverTap;
    if (!ct) return;
    const props = sanitizeExtras(extras);

    if (typeof ct['pushDisplayUnitElementClickedEventForID'] === 'function') {
      NDLogger.d('NativeDisplayBridge', `Pushing element-clicked event for unit: ${unitId}`);
      (ct['pushDisplayUnitElementClickedEventForID'] as (id: string, p: Record<string, unknown>) => void)(
        unitId,
        props,
      );
      return;
    }

    if (typeof ct['pushDisplayUnitClickedEventForID'] === 'function') {
      NDLogger.d('NativeDisplayBridge', `Pushing clicked event for unit: ${unitId}`);
      (ct['pushDisplayUnitClickedEventForID'] as (id: string) => void)(unitId);
      NDLogger.w(
        'NativeDisplayBridge',
        'pushDisplayUnitElementClickedEventForID not available; ' +
        'element attribution + SDK version stamp were not forwarded to Core SDK. ' +
        'Update `@clevertap/clevertap-react-native` to receive attribution data.',
      );
    } else {
      NDLogger.w('NativeDisplayBridge', `pushDisplayUnitClickedEventForID not available. Clicked event for ${unitId} not sent.`);
    }
  }

  private _notifyListeners(units: NativeDisplayUnit[]): void {
    for (const listener of this._listeners) {
      try {
        listener.onNativeDisplaysLoaded(units);
      } catch (e) {
        NDLogger.e('NativeDisplayBridge', 'Listener threw an exception:', e);
      }
    }
  }

  private _resolveDisplayUnitsLoadedEvent(ct: Record<string, unknown>): string | null {
    // Prefer the constant the CT instance exposes, else the known name.
    if (typeof ct['CleverTapDisplayUnitsLoaded'] === 'string') {
      return ct['CleverTapDisplayUnitsLoaded'];
    }
    return 'CleverTapDisplayUnitsLoaded';
  }

  private _handleCleverTapDisplayUnitsEvent(event: unknown): void {
    if (!event || typeof event !== 'object') return;
    const e = event as Record<string, unknown>;
    // CT sends this as { displayUnits: [...] } or as a plain array.
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
