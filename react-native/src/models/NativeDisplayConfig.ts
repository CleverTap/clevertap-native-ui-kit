import { NativeDisplayNode } from './NativeDisplayNode';
import { Style, StyleClass, Theme } from './Style';

export interface NativeDisplayConfig {
  version?: string;
  theme?: Theme;
  styleClasses?: StyleClass[];
  variables?: Record<string, unknown>;
  root?: NativeDisplayNode;
}

export interface ResolvedConfig {
  theme: Theme;
  styleClasses: StyleClass[];
  variables: Record<string, unknown>;
  root: NativeDisplayNode;
}

export interface ResolvedStyles {
  [nodeId: string]: Style;
}

export const DEFAULT_THEME: Theme = {
  id: 'default',
  defaultStyle: {},
  colors: {},
};

export function toResolvedConfig(config: NativeDisplayConfig): ResolvedConfig | null {
  if (!config.root) return null;
  return {
    theme: config.theme ?? DEFAULT_THEME,
    styleClasses: config.styleClasses ?? [],
    variables: config.variables ?? {},
    root: config.root,
  };
}
