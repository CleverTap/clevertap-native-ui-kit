import React, { createContext, useContext } from 'react';

export type Variables = Record<string, unknown>;

const EMPTY_VARIABLES: Variables = Object.freeze({});

export const VariablesContext = createContext<Variables>(EMPTY_VARIABLES);

export interface VariablesProviderProps {
  variables?: Variables;
  children: React.ReactNode;
}

/**
 * Shares the `variables` map with all child components via context.
 *
 * We use context instead of passing variables as a prop so `RenderNode` keeps
 * a stable reference across renders. That lets `React.memo` on containers skip
 * unneeded re-renders - a prop would create a new closure each render and
 * break memo.
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
