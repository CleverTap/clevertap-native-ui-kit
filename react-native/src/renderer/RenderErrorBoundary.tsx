import React from 'react';
import { View } from 'react-native';

interface RenderErrorBoundaryProps {
  children: React.ReactNode;
  /**
   * Content to show when a child component throws. If omitted, an empty
   * `<View />` is rendered so the host layout collapses gracefully.
   */
  fallback?: React.ReactNode;
  /**
   * Optional callback fired after `componentDidCatch` so the host can send
   * the error to analytics. The boundary already calls `console.error` itself.
   */
  onError?: (error: Error, info: React.ErrorInfo) => void;
}

interface RenderErrorBoundaryState {
  hasError: boolean;
}

/**
 * Catches render-time and lifecycle errors thrown inside a
 * `NativeDisplayView` subtree so they cannot crash the host app.
 *
 * Why this exists
 * ---------------
 * The SDK renders arbitrary server-driven JSON. That JSON can be:
 *  - malformed or schema-changed by the server without a client-side release
 *  - missing required fields (null colors, empty arrays, unknown node types)
 *  - using features that the installed SDK version does not support yet
 *
 * On React Native with the New Architecture (Fabric), an uncaught render
 * error propagates up the whole React tree. Fabric then tears down the host
 * surface - the entire app crashes to a blank screen or an error overlay.
 * Without this boundary, one bad JSON payload can bring down the whole app.
 *
 * This boundary catches errors at the SDK boundary, collapses only the
 * affected display unit to an empty `<View />` (or the `fallback` prop), and
 * logs a descriptive error. Every other part of the host app keeps running.
 *
 * Dev-mode note
 * -------------
 * React 19 introduced an `onCaughtError` root option that routes every
 * boundary-caught error through `ExceptionsManager`, which triggers the red
 * dev overlay even though the boundary handled the error. This is intentional
 * React dev-mode behavior and cannot be suppressed from SDK code. In
 * production (`__DEV__ === false`) the overlay is never shown and the boundary
 * works silently as intended.
 *
 * Key prop reset pattern
 * ----------------------
 * Once a boundary flips to `hasError: true` it stays there until unmounted.
 * `NativeDisplayView` passes `key={unitId}` to this component so React
 * remounts a fresh boundary whenever the active unit changes. Without that
 * key, switching from a broken unit to a healthy one would still show the
 * empty fallback because the same boundary instance is reused.
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
