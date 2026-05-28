export interface NativeDisplayActionListener {
  onOpenUrl(url: string, openInBrowser: boolean): boolean;
  onCustomAction(key: string, value: unknown, metadata?: Record<string, string>): void;
  onNavigate(destination: string, params?: Record<string, string>): void;
  onTrackEvent(eventName: string, properties?: Record<string, unknown>): void;
  onDisplayUnitViewed?(unitId: string): void;
  onDisplayUnitClicked?(unitId: string): void;
}
