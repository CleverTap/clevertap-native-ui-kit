import { Linking } from 'react-native';
import type { Action, CompositeAction } from '../models/Action';
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
   * Fire the unit-clicked system event without dispatching any action.
   * Call this on every button press so analytics always track the click,
   * matching Android which fires "Notification Clicked" unconditionally.
   */
  fireClickedEvent(_nodeId: string): void {
    this.bridge?.pushClickedEvent(this.unitId);
    this.actionListener?.onDisplayUnitClicked?.(this.unitId);
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

    // Note: pushClickedEvent is intentionally NOT called here.
    // ButtonElement calls fireClickedEvent() on every press before handle(),
    // ensuring the system event fires exactly once even when no action is defined.

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
