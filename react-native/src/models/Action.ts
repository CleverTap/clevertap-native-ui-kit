import { ExecutionMode } from './enums';

/**
 * A per-platform URL. It can be a plain string, or an object with `text`
 * (the older shape). Either works - `resolveOpenUrl` turns it into a string.
 * `replacements` is not used yet.
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
  /** Extra tracking fields from the server, added to the click event. */
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
 * Get the right URL for this platform. Tries rn, then android, then ios.
 * Each entry can be a string or a `{ text }` object.
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
