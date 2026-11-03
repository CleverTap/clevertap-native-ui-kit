import { resolveLayoutStyle } from '../src/renderer/layoutModifier';
import type { Dimension, Layout } from '../src/models/Layout';

// Helpers to build dimensions concisely.
const px = (value: number): Dimension => ({ value, unit: 'dp' });
const pct = (value: number): Dimension => ({ value, unit: 'percent' });

// Cross-platform rule (Android / iOS / Flutter): when a node has aspectRatio it
// takes the full available parent width and derives height = width / aspectRatio,
// IGNORING any width.percent / height.percent. aspectRatio is skipped ONLY when
// BOTH width AND height are fixed (dp/sp/px) simultaneously.
describe('resolveLayoutStyle — aspectRatio overrides percent (parity with native/Flutter)', () => {
  it('AR + percent width/height: full width + AR, percent ignored, height derived', () => {
    const layout: Layout = { width: pct(80), height: pct(60), aspectRatio: 1.7778 };
    const s = resolveLayoutStyle(layout, 800);
    expect(s.width).toBe('100%');
    expect(s.aspectRatio).toBe(1.7778);
    // height is left to Yoga (= width / aspectRatio); must NOT be the percent value.
    expect(s.height).toBeUndefined();
  });

  it('AR with only width fixed (not both fixed): AR still applies', () => {
    const layout: Layout = { width: px(200), height: pct(50), aspectRatio: 1.5 };
    const s = resolveLayoutStyle(layout, 800);
    expect(s.width).toBe('100%');
    expect(s.aspectRatio).toBe(1.5);
    expect(s.height).toBeUndefined();
  });

  it('BOTH width & height fixed: AR is skipped, the fixed box wins', () => {
    const layout: Layout = { width: px(200), height: px(120), aspectRatio: 1.7778 };
    const s = resolveLayoutStyle(layout, 800);
    expect(s.width).toBe(200);
    expect(s.height).toBe(120);
    expect(s.aspectRatio).toBeUndefined();
  });

  it('no aspectRatio: percent width/height pass through unchanged', () => {
    const layout: Layout = { width: pct(50), height: pct(30) };
    const s = resolveLayoutStyle(layout, 800);
    expect(s.width).toBe('50%');
    expect(s.height).toBe('30%');
    expect(s.aspectRatio).toBeUndefined();
  });
});
