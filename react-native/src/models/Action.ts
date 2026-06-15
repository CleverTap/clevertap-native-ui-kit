import { ExecutionMode } from './enums';

/**
 * The shape of a per-platform URL entry. Production payloads ship two
 * variants:
 *
 *  1. A flat string: `{ "android": "https://...", "ios": "https://..." }`.
 *  2. A nested object carrying `text` (+ optional `replacements`), the legacy
 *     Ultron shape: `{ "android": { "text": "https://...", "replacements": {} } }`.
 *
 * Either is accepted; `resolveOpenUrl` flattens the nested shape down to a
 * string. `replacements` are not expanded yet on RN (Android/iOS also just
 * read `text` today).
 */
export type PlatformUrlValue =
  | string
  | { text?: string; replacements?: Record<string, string> };

export interface OpenUrlAction {
  type: 'open_url';
  url:
    | string
    | { android?: PlatformUrlValue; ios?: PlatformUrlValue; rn?: PlatformUrlValue };
  openInBrowser?: boolean;
  customTabsEnabled?: boolean;
  /**
   * Server-injected attribution fields (`wzrk_element_id`, `wzrk_c2a`, etc.).
   * Flattened into the click event's `additionalProperties` via
   * `ActionAttributionExtras`.
   */
  metadata?: Record<string, string>;
}

export interface CustomAction {
  type: 'custom';
  key: string;
  value?: unknown;
  metadata?: Record<string, string>;
}

export interface NavigateAction {
  type: 'navigate';
  destination: string;
  params?: Record<string, string>;
}

export interface TrackEventAction {
  type: 'event';
  eventName: string;
  properties?: Record<string, unknown>;
}

export interface CompositeAction {
  type: 'composite';
  actions: Action[];
  executionMode: ExecutionMode;
}

export type Action =
  | OpenUrlAction
  | CustomAction
  | NavigateAction
  | TrackEventAction
  | CompositeAction;

export type ActionTrigger =
  | 'onClick'
  | 'onLongPress'
  | 'onDoubleTap'
  | 'onAppear'
  | 'onDisappear';

/**
 * Pick the platform-correct URL from an `OpenUrlAction.url` field.
 *
 * Preference order is `rn` → `android` → `ios`. Each entry can be either a
 * plain string or the legacy nested `{ text, replacements }` shape; the
 * nested form is flattened to its `text` value.
 */
export function resolveOpenUrl(action: OpenUrlAction): string {
  if (typeof action.url === 'string') return action.url;
  return (
    flattenPlatformUrl(action.url.rn) ||
    flattenPlatformUrl(action.url.android) ||
    flattenPlatformUrl(action.url.ios) ||
    ''
  );
}

function flattenPlatformUrl(value: PlatformUrlValue | undefined): string {
  if (value == null) return '';
  if (typeof value === 'string') return value;
  return value.text ?? '';
}
