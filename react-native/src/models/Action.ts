import { ExecutionMode } from './enums';

export interface OpenUrlAction {
  type: 'open_url';
  url: string | { android?: string; ios?: string; rn?: string };
  openInBrowser?: boolean;
  customTabsEnabled?: boolean;
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

export function resolveOpenUrl(action: OpenUrlAction): string {
  if (typeof action.url === 'string') return action.url;
  return action.url.rn ?? action.url.android ?? action.url.ios ?? '';
}
