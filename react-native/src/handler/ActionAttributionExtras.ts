import type { Action } from '../models/Action';
import { resolveOpenUrl } from '../models/Action';
import {
  CODE as ND_LIB_VERSION_CODE,
  KEY_ND_LIB_VERSION_CODE,
  KEY_ND_LIB_VERSION_NAME,
  NAME as ND_LIB_VERSION_NAME,
} from '../NativeDisplaySdkVersion';

/**
 * Pure helper that turns an `Action` into a flat `Record<string, unknown>`
 * payload the bridge can forward to the Core SDK's element-click attribution
 * endpoint as `additionalProperties`.
 *
 * Mirrors `ios/Sources/CleverTapNativeDisplay/Handlers/ActionAttributionExtras.swift`
 * and the equivalent Android Kotlin helper so the keys arriving on the
 * CleverTap dashboard are identical across all three platforms.
 *
 * Output keys:
 *
 *   - `action_type`        - one of `open_url`, `custom`, `navigate`, `event`,
 *                            `composite`.
 *   - `action_key`         - the `CustomAction.key` discriminator (the BE
 *                            uses this for `"kv"` bundles, `"close"` actions,
 *                            etc.).
 *   - `action_url`         - resolved platform-specific URL for `open_url`.
 *   - `action_open_in_browser` - copied verbatim.
 *   - `action_destination` - for `navigate`.
 *   - `action_event_name`  - for `event`.
 *   - `action_value`       - scalar fallback for non-dict `CustomAction.value`.
 *   - `action_count`       - sub-action count for `composite`.
 *   - `action_mode`        - execution mode for `composite`.
 *   - Entries from `metadata` / `params` / `properties` / dict `value` are
 *     **spread verbatim** so the dashboard can slice by the client's own
 *     keys (especially `wzrk_*` fields the BE injects into `metadata`).
 *
 * Key collisions resolve last-write-wins under this order:
 *   reserved keys → spread entries (value/metadata/params/properties).
 */
export function attributionExtrasFor(action: Action | undefined): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (!action) return out;
  append(action, out);
  return out;
}

function append(action: Action, out: Record<string, unknown>): void {
  switch (action.type) {
    case 'open_url': {
      out['action_type'] = 'open_url';
      out['action_url'] = resolveOpenUrl(action);
      if (action.openInBrowser != null) out['action_open_in_browser'] = action.openInBrowser;
      spreadInto(out, action.metadata);
      break;
    }
    case 'custom': {
      out['action_type'] = 'custom';
      out['action_key'] = action.key;
      const value = action.value;
      if (isPlainObject(value)) {
        // Spread the bundle entries so the dashboard can slice per KV name
        // (mirrors the BE's `{ "type": "custom", "key": "kv", "value": {...} }` shape).
        for (const [k, v] of Object.entries(value)) {
          const scalar = coerceScalar(v);
          if (scalar !== undefined) out[k] = scalar;
        }
      } else {
        const scalar = coerceScalar(value);
        if (scalar !== undefined) out['action_value'] = scalar;
      }
      spreadInto(out, action.metadata);
      break;
    }
    case 'navigate': {
      out['action_type'] = 'navigate';
      out['action_destination'] = action.destination;
      spreadInto(out, action.params);
      break;
    }
    case 'event': {
      out['action_type'] = 'event';
      out['action_event_name'] = action.eventName;
      if (action.properties) {
        for (const [k, v] of Object.entries(action.properties)) {
          const scalar = coerceScalar(v);
          if (scalar !== undefined) out[k] = scalar;
        }
      }
      break;
    }
    case 'composite': {
      out['action_type'] = 'composite';
      out['action_count'] = action.actions.length;
      out['action_mode'] = action.executionMode;
      break;
    }
  }
}

/**
 * Reduce an arbitrary `unknown` to an analytics-friendly scalar.
 *
 * Strings/numbers/booleans round-trip as their native type so the CleverTap
 * dashboard renders them appropriately. Objects/arrays are JSON-stringified
 * so the payload stays serializable across the bridge. `null`/`undefined`
 * return `undefined` so the caller can skip emitting the key.
 */
function coerceScalar(v: unknown): unknown | undefined {
  if (v == null) return undefined;
  if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') return v;
  try {
    return JSON.stringify(v);
  } catch {
    return String(v);
  }
}

function isPlainObject(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === 'object' && !Array.isArray(v);
}

function spreadInto(out: Record<string, unknown>, source: Record<string, unknown> | undefined): void {
  if (!source) return;
  for (const [k, v] of Object.entries(source)) {
    if (v == null) continue;
    out[k] = v;
  }
}

/**
 * Drop entries whose values can't be transported across the JS/native
 * bridge cleanly, then unconditionally stamp the ND SDK version onto the
 * payload. Callers should pipe their raw extras through this helper before
 * handing them to the Core SDK so every event the dashboard sees can be
 * attributed to a specific SDK build.
 *
 * Always returns a non-empty object - even an `undefined` / empty input
 * produces `{ nd_lib_v_name, nd_lib_v_code }`. Caller-supplied keys win on
 * collision (we set the version keys last only if absent).
 */
export function sanitizeExtras(extras: Record<string, unknown> | undefined): Record<string, unknown> {
  const out: Record<string, unknown> = {};
  if (extras) {
    for (const [k, v] of Object.entries(extras)) {
      if (!k || v == null) continue;
      if (typeof v === 'string' || typeof v === 'number' || typeof v === 'boolean') {
        out[k] = v;
      } else if (Array.isArray(v) || isPlainObject(v)) {
        out[k] = v;
      } else {
        out[k] = String(v);
      }
    }
  }
  if (!(KEY_ND_LIB_VERSION_NAME in out)) out[KEY_ND_LIB_VERSION_NAME] = ND_LIB_VERSION_NAME;
  if (!(KEY_ND_LIB_VERSION_CODE in out)) out[KEY_ND_LIB_VERSION_CODE] = ND_LIB_VERSION_CODE;
  return out;
}
