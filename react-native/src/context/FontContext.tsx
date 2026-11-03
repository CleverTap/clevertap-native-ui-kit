import React, { createContext, useContext } from 'react';

export interface FontContextValue {
  fontResolver?: (fontFamily: string) => string;
  defaultFontFamily?: string;
}

export const FontContext = createContext<FontContextValue>({});

export interface FontProviderProps {
  fontResolver?: (fontFamily: string) => string;
  defaultFontFamily?: string;
  children: React.ReactNode;
}

export function FontProvider({ fontResolver, defaultFontFamily, children }: FontProviderProps): React.ReactElement {
  return (
    <FontContext.Provider value={{ fontResolver, defaultFontFamily }}>
      {children}
    </FontContext.Provider>
  );
}

export function useFontContext(): FontContextValue {
  return useContext(FontContext);
}

/**
 * Picks which font family to use, matching iOS and Android priority:
 *   1. Client default (highest). Used as-is, not passed through fontResolver.
 *   2. JSON `fontFamily`, remapped by fontResolver if one is set.
 *   3. System default (returns undefined so RN uses the OS font).
 *
 * Note: the client default must win over the JSON font, or a JSON config could
 * override the client's chosen font - the opposite of what native does.
 */
export function resolveFont(fontFamily: string | undefined, ctx: FontContextValue): string | undefined {
  if (ctx.defaultFontFamily) return ctx.defaultFontFamily;
  if (fontFamily) return ctx.fontResolver ? ctx.fontResolver(fontFamily) : fontFamily;
  return undefined;
}
