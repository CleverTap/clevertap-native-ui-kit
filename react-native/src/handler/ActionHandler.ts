import { Linking } from 'react-native';
import type { Action, CompositeAction } from '../models/Action';

// Matches Android ActionHandler.kt / iOS ActionHandler.swift after SDK-5859:
// the native SDKs no longer restrict open_url to an http/https/tel/mailto
// allow-list - they open ANY URL that carries a scheme, so custom deeplinks
// (myapp://, whatsapp://, intent://, ...) work. We keep only a minimal guard:
// the string must start with a valid RFC-3986 scheme followed by ':'. That
// still drops schemeless strings like "www.google.com" and markdown like
// "[text](url)", which can't be opened anyway.
function isValidUrlScheme(url: string): boolean {
  return /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(url.trim());
}
import { resolveOpenUrl } from '../models/Action';
import { attributionExtrasFor } from './ActionAttributionExtras';
import type { NativeDisplayActionListener } from '../listener/NativeDisplayActionListener';
import type { NativeDisplayComponentListener, InteractionType } from '../listener/NativeDisplayComponentListener';

export class ActionHandler {
  constructor(
    private readonly actionListener: NativeDisplayActionListener | null,
    private readonly componentListener: NativeDisplayComponentListener | null,
    private readonly bridge: {
      pushClickedEvent(unitId: string, extras?: Record<string, unknown>): void;
    } | null,
    private readonly unitId: string,
  ) {}

  /**
   * Fire the unit-clicked event without dispatching any action.
   *
   * Called on every button press so analytics always records the click,
   * even when no action is configured. When the press carries a concrete
   * action (i.e. the node has `actions.onClick` set), pass it in so we can
   * build the element-attribution extras that the CleverTap dashboard uses
   * to slice clicks by element / c2a / btn_text / wzrk_* fields - matches
   * Android + iOS PR #12 behavior. Passing `action` is optional: the helper
   * returns an empty extras object when omitted, so older call-sites keep
   * working with the single-arg signature.
   */
  fireClickedEvent(nodeId: string, action?: Action): void {
    const extras: Record<string, unknown> = {
      node_id: nodeId,
      ...attributionExtrasFor(action),
    };
    this.bridge?.pushClickedEvent(this.unitId, extras);
    this.actionListener?.onDisplayUnitClicked?.(this.unitId);
    this.actionListener?.onTrackEvent('Notification Clicked', extras);
  }

  /**
   * Fire a lifecycle action (onAppear / onDisappear).
   * Skips the componentListener because lifecycle events are not user interactions.
   * Matches Android's LaunchedEffect / DisposableEffect pattern.
   */
  handleLifecycle(action: Action, nodeId: string, trigger: 'appear' | 'disappear'): void {
    console.log(`[ActionHandler] Lifecycle trigger=${trigger} nodeId=${nodeId}`);
    this._dispatch(action, nodeId, 'click');
  }

  handle(action: Action, nodeId: string, interactionType: InteractionType): void {
    console.log(`[ActionHandler] Handling action type=${action.type} nodeId=${nodeId} interaction=${interactionType}`);

    if (this.componentListener) {
      const interested = this.componentListener.getInterestedNodeIds();
      if (interested === null || interested.has(nodeId)) {
        const handled = this.componentListener.onComponentInteraction(nodeId, interactionType, true);
        if (handled) {
          console.log(`[ActionHandler] Action consumed by component listener for nodeId=${nodeId}`);
          return;
        }
      }
    }

    // pushClickedEvent is intentionally not called here.
    // ButtonElement calls fireClickedEvent() on every press before handle(),
    // so the system event fires exactly once even when no action is defined.

    this._dispatch(action, nodeId, interactionType);
  }

  private _dispatch(action: Action, nodeId: string, interactionType: InteractionType): void {
    switch (action.type) {
      case 'open_url': {
        const url = resolveOpenUrl(action);
        if (!url) {
          console.warn(`[ActionHandler] open_url action has no resolvable URL for nodeId=${nodeId}`);
          return;
        }
        if (!isValidUrlScheme(url)) {
          console.warn(`[ActionHandler] Invalid or missing URL scheme, dropping open_url for nodeId=${nodeId}: ${url}`);
          return;
        }
        const openInBrowser = action.openInBrowser ?? false;
        console.log(`[ActionHandler] Opening URL: ${url} openInBrowser=${openInBrowser}`);
        if (this.actionListener) {
          const handled = this.actionListener.onOpenUrl(url, openInBrowser);
          if (handled) return;
        }
        Linking.openURL(url).catch((e) => {
          console.warn(`[ActionHandler] Failed to open URL: ${url}`, e);
        });
        break;
      }
      case 'custom': {
        console.log(`[ActionHandler] Dispatching custom action key=${action.key}`);
        this.actionListener?.onCustomAction(action.key, action.value, action.metadata);
        break;
      }
      case 'navigate': {
        console.log(`[ActionHandler] Dispatching navigate action destination=${action.destination}`);
        this.actionListener?.onNavigate(action.destination, action.params);
        break;
      }
      case 'event': {
        console.log(`[ActionHandler] Dispatching track event: ${action.eventName}`);
        // Drop properties whose values are null/undefined. Matches iOS
        // `compactMapValues` - some host bridges choke on `undefined`
        // entries when serializing the props dict.
        const props = filterNullishValues(action.properties);
        this.actionListener?.onTrackEvent(action.eventName, props);
        break;
      }
      case 'composite': {
        const composite = action as CompositeAction;
        console.log(`[ActionHandler] Dispatching composite action with ${composite.actions.length} sub-action(s)`);
        for (const sub of composite.actions) {
          this._dispatch(sub, nodeId, interactionType);
        }
        break;
      }
      default:
        console.warn(`[ActionHandler] Unknown action type: ${(action as Action).type}`);
        break;
    }
  }
}

/**
 * Drop entries whose values are `null` or `undefined` from a properties dict.
 * Matches iOS `compactMapValues`. Returns `undefined` for an empty input or
 * if every value was nullish so callers can pass it straight through to a
 * listener that expects `Record<string, unknown> | undefined`.
 */
function filterNullishValues(
  props: Record<string, unknown> | undefined,
): Record<string, unknown> | undefined {
  if (!props) return undefined;
  const out: Record<string, unknown> = {};
  for (const [k, v] of Object.entries(props)) {
    if (v != null) out[k] = v;
  }
  return Object.keys(out).length > 0 ? out : undefined;
}
