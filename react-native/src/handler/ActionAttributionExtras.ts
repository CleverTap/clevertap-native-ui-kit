import type { Action } from '../models/Action';
import { resolveOpenUrl } from '../models/Action';
import {
  CODE as ND_LIB_VERSION_CODE,
  KEY_ND_LIB_VERSION_CODE,
  KEY_ND_LIB_VERSION_NAME,
  NAME as ND_LIB_VERSION_NAME,
} from '../NativeDisplaySdkVersion';

/**
 * Turn an Action into a flat map the bridge forwards as click-attribution
 * extras. Keys match Android and iOS so the dashboard sees the same fields
 * everywhere.
 *
 * Reserved keys per action type:
 *   - action_type          - open_url, custom, navigate, event, or composite
 *   - action_key           - the CustomAction key (e.g. "kv", "close")
 *   - action_url           - resolved URL for open_url
 *   - action_open_in_browser
 *   - action_destination   - for navigate
 *   - action_event_name    - for event
 *   - action_value         - fallback when CustomAction value isn't an object
 *   - action_count         - sub-action count for composite
 *   - action_mode          - execution mode for composite
 *
 * metadata / params / properties / dict value are spread in as-is so the
 * dashboard can slice by the client's own keys (like wzrk_* fields).
 * On key collision the spread entries win (they're written last).
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
      // Always write this key, even when the server omits openInBrowser. Android
      // and iOS default it to false, so writing it keeps attribution identical.
      out['action_open_in_browser'] = action.openInBrowser ?? false;
      spreadInto(out, action.metadata);
      break;
    }
    case 'custom': {
      out['action_type'] = 'custom';
      out['action_key'] = action.key;
      const value = action.value;
      if (isPlainObject(value)) {
        // Spread each KV entry so the dashboard can slice by its name.
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
 * Reduce a value to an analytics-friendly scalar. Strings/numbers/booleans
 * pass through as-is; objects/arrays are JSON-stringified so they survive the
 * bridge; null/undefined return undefined so the caller can skip the key.
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
 * Clean extras for the bridge and stamp on the ND SDK version so every event
 * can be tied to a build. Run raw extras through this before sending them to
 * the Core SDK. Always returns at least { nd_lib_v_name, nd_lib_v_code };
 * caller keys win on collision (version keys are only added if missing).
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
