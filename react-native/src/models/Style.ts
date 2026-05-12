import { Dimension } from './Layout';
import {
  FontStyle,
  FontWeight,
  TextDecoration,
  TextDimensionUnit,
  TextOverflow,
} from './enums';
import type { Background } from './Background';

export interface TextDimension {
  value: number;
  unit: TextDimensionUnit;
}

export interface TextShadow {
  color: string;
  offsetX: number;
  offsetY: number;
  blur: number;
}

export interface TextGradient {
  type: string;
  colors: string[];
  angle: number;
  stops?: number[];
}

export interface Style {
  // Text properties (cascade to children)
  textColor?: string;
  fontSize?: TextDimension;
  fontFamily?: string;
  fontWeight?: FontWeight;
  fontStyle?: FontStyle;
  lineHeight?: TextDimension;
  letterSpacing?: number;
  textDecoration?: TextDecoration;
  textAlign?: string;
  maxLines?: number;
  overflow?: TextOverflow;
  textShadow?: TextShadow;
  textGradient?: TextGradient;

  // Visual properties (do NOT cascade)
  background?: Background;
  backgroundColor?: string;

  // Border properties (do NOT cascade)
  borderRadius?: Dimension;
  borderWidth?: number;
  borderColor?: string;

  // Shadow properties (do NOT cascade)
  shadowColor?: string;
  shadowRadius?: number;
  shadowOffsetX?: number;
  shadowOffsetY?: number;

  // Universal (cascades)
  opacity?: number;
}

export interface StyleClass {
  name: string;
  style: Style;
}

export interface Theme {
  id: string;
  defaultStyle: Style;
  colors: Record<string, string>;
}

export const CASCADING_KEYS: (keyof Style)[] = [
  'textColor',
  'fontSize',
  'fontFamily',
  'fontWeight',
  'fontStyle',
  'lineHeight',
  'letterSpacing',
  'textDecoration',
  'textAlign',
  'maxLines',
  'overflow',
  'textShadow',
  'textGradient',
  'opacity',
];

export function mergeStyles(own: Style, fallback: Style): Style {
  const result: Style = { ...fallback };
  const ownKeys = Object.keys(own) as (keyof Style)[];
  for (const key of ownKeys) {
    if (own[key] !== undefined) {
      (result as Record<string, unknown>)[key] = own[key];
    }
  }
  return result;
}

export function cascadingOnly(style: Style): Style {
  const result: Partial<Style> = {};
  for (const key of CASCADING_KEYS) {
    if (style[key] !== undefined) {
      (result as Record<string, unknown>)[key] = style[key];
    }
  }
  return result as Style;
}

export function parseTextDimension(raw: unknown): TextDimension | undefined {
  if (raw == null) return undefined;
  if (typeof raw === 'number') return { value: raw, unit: 'platform' };
  if (typeof raw === 'object' && raw !== null) {
    const obj = raw as Record<string, unknown>;
    const value = typeof obj.value === 'number' ? obj.value : parseFloat(String(obj.value ?? 0));
    const unit: TextDimensionUnit = obj.unit === 'percent' ? 'percent' : 'platform';
    return { value: isNaN(value) ? 0 : value, unit };
  }
  return undefined;
}

export function resolveTextDimension(td: TextDimension, rootHeightPx: number): number {
  if (td.unit === 'percent') return rootHeightPx * td.value / 1000;
  return td.value;
}
