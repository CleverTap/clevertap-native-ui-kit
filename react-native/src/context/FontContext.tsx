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

export function resolveFont(fontFamily: string | undefined, ctx: FontContextValue): string | undefined {
  const family = fontFamily ?? ctx.defaultFontFamily;
  if (!family) return undefined;
  if (ctx.fontResolver) return ctx.fontResolver(family);
  return family;
}
