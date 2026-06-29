import React, { createContext, useContext } from 'react';

/**
 * Pixel size of the immediate parent's layout box, propagated from each
 * container to its children. Lets a child resolve `width: '100%'` /
 * `height: '100%'` against its nearest sized ancestor instead of the root.
 *
 * Why this exists (separate from `RootSizeContext`):
 *   iOS Fabric refuses to resolve `width: '100%'` / `height: '100%'` reliably
 *   for both flow children inside a `ScrollView`-backed root and absolutely-
 *   positioned children inside any container. Yoga falls back to resolving
 *   percentages against the parent's INTRINSIC content size rather than its
 *   actual rendered size, so the percent collapses to wrap_content. The
 *   workaround is to substitute the explicit pixel value before passing the
 *   style to Yoga.
 *
 *   For the root container we can use `useRootSize()` directly. For nested
 *   containers that is wrong - "100%" should mean "100% of my immediate
 *   parent" not "100% of the entire NativeDisplayView". Each container reads
 *   its parent's resolved size from this context and provides its own resolved
 *   size to its children, building a chain that mirrors what Yoga should have
 *   computed natively.
 *
 *   `null` is the "no parent yet" sentinel, used at the top of the tree.
 *   Consumers fall back to the root size in that case.
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
