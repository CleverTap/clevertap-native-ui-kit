/**
 * Callbacks the SDK fires as a unit is shown and as the user interacts with it.
 * Implement only the ones you need.
 */
export interface NativeDisplayActionListener {
  /**
   * Fired on an `open_url` action. Return `true` if you handled the navigation
   * yourself, `false` to let the SDK open it with `Linking.openURL`.
   */
  onOpenUrl(url: string, openInBrowser: boolean): boolean;

  /**
   * Fired on a `custom` action. The SDK just hands you the key/value pair; you
   * decide what to do with it.
   */
  onCustomAction(key: string, value: unknown, metadata?: Record<string, string>): void;

  /**
   * Fired on a `navigate` action. Hook this up to your navigation library.
   */
  onNavigate(destination: string, params?: Record<string, string>): void;

  /**
   * Fired for `event` actions and for the SDK's own analytics events
   * (Notification Viewed / Clicked). The SDK already sent these to CleverTap,
   * so this is just a heads-up for you.
   */
  onTrackEvent(eventName: string, properties?: Record<string, unknown>): void;

  /**
   * Fired once when a unit first becomes visible.
   *
   * Do NOT push a "Notification Viewed" event yourself - the SDK already does.
   * This is just a notification for the host (e.g. your own analytics).
   */
  onDisplayUnitViewed?(unitId: string): void;

  /**
   * Fired when any element in a unit is clicked.
   *
   * Do NOT push a "Notification Clicked" event yourself - the SDK already does.
   * This is just a notification for the host.
   */
  onDisplayUnitClicked?(unitId: string): void;
}
