import { ArrangementStrategy, DimensionUnit, SpecialDimension } from './enums';

export interface Dimension {
  value: number;
  unit: DimensionUnit;
  special?: SpecialDimension | null;
}

export interface Offset {
  x: number;
  y: number;
  unit: DimensionUnit;
}

export interface Spacing {
  all?: number;
  horizontal?: number;
  vertical?: number;
  top?: number;
  bottom?: number;
  left?: number;
  right?: number;
  unit?: DimensionUnit;
}

export interface ChildArrangement {
  strategy: ArrangementStrategy;
  spacing?: number;
  spacingUnit?: DimensionUnit;
}

export interface Layout {
  width?: Dimension;
  height?: Dimension;
  aspectRatio?: number;
  offset?: Offset;
  padding?: Spacing;
  arrangement?: ChildArrangement;
}

export function resolveSpacingTop(s: Spacing): number {
  return s.top ?? s.vertical ?? s.all ?? 0;
}

export function resolveSpacingBottom(s: Spacing): number {
  return s.bottom ?? s.vertical ?? s.all ?? 0;
}

export function resolveSpacingLeft(s: Spacing): number {
  return s.left ?? s.horizontal ?? s.all ?? 0;
}

export function resolveSpacingRight(s: Spacing): number {
  return s.right ?? s.horizontal ?? s.all ?? 0;
}

export function parseDimension(raw: unknown): Dimension | undefined {
  if (raw == null) return undefined;
  if (typeof raw === 'number') {
    return { value: raw, unit: 'dp' };
  }
  if (typeof raw === 'string') {
    if (raw === 'wrap_content') return { value: 0, unit: 'dp', special: 'wrap_content' };
    if (raw === 'match_parent') return { value: 0, unit: 'dp', special: 'match_parent' };
    if (raw.endsWith('%')) {
      const val = parseFloat(raw);
      if (!isNaN(val)) return { value: val, unit: 'percent' };
    }
    const num = parseFloat(raw);
    if (!isNaN(num)) return { value: num, unit: 'dp' };
    return undefined;
  }
  if (typeof raw === 'object' && raw !== null) {
    const obj = raw as Record<string, unknown>;
    if (obj.special === 'wrap_content') return { value: 0, unit: 'dp', special: 'wrap_content' };
    if (obj.special === 'match_parent') return { value: 0, unit: 'dp', special: 'match_parent' };
    const value = typeof obj.value === 'number' ? obj.value : parseFloat(String(obj.value ?? 0));
    const unit = (obj.unit as DimensionUnit) ?? 'dp';
    const special = obj.special != null ? (obj.special as SpecialDimension) : null;
    return { value: isNaN(value) ? 0 : value, unit, special: special ?? null };
  }
  return undefined;
}
