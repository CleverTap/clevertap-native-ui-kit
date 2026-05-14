import { NativeDisplayUnit } from './NativeDisplayUnit';
import { NativeDisplayConfigParser } from './NativeDisplayConfigParser';
import { NativeDisplayUnitCache } from './NativeDisplayUnitCache';
import { deferToIdleAsync } from '../utils/threading';

export interface NativeDisplayBridgeListener {
  onNativeDisplaysLoaded(units: NativeDisplayUnit[]): void;
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

    // Pull any units already sitting in the CT cache
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

  pushViewedEvent(unitId: string): void {
    const ct = this._cleverTap;
    if (!ct) return;
    if (typeof ct['pushDisplayUnitViewedEventForID'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing viewed event for unit: ${unitId}`);
      (ct['pushDisplayUnitViewedEventForID'] as (id: string) => void)(unitId);
    } else {
      console.warn(`[NativeDisplayBridge] pushDisplayUnitViewedEventForID not available. Viewed event for ${unitId} not sent.`);
    }
  }

  pushClickedEvent(unitId: string): void {
    const ct = this._cleverTap;
    if (!ct) return;
    if (typeof ct['pushDisplayUnitClickedEventForID'] === 'function') {
      console.log(`[NativeDisplayBridge] Pushing clicked event for unit: ${unitId}`);
      (ct['pushDisplayUnitClickedEventForID'] as (id: string) => void)(unitId);
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
