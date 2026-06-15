import { NativeDisplayConfig } from '../models/NativeDisplayConfig';
import { NativeDisplayNode } from '../models/NativeDisplayNode';
import { parseDimension } from '../models/Layout';
import { parseTextDimension } from '../models/Style';
import type { Action } from '../models/Action';

type Raw = Record<string, unknown>;

/**
 * Coerce every value in an arbitrary record into a string.
 *
 * Mirrors Android's `FlexibleStringMapSerializer` and iOS's `AnyStringValue`
 * decoding: the backend sometimes ships `bindings`/`metadata` values as JSON
 * primitives (boolean / number) or even nested objects/arrays. Without
 * coercion they survive into the renderer as non-strings and break callers
 * that expect a `Record<string, string>` (notably `evaluateBoolean`).
 *
 * - `null` / `undefined` values are skipped entirely (no key emitted).
 * - Primitive scalars (string / number / boolean) are stringified with
 *   `String(value)`.
 * - Arrays and objects are `JSON.stringify`'d so the payload stays
 *   analytics-friendly.
 */
/**
 * Parse a per-trigger action map (`onClick`, `onAppear`, ...) from the
 * raw JSON object. Each value is dispatched to `parseAction` so nested
 * `metadata` and other typed fields get the right coercion.
 *
 * Returns `undefined` if the input isn't a usable object, so callers can
 * keep the `actions` field optional.
 */
function parseActions(raw: unknown): Record<string, Action> | undefined {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const out: Record<string, Action> = {};
  for (const [trigger, value] of Object.entries(raw as Record<string, unknown>)) {
    const action = parseAction(value);
    if (action) out[trigger] = action;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}

/**
 * Parse a single Action object. Dispatches on `type`. Carefully extracts
 * `metadata` for `open_url` and `custom` (server-injected `wzrk_*`
 * attribution fields land here), coercing any non-string values into
 * strings so downstream consumers always see a `Record<string, string>`.
 *
 * Unknown action types return `undefined` so the caller can drop them.
 */
function parseAction(raw: unknown): Action | undefined {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return undefined;
  const r = raw as Raw;
  const type = r['type'];

  switch (type) {
    case 'open_url': {
      const metadata = coerceStringMap(r['metadata']);
      const action: import('../models/Action').OpenUrlAction = {
        type: 'open_url',
        url: r['url'] as import('../models/Action').OpenUrlAction['url'],
        openInBrowser: r['openInBrowser'] as boolean | undefined,
        customTabsEnabled: r['customTabsEnabled'] as boolean | undefined,
      };
      if (Object.keys(metadata).length > 0) action.metadata = metadata;
      return action;
    }
    case 'custom': {
      const metadata = coerceStringMap(r['metadata']);
      const action: import('../models/Action').CustomAction = {
        type: 'custom',
        key: (r['key'] as string) ?? '',
        value: r['value'],
      };
      if (Object.keys(metadata).length > 0) action.metadata = metadata;
      return action;
    }
    case 'navigate':
      return {
        type: 'navigate',
        destination: (r['destination'] as string) ?? '',
        params: coerceStringMap(r['params']),
      };
    case 'event':
      return {
        type: 'event',
        eventName: (r['eventName'] as string) ?? '',
        properties: (r['properties'] as Record<string, unknown> | undefined) ?? undefined,
      };
    case 'composite': {
      const actionsRaw = r['actions'];
      const subActions: Action[] = Array.isArray(actionsRaw)
        ? (actionsRaw as unknown[])
            .map(parseAction)
            .filter((a): a is Action => !!a)
        : [];
      return {
        type: 'composite',
        actions: subActions,
        executionMode: (r['executionMode'] as import('../models/enums').ExecutionMode) ?? 'sequential',
      };
    }
    default:
      return undefined;
  }
}

function coerceStringMap(raw: unknown): Record<string, string> {
  if (!raw || typeof raw !== 'object' || Array.isArray(raw)) return {};
  const out: Record<string, string> = {};
  for (const [key, value] of Object.entries(raw as Record<string, unknown>)) {
    if (value == null) continue;
    if (typeof value === 'string') {
      out[key] = value;
    } else if (typeof value === 'number' || typeof value === 'boolean') {
      out[key] = String(value);
    } else {
      try {
        out[key] = JSON.stringify(value);
      } catch {
        out[key] = String(value);
      }
    }
  }
  return out;
}

export function parseNativeDisplayConfig(raw: Raw): NativeDisplayConfig {
  return {
    version: (raw['version'] as string) ?? '1.0',
    theme: raw['theme'] ? parseTheme(raw['theme'] as Raw) : undefined,
    styleClasses: Array.isArray(raw['styleClasses'])
      ? (raw['styleClasses'] as Raw[]).map(parseStyleClass)
      : [],
    variables: (raw['variables'] as Record<string, unknown>) ?? {},
    root: raw['root'] ? parseNode(raw['root'] as Raw) : undefined,
  };
}

function parseTheme(raw: Raw) {
  return {
    id: (raw['id'] as string) ?? 'default',
    defaultStyle: raw['defaultStyle'] ? parseStyle(raw['defaultStyle'] as Raw) : {},
    colors: (raw['colors'] as Record<string, string>) ?? {},
  };
}

function parseStyleClass(raw: Raw) {
  return {
    name: (raw['name'] as string) ?? '',
    style: raw['style'] ? parseStyle(raw['style'] as Raw) : {},
  };
}

function parseNode(raw: Raw): NativeDisplayNode {
  const type = raw['type'] as string;

  if (type === 'container') {
    return {
      type: 'container',
      id: (raw['id'] as string) ?? '',
      containerType: (raw['containerType'] as string)?.toLowerCase() as import('../models/enums').ContainerType ?? 'vertical',
      children: Array.isArray(raw['children'])
        ? (raw['children'] as Raw[]).map(parseNode)
        : [],
      layout: raw['layout'] ? parseLayout(raw['layout'] as Raw) : undefined,
      style: raw['style'] ? parseStyle(raw['style'] as Raw) : undefined,
      styleClass: raw['styleClass'] as string | undefined,
      visible: raw['visible'] as string | undefined,
      actions: parseActions(raw['actions']),
      animation: raw['animation'] ? raw['animation'] as import('../models/Animation').Animation : undefined,
      galleryConfig: raw['galleryConfig'] ? raw['galleryConfig'] as import('../models/GalleryConfig').GalleryConfig : undefined,
      dividerConfig: raw['dividerConfig'] ? raw['dividerConfig'] as import('../models/NativeDisplayNode').DividerConfig : undefined,
    };
  }

  // element (default)
  return {
    type: 'element',
    id: (raw['id'] as string) ?? '',
    elementType: (raw['elementType'] as string)?.toLowerCase() as import('../models/enums').ElementType ?? 'text',
    bindings: coerceStringMap(raw['bindings']),
    layout: raw['layout'] ? parseLayout(raw['layout'] as Raw) : undefined,
    style: raw['style'] ? parseStyle(raw['style'] as Raw) : undefined,
    styleClass: raw['styleClass'] as string | undefined,
    visible: raw['visible'] as string | undefined,
    actions: raw['actions'] ? raw['actions'] as Record<string, import('../models/Action').Action> : undefined,
    animation: raw['animation'] ? raw['animation'] as import('../models/Animation').Animation : undefined,
    dividerConfig: raw['dividerConfig'] ? raw['dividerConfig'] as import('../models/NativeDisplayNode').DividerConfig : undefined,
    imageConfig: raw['imageConfig'] ? raw['imageConfig'] as import('../models/NativeDisplayNode').ImageConfig : undefined,
    htmlConfig: raw['htmlConfig'] ? raw['htmlConfig'] as import('../models/NativeDisplayNode').HtmlConfig : undefined,
  };
}

function parseLayout(raw: Raw): import('../models/Layout').Layout {
  return {
    width: parseDimension(raw['width']),
    height: parseDimension(raw['height']),
    aspectRatio: raw['aspectRatio'] != null ? Number(raw['aspectRatio']) : undefined,
    offset: raw['offset'] ? raw['offset'] as import('../models/Layout').Offset : undefined,
    padding: raw['padding'] ? raw['padding'] as import('../models/Layout').Spacing : undefined,
    arrangement: raw['arrangement'] ? raw['arrangement'] as import('../models/Layout').ChildArrangement : undefined,
  };
}

function parseStyle(raw: Raw): import('../models/Style').Style {
  return {
    textColor: raw['textColor'] as string | undefined,
    fontSize: raw['fontSize'] != null ? parseTextDimension(raw['fontSize']) : undefined,
    fontFamily: raw['fontFamily'] as string | undefined,
    fontWeight: raw['fontWeight'] as import('../models/enums').FontWeight | undefined,
    fontStyle: raw['fontStyle'] as import('../models/enums').FontStyle | undefined,
    lineHeight: raw['lineHeight'] != null ? parseTextDimension(raw['lineHeight']) : undefined,
    letterSpacing: raw['letterSpacing'] != null ? Number(raw['letterSpacing']) : undefined,
    textDecoration: raw['textDecoration'] as import('../models/enums').TextDecoration | undefined,
    textAlign: raw['textAlign'] as string | undefined,
    maxLines: raw['maxLines'] != null ? Number(raw['maxLines']) : undefined,
    overflow: raw['overflow'] as import('../models/enums').TextOverflow | undefined,
    textShadow: raw['textShadow'] ? raw['textShadow'] as import('../models/Style').TextShadow : undefined,
    textGradient: raw['textGradient'] ? raw['textGradient'] as import('../models/Style').TextGradient : undefined,
    background: raw['background'] ? raw['background'] as import('../models/Background').Background : undefined,
    backgroundColor: raw['backgroundColor'] as string | undefined,
    borderRadius: raw['borderRadius'] != null ? parseDimension(raw['borderRadius']) : undefined,
    borderWidth: raw['borderWidth'] != null ? Number(raw['borderWidth']) : undefined,
    borderColor: raw['borderColor'] as string | undefined,
    shadowColor: raw['shadowColor'] as string | undefined,
    shadowRadius: raw['shadowRadius'] != null ? Number(raw['shadowRadius']) : undefined,
    shadowOffsetX: raw['shadowOffsetX'] != null ? Number(raw['shadowOffsetX']) : undefined,
    shadowOffsetY: raw['shadowOffsetY'] != null ? Number(raw['shadowOffsetY']) : undefined,
    opacity: raw['opacity'] != null ? Number(raw['opacity']) : undefined,
  };
}
