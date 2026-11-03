import { resolveBoxDimensionsPx } from '../src/renderer/containers/boxDimensions';
import type { Dimension, Layout } from '../src/models/Layout';

const dp = (value: number): Dimension => ({ value, unit: 'dp' });
const pct = (value: number): Dimension => ({ value, unit: 'percent' });

const ROOT_W = 1000;
const ROOT_H = 800;

// The BOX computes its pixel size itself (to lay out absolute children). It must
// honor the same rule as the other SDKs: aspectRatio takes the FULL parent width
// and derives height = width / aspectRatio, ignoring width.percent/height.percent;
// skipped only when BOTH width and height are fixed (dp/sp/px).
describe('resolveBoxDimensionsPx — aspectRatio overrides percent (parity)', () => {
  it('AR + percent width/height: full parent width, height = width/AR (percent ignored)', () => {
    const layout: Layout = { width: pct(80), height: pct(60), aspectRatio: 2 };
    const r = resolveBoxDimensionsPx(layout, ROOT_W, ROOT_H);
    expect(r.width).toBe(ROOT_W); // full width — NOT 80% (800)
    expect(r.height).toBeCloseTo(ROOT_W / 2);
  });

  it('AR with only width fixed (not both fixed): still full parent width', () => {
    const layout: Layout = { width: dp(300), height: pct(50), aspectRatio: 2 };
    const r = resolveBoxDimensionsPx(layout, ROOT_W, ROOT_H);
    expect(r.width).toBe(ROOT_W);
    expect(r.height).toBeCloseTo(ROOT_W / 2);
  });

  it('BOTH width & height fixed: AR skipped, fixed box wins', () => {
    const layout: Layout = { width: dp(300), height: dp(120), aspectRatio: 2 };
    const r = resolveBoxDimensionsPx(layout, ROOT_W, ROOT_H);
    expect(r.width).toBe(300);
    expect(r.height).toBe(120);
  });

  it('no aspectRatio: percent width/height resolve against the root', () => {
    const layout: Layout = { width: pct(80), height: pct(60) };
    const r = resolveBoxDimensionsPx(layout, ROOT_W, ROOT_H);
    expect(r.width).toBeCloseTo(800); // 80% of 1000
    expect(r.height).toBeCloseTo(480); // 60% of 800
  });
});
