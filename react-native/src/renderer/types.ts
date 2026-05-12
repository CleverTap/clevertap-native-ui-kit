import type { NativeDisplayNode } from '../models/NativeDisplayNode';
import type { ResolvedStyles } from '../models/NativeDisplayConfig';
import type { ActionHandler } from '../handler/ActionHandler';

export interface RenderNodeProps {
  node: NativeDisplayNode;
  resolvedStyles: ResolvedStyles;
  actionHandler: ActionHandler;
  variables?: Record<string, unknown>;
}
