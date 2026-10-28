import { Linking } from 'react-native';
import type { Action, CompositeAction } from '../models/Action';

// Allow any URL that has a scheme (myapp://, whatsapp://, tel:, https:, ...),
// matching native SDKs. We only require a valid scheme followed by ':', which
// drops things we can't open anyway like "www.google.com" or "[text](url)".
function isValidUrlScheme(url: string): boolean {
  return /^[a-zA-Z][a-zA-Z0-9+.-]*:/.test(url.trim());
}
import { resolveOpenUrl } from '../models/Action';
import { attributionExtrasFor } from './ActionAttributionExtras';
import { NDLogger } from '../internal/NDLogger';
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
   * Record a click event without running any action.
   *
   * Called on every button press so analytics always logs the click, even
   * when no action is set. Pass the action (if any) to add attribution extras
   * the dashboard uses to slice clicks by element / c2a / btn_text / wzrk_*.
   * `action` is optional - omitting it just gives empty extras.
   */
  fireClickedEvent(nodeId: string, action?: Action): void {
    // Attribution extras come from the action only, matching Android and iOS.
    // node_id is not an attribution field there. We keep nodeId for a local
    // debug log so the click is still traceable in logs.
    NDLogger.d('ActionHandler', `Click fired for nodeId=${nodeId}`);
    const extras: Record<string, unknown> = {
      ...attributionExtrasFor(action),
    };
    this.bridge?.pushClickedEvent(this.unitId, extras);
    this.actionListener?.onDisplayUnitClicked?.(this.unitId);
    this.actionListener?.onTrackEvent('Notification Clicked', extras);
  }

  /**
   * Run an onAppear / onDisappear action. Skips the componentListener since
   * these aren't user interactions.
   */
  handleLifecycle(action: Action, nodeId: string, trigger: 'appear' | 'disappear'): void {
    NDLogger.d('ActionHandler', `Lifecycle trigger=${trigger} nodeId=${nodeId}`);
    this._dispatch(action, nodeId, 'click');
  }

  handle(action: Action, nodeId: string, interactionType: InteractionType): void {
    NDLogger.d('ActionHandler', `Handling action type=${action.type} nodeId=${nodeId} interaction=${interactionType}`);

    if (this.componentListener) {
      const interested = this.componentListener.getInterestedNodeIds();
      if (interested === null || interested.has(nodeId)) {
        const handled = this.componentListener.onComponentInteraction(nodeId, interactionType, true);
        if (handled) {
          NDLogger.d('ActionHandler', `Action consumed by component listener for nodeId=${nodeId}`);
          return;
        }
      }
    }

    // We don't push the click event here. ButtonElement already calls
    // fireClickedEvent() before handle(), so it fires exactly once.

    this._dispatch(action, nodeId, interactionType);
  }

  private _dispatch(action: Action, nodeId: string, interactionType: InteractionType): void {
    switch (action.type) {
      case 'open_url': {
        const url = resolveOpenUrl(action);
        if (!url) {
          NDLogger.w('ActionHandler', `open_url action has no resolvable URL for nodeId=${nodeId}`);
          return;
        }
        if (!isValidUrlScheme(url)) {
          NDLogger.w('ActionHandler', `Invalid or missing URL scheme, dropping open_url for nodeId=${nodeId}: ${url}`);
          return;
        }
        const openInBrowser = action.openInBrowser ?? false;
        NDLogger.d('ActionHandler', `Opening URL: ${url} openInBrowser=${openInBrowser}`);
        if (this.actionListener) {
          const handled = this.actionListener.onOpenUrl(url, openInBrowser);
          if (handled) return;
        }
        Linking.openURL(url).catch((e) => {
          NDLogger.w('ActionHandler', `Failed to open URL: ${url}`, e);
        });
        break;
      }
      case 'custom': {
        NDLogger.d('ActionHandler', `Dispatching custom action key=${action.key}`);
        this.actionListener?.onCustomAction(action.key, action.value, action.metadata);
        break;
      }
      case 'navigate': {
        NDLogger.d('ActionHandler', `Dispatching navigate action destination=${action.destination}`);
        this.actionListener?.onNavigate(action.destination, action.params);
        break;
      }
      case 'event': {
        NDLogger.d('ActionHandler', `Dispatching track event: ${action.eventName}`);
        // Drop null/undefined props - some bridges fail to serialize them.
        const props = filterNullishValues(action.properties);
        this.actionListener?.onTrackEvent(action.eventName, props);
        break;
      }
      case 'composite': {
        const composite = action as CompositeAction;
        NDLogger.d('ActionHandler', `Dispatching composite action with ${composite.actions.length} sub-action(s)`);
        for (const sub of composite.actions) {
          this._dispatch(sub, nodeId, interactionType);
        }
        break;
      }
      default:
        NDLogger.w('ActionHandler', `Unknown action type: ${(action as Action).type}`);
        break;
    }
  }
}

/**
 * Remove null/undefined values from a props dict. Returns undefined if the
 * result is empty, so it can pass straight to a listener expecting
 * `Record<string, unknown> | undefined`.
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
