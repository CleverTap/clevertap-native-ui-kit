import { Linking } from 'react-native';
import type { Action, CompositeAction } from '../models/Action';

// Matches the URL scheme check in Android ActionHandler.kt and iOS ActionHandler.swift.
// Only http, https, tel, and mailto are safe to open. Everything else (including
// schemeless URLs like "www.google.com" or strings like "[text](url)") is dropped with a warning.
function isValidUrlScheme(url: string): boolean {
  const scheme = url.split(':')[0]?.toLowerCase();
  return ['http', 'https', 'tel', 'mailto'].includes(scheme ?? '');
}
import { resolveOpenUrl } from '../models/Action';
import type { NativeDisplayActionListener } from '../listener/NativeDisplayActionListener';
import type { NativeDisplayComponentListener, InteractionType } from '../listener/NativeDisplayComponentListener';

export class ActionHandler {
  constructor(
    private readonly actionListener: NativeDisplayActionListener | null,
    private readonly componentListener: NativeDisplayComponentListener | null,
    private readonly bridge: { pushClickedEvent(unitId: string): void } | null,
    private readonly unitId: string,
  ) {}

  /**
   * Fire the unit-clicked event without dispatching any action.
   * Call this on every button press so analytics always records the click.
   * Matches Android behavior, which fires "Notification Clicked" on every press.
   */
  fireClickedEvent(nodeId: string): void {
    this.bridge?.pushClickedEvent(this.unitId);
    this.actionListener?.onDisplayUnitClicked?.(this.unitId);
    this.actionListener?.onTrackEvent('Notification Clicked', { nodeId });
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
        this.actionListener?.onTrackEvent(action.eventName, action.properties);
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
