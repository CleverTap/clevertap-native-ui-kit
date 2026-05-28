import { ResolvedConfig, ResolvedStyles } from '../models/NativeDisplayConfig';

export interface NativeDisplayUnit {
  unitId: string;
  config: ResolvedConfig;
  resolvedStyles: ResolvedStyles;
  slotId?: string;
  customExtras: Record<string, string>;
  rawJson?: string;
}
