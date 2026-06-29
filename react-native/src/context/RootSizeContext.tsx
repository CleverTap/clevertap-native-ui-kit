import React, { createContext, useContext } from 'react';
import { Dimensions } from 'react-native';

export interface RootSize {
  width: number;
  height: number;
}

const defaultSize: RootSize = {
  width: Dimensions.get('window').width,
  height: Dimensions.get('window').height,
};

export const RootSizeContext = createContext<RootSize>(defaultSize);

export interface RootSizeProviderProps {
  size?: RootSize;
  children: React.ReactNode;
}

export function RootSizeProvider({ size, children }: RootSizeProviderProps): React.ReactElement {
  const resolved = size ?? defaultSize;
  return (
    <RootSizeContext.Provider value={resolved}>
      {children}
    </RootSizeContext.Provider>
  );
}

export function useRootSize(): RootSize {
  return useContext(RootSizeContext);
}
