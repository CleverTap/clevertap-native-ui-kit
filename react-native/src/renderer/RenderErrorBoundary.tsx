import React from 'react';
import { View } from 'react-native';
import { NDLogger } from '../internal/NDLogger';

interface RenderErrorBoundaryProps {
  children: React.ReactNode;
  /** What to show when a child throws. Defaults to an empty <View />. */
  fallback?: React.ReactNode;
  /**
   * Called after componentDidCatch so the host can log the error to analytics.
   * The boundary already logs it via NDLogger.
   */
  onError?: (error: Error, info: React.ErrorInfo) => void;
}

interface RenderErrorBoundaryState {
  hasError: boolean;
}

/**
 * Catches errors thrown while rendering a NativeDisplayView so bad JSON can't
 * crash the host app.
 *
 * Why it exists: the SDK renders arbitrary server JSON that may be malformed,
 * missing fields, or using unsupported features. On Fabric an uncaught render
 * error tears down the whole app. This boundary contains the damage to the one
 * display unit, shows an empty <View /> (or the fallback prop), and logs it.
 *
 * Dev-mode note: React 19 still shows the red error overlay for caught errors
 * in dev. That's expected and can't be turned off from here. In production the
 * overlay never appears.
 *
 * Key reset: once tripped, a boundary stays broken until it unmounts.
 * NativeDisplayView passes key={unitId} so each unit gets a fresh boundary -
 * otherwise a broken unit's fallback would stick around after switching to a
 * healthy one.
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
    NDLogger.e('NativeDisplay', 'render error:', error, info);
    this.props.onError?.(error, info);
  }

  render(): React.ReactNode {
    if (this.state.hasError) {
      return this.props.fallback ?? <View />;
    }
    return this.props.children;
  }
}
