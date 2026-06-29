import React, { createContext, useContext } from 'react';

export type Variables = Record<string, unknown>;

const EMPTY_VARIABLES: Variables = Object.freeze({});

export const VariablesContext = createContext<Variables>(EMPTY_VARIABLES);

export interface VariablesProviderProps {
  variables?: Variables;
  children: React.ReactNode;
}

/**
 * Provides the unit-level `variables` map to all child components via context.
 *
 * Putting variables in context (instead of passing them as a prop through every
 * RenderNodeProps call) lets `RenderNode` be passed by stable reference to
 * container components. Containers get the same `RenderNode` reference across
 * renders, so their `React.memo` wrapping can skip re-renders correctly.
 *
 * Without this, `RenderNode.tsx` would need an inline closure like
 * `(props) => <RenderNode {...props} variables={variables} />` to pass the
 * variables down. A new closure object is created on every parent render,
 * which looks like a new `RenderNode` prop to the container - breaking memo.
 */
export function VariablesProvider({ variables, children }: VariablesProviderProps): React.ReactElement {
  return (
    <VariablesContext.Provider value={variables ?? EMPTY_VARIABLES}>
      {children}
    </VariablesContext.Provider>
  );
}

export function useVariables(): Variables {
  return useContext(VariablesContext);
}
