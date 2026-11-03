import React, { createContext, useContext } from 'react';

/**
 * Pixel size of a node's immediate parent. Each container passes its own size
 * down to its children so a child can turn `width: '100%'` into real pixels.
 *
 * Why not just use RootSizeContext: on iOS, Yoga doesn't reliably resolve
 * percentage sizes, so we compute them ourselves. And "100%" should mean
 * "100% of my parent", not the whole view - so we track the parent size, not
 * just the root.
 *
 * `null` means "no parent yet" (top of the tree); consumers fall back to the
 * root size then.
 */
export interface ParentSize {
  width: number;
  height: number;
}

const ParentSizeContext = createContext<ParentSize | null>(null);

export function ParentSizeProvider({
  value,
  children,
}: {
  value: ParentSize;
  children: React.ReactNode;
}): React.ReactElement {
  return (
    <ParentSizeContext.Provider value={value}>
      {children}
    </ParentSizeContext.Provider>
  );
}

export function useParentSize(): ParentSize | null {
  return useContext(ParentSizeContext);
}
