import { NativeDisplayConfig, ResolvedConfig, toResolvedConfig } from '../models/NativeDisplayConfig';
import { StyleResolver } from '../style/StyleResolver';
import { NativeDisplayUnit } from './NativeDisplayUnit';
import { parseNativeDisplayConfig } from './configDeserializer';

export class NativeDisplayConfigParser {
  tryParse(jsonString: string): NativeDisplayUnit | null {
    try {
      const jsonObj = JSON.parse(jsonString) as Record<string, unknown>;

      const unitId = this._extractUnitId(jsonObj);
      if (!unitId) {
        console.warn('[NativeDisplayConfigParser] Missing required field wzrk_id. Skipping unit.');
        return null;
      }

      const slotId = this._extractSlotId(jsonObj);
      const customExtras = this._extractCustomExtras(jsonObj);

      const resolvedConfig =
        this._tryParseNativeDisplayConfig(jsonObj) ??
        this._tryParseFromCustomKv(jsonObj) ??
        this._tryParseAsRootConfig(jsonObj);

      if (!resolvedConfig) {
        console.warn(`[NativeDisplayConfigParser] All parse strategies failed for unit ${unitId}. No valid config found.`);
        return null;
      }

      const resolvedStyles = this._preResolveStyles(resolvedConfig, unitId);

      return {
        unitId,
        config: resolvedConfig,
        resolvedStyles,
        slotId,
        customExtras,
        rawJson: jsonString,
      };
    } catch (e) {
      console.warn('[NativeDisplayConfigParser] Failed to parse JSON:', e);
      return null;
    }
  }

  // Strategy 1: top-level native_display_config key
  private _tryParseNativeDisplayConfig(
    jsonObj: Record<string, unknown>,
  ): ResolvedConfig | null {
    const ndConfigRaw = jsonObj['native_display_config'];
    if (ndConfigRaw == null) return null;
    try {
      const ndConfig = parseNativeDisplayConfig(ndConfigRaw as Record<string, unknown>);
      return toResolvedConfig(ndConfig);
    } catch (e) {
      console.warn('[NativeDisplayConfigParser] Strategy 1 (native_display_config) failed:', e);
      return null;
    }
  }

  // Strategy 2: custom_kv.nd_config JSON string
  private _tryParseFromCustomKv(
    jsonObj: Record<string, unknown>,
  ): ResolvedConfig | null {
    const customKv = jsonObj['custom_kv'];
    if (!customKv || typeof customKv !== 'object') return null;
    const ndConfigStr = (customKv as Record<string, unknown>)['nd_config'];
    if (typeof ndConfigStr !== 'string') return null;
    try {
      const parsed = JSON.parse(ndConfigStr) as Record<string, unknown>;
      const ndConfig = parseNativeDisplayConfig(parsed);
      return toResolvedConfig(ndConfig);
    } catch (e) {
      console.warn('[NativeDisplayConfigParser] Strategy 2 (custom_kv.nd_config) failed:', e);
      return null;
    }
  }

  // Strategy 3: treat entire object as NativeDisplayConfig if it has a root key
  private _tryParseAsRootConfig(
    jsonObj: Record<string, unknown>,
  ): ResolvedConfig | null {
    if (!('root' in jsonObj)) return null;
    try {
      const ndConfig = parseNativeDisplayConfig(jsonObj);
      return toResolvedConfig(ndConfig);
    } catch (e) {
      console.warn('[NativeDisplayConfigParser] Strategy 3 (bare root) failed:', e);
      return null;
    }
  }

  private _preResolveStyles(config: ResolvedConfig, unitId: string): Record<string, import('../models/Style').Style> {
    try {
      return new StyleResolver(config.theme, config.styleClasses).resolveAll(config.root);
    } catch (e) {
      console.warn(`[NativeDisplayConfigParser] Style pre-resolution failed for unit ${unitId}:`, e);
      return {};
    }
  }

  private _extractUnitId(jsonObj: Record<string, unknown>): string | null {
    const id = jsonObj['wzrk_id'];
    if (typeof id === 'string' && id.length > 0) return id;
    return null;
  }

  private _extractSlotId(jsonObj: Record<string, unknown>): string | undefined {
    const id = jsonObj['slot_id'];
    if (typeof id === 'string' && id.length > 0) return id;
    return undefined;
  }

  private _extractCustomExtras(jsonObj: Record<string, unknown>): Record<string, string> {
    const customKv = jsonObj['custom_kv'];
    if (!customKv || typeof customKv !== 'object') return {};
    const result: Record<string, string> = {};
    for (const [key, value] of Object.entries(customKv as Record<string, unknown>)) {
      if (key === 'nd_config') continue;
      result[key] = typeof value === 'string' ? value : JSON.stringify(value);
    }
    return result;
  }
}
