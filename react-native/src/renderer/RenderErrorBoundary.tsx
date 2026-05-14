import React from 'react';
import { View } from 'react-native';

interface RenderErrorBoundaryProps {
  children: React.ReactNode;
  /**
   * Optional placeholder rendered when a descendant throws during render or in a
   * lifecycle method. If omitted, an empty `<View />` is rendered so the host
   * layout collapses gracefully instead of crashing.
   */
  fallback?: React.ReactNode;
  /**
   * Optional callback fired after `componentDidCatch` so the host can log to
   * analytics. The boundary already calls `console.error` on its own.
   */
  onError?: (error: Error, info: React.ErrorInfo) => void;
}

interface RenderErrorBoundaryState {
  hasError: boolean;
}

/**
 * Isolates render-time and lifecycle exceptions thrown inside a
 * `NativeDisplayView` subtree so they cannot crash the host app.
 *
 * WHY THIS EXISTS
 * ---------------
 * The SDK renders arbitrary server-driven JSON. That JSON can be:
 *  - malformed or schema-changed by the server without a client-side release
 *  - missing required fields (null colours, empty arrays, unknown node types)
 *  - carrying feature flags that the installed SDK version does not yet support
 *
 * On React Native with the New Architecture (Fabric) an uncaught render
 * exception propagates all the way up the React tree. Fabric then tears down
 * the host surface — the entire host app crashes to a blank screen or a
 * red/white error overlay. Without this boundary, one bad JSON payload can
 * bring down the whole app.
 *
 * This boundary catches those exceptions at the SDK boundary, collapses only
 * the affected display unit to an empty `<View />` (or the optional `fallback`
 * prop supplied by the host), and logs a descriptive error. Every other part
 * of the host app continues to run normally.
 *
 * DEV-MODE NOTE
 * -------------
 * React 19 introduced an `onCaughtError` root option that fires for every
 * boundary-caught error and routes it through `ExceptionsManager` — which
 * triggers the red dev overlay even though the boundary handled the error.
 * This is React's intentional dev-mode behaviour and cannot be suppressed
 * from SDK code. In production (where `__DEV__ === false`) the overlay is
 * never shown and the boundary works silently as intended.
 *
 * KEY PROP RESET PATTERN
 * ----------------------
 * Once a boundary flips to `hasError: true` it stays there until it is
 * unmounted. `NativeDisplayView` passes `key={unitId}` to this component so
 * React remounts a fresh boundary whenever the active unit changes. Without
 * that key, navigating away from a broken config would leave the boundary in
 * error state and render an empty view for every subsequent unit.
 */
export class RenderErrorBoundary extends React.Component<
  RenderErrorBoundaryProps,
  RenderErrorBoundaryState
> {
  state: RenderErrorBoundaryState = { hasError: false };

  static getDerivedStateFromError(): RenderErrorBoundaryState {
    return { hasError: true };
  }

  componentDidCatch(error: Error, info: React.ErrorInfo): void {
    console.error('[NativeDisplay] render error:', error, info);
    this.props.onError?.(error, info);
  }

  render(): React.ReactNode {
    if (this.state.hasError) {
      return this.props.fallback ?? <View />;
    }
    return this.props.children;
  }
}
