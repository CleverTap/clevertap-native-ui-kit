/**
 * Host-facing callbacks fired by the Native Display SDK as a unit goes
 * through its lifecycle and as the user interacts with its elements.
 *
 * All methods are optional except those marked required at the type level.
 * Implement only the ones you care about and ignore the rest.
 */
export interface NativeDisplayActionListener {
  /**
   * Called when an `open_url` action fires. Return `true` if the host took
   * over the navigation; `false` to fall through to the SDK's default
   * `Linking.openURL`.
   */
  onOpenUrl(url: string, openInBrowser: boolean): boolean;

  /**
   * Called when a `custom` action fires. The SDK never opens custom actions
   * itself - it just hands you the key/value pair so you can route it.
   */
  onCustomAction(key: string, value: unknown, metadata?: Record<string, string>): void;

  /**
   * Called when a `navigate` action fires. Wire this to your navigation
   * library (React Navigation, etc.).
   */
  onNavigate(destination: string, params?: Record<string, string>): void;

  /**
   * Called for `event` actions, and also for the SDK's own analytics:
   * `Notification Viewed` (carrying the unit id) and `Notification
   * Clicked` (carrying `node_id` plus attribution extras such as
   * `action_type`, `action_url`, `wzrk_*`). Treat this as a passive
   * notification - the SDK already pushed the matching event to CleverTap.
   */
  onTrackEvent(eventName: string, properties?: Record<string, unknown>): void;

  /**
   * Called once when a unit first becomes visible.
   *
   * **Do NOT call `pushDisplayUnitViewedEventForID` manually here** - the
   * SDK already fires the "Notification Viewed" event to the Core SDK
   * automatically. This callback is purely a notification for the host
   * (e.g. for in-app logging or extra analytics).
   */
  onDisplayUnitViewed?(unitId: string): void;

  /**
   * Called when any element inside a unit is clicked.
   *
   * **Do NOT call `pushDisplayUnitClickedEventForID` manually here** - the
   * SDK already fires "Notification Clicked" to the Core SDK automatically
   * (with element-attribution extras after PR #12). This callback is purely
   * a notification for the host.
   */
  onDisplayUnitClicked?(unitId: string): void;
}
