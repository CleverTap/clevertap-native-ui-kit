import { resolveRootHeightDp, resolveRootWidthDp } from '../src/renderer/rootHeight';
import type { Dimension, Layout } from '../src/models/Layout';

const dp = (v: number): Dimension => ({ value: v, unit: 'dp' });
const pct = (v: number): Dimension => ({ value: v, unit: 'percent' });

// Mirrors the native SDK's resolveRootHeightPx cascade. The key case: an
// aspectRatio root anchors on the DECLARED percent width (not the full box width),
// matching native — otherwise percent fonts come out too large.
describe('resolveRootWidthDp', () => {
  it('percent resolves against parent', () => {
    expect(resolveRootWidthDp({ width: pct(80) } as Layout, 1000)).toBe(800);
  });
  it('dp uses raw value', () => {
    expect(resolveRootWidthDp({ width: dp(300) } as Layout, 1000)).toBe(300);
  });
  it('no width falls back to parent', () => {
    expect(resolveRootWidthDp({} as Layout, 1000)).toBe(1000);
  });
});

describe('resolveRootHeightDp — native cascade parity', () => {
  it('aspectRatio honors the declared percent width (header3: 80%/AR 1)', () => {
    const layout: Layout = { width: pct(80), height: pct(60), aspectRatio: 1 };
    // rootWidth = 0.8*1000 = 800; /AR 1 = 800  (NOT 1000 = full width)
    expect(resolveRootHeightDp(layout, 1000, 5000, 2400)).toBeCloseTo(800, 3);
  });

  it('aspectRatio 1.7778 with percent width', () => {
    const layout: Layout = { width: pct(80), height: pct(60), aspectRatio: 1.7778 };
    expect(resolveRootHeightDp(layout, 1000, 5000, 2400)).toBeCloseTo(800 / 1.7778, 3);
  });

  it('fixed dp height wins over aspectRatio', () => {
    const layout: Layout = { width: pct(80), height: dp(120), aspectRatio: 1.5 };
    expect(resolveRootHeightDp(layout, 1000, 5000, 2400)).toBe(120);
  });

  it('percent height when no aspectRatio', () => {
    const layout: Layout = { width: pct(80), height: pct(60) };
    expect(resolveRootHeightDp(layout, 1000, 500, 2400)).toBeCloseTo(300, 3); // 60% of 500
  });

  it('falls back to parentHeight, then screenHeight', () => {
    expect(resolveRootHeightDp({} as Layout, 1000, 500, 2400)).toBe(500);
    expect(resolveRootHeightDp({} as Layout, 1000, 0, 2400)).toBe(2400);
  });
});
