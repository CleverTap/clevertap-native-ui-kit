import * as fs from 'fs';
import * as path from 'path';
import { NativeDisplayConfigParser } from '../src/bridge/NativeDisplayConfigParser';
import { VariableEvaluator } from '../src/evaluator/VariableEvaluator';
import { resolveArrangement } from '../src/renderer/arrangement';
import type { ChildArrangement } from '../src/models/Layout';

// ─── Test config loader ────────────────────────────────────────────────────────

const TEST_CONFIGS_DIR = path.resolve(__dirname, '../../test-configs');

function loadTestConfig(filename: string): string {
  const content = fs.readFileSync(path.join(TEST_CONFIGS_DIR, filename), 'utf-8');
  const obj = JSON.parse(content) as Record<string, unknown>;
  // Wrap with required wzrk_id so the parser accepts it
  return JSON.stringify({ wzrk_id: 'test-unit-001', slot_id: 'test-slot', ...obj });
}

function loadAllTestConfigs(): Array<{ file: string; json: string }> {
  return fs
    .readdirSync(TEST_CONFIGS_DIR)
    .filter((f) => f.endsWith('.json') && f.startsWith('test-'))
    .map((file) => ({ file, json: loadTestConfig(file) }));
}

// ─── Parser tests ─────────────────────────────────────────────────────────────

describe('NativeDisplayConfigParser', () => {
  const parser = new NativeDisplayConfigParser();

  test('parses bare root config (strategy 3)', () => {
    const json = loadTestConfig('test-001-vertical-simple.json');
    const unit = parser.tryParse(json);
    expect(unit).not.toBeNull();
    expect(unit!.unitId).toBe('test-unit-001');
    expect(unit!.slotId).toBe('test-slot');
    expect(unit!.config.root).toBeDefined();
    expect(Object.keys(unit!.resolvedStyles).length).toBeGreaterThan(0);
  });

  test('parses native_display_config strategy (strategy 1)', () => {
    const inner = JSON.parse(loadTestConfig('test-001-vertical-simple.json')) as Record<string, unknown>;
    const wrapped = JSON.stringify({
      wzrk_id: 'unit-strat1',
      slot_id: 'slot-1',
      native_display_config: inner,
    });
    const unit = parser.tryParse(wrapped);
    expect(unit).not.toBeNull();
    expect(unit!.unitId).toBe('unit-strat1');
  });

  test('parses custom_kv.nd_config strategy (strategy 2)', () => {
    const inner = JSON.parse(loadTestConfig('test-001-vertical-simple.json')) as Record<string, unknown>;
    const wrapped = JSON.stringify({
      wzrk_id: 'unit-strat2',
      slot_id: 'slot-2',
      custom_kv: {
        nd_config: JSON.stringify(inner),
        extra_key: 'extra_value',
      },
    });
    const unit = parser.tryParse(wrapped);
    expect(unit).not.toBeNull();
    expect(unit!.unitId).toBe('unit-strat2');
    expect(unit!.customExtras['extra_key']).toBe('extra_value');
    expect(unit!.customExtras['nd_config']).toBeUndefined();
  });

  test('returns null when wzrk_id is missing', () => {
    const json = JSON.stringify({ root: { type: 'container', id: 'root', containerType: 'vertical', children: [] } });
    expect(parser.tryParse(json)).toBeNull();
  });

  test('returns null for invalid JSON', () => {
    expect(parser.tryParse('not json')).toBeNull();
    expect(parser.tryParse('')).toBeNull();
  });

  describe('round-trips all test-configs', () => {
    const configs = loadAllTestConfigs();

    test.each(configs)('parses $file', ({ json }) => {
      const unit = parser.tryParse(json);
      expect(unit).not.toBeNull();
      expect(unit!.config.root).toBeDefined();
    });

    test.each(configs)('resolvedStyles non-empty for $file', ({ json }) => {
      const unit = parser.tryParse(json);
      expect(unit).not.toBeNull();
      expect(Object.keys(unit!.resolvedStyles).length).toBeGreaterThan(0);
    });
  });
});

// ─── VariableEvaluator tests ──────────────────────────────────────────────────

describe('VariableEvaluator', () => {
  test('replaces simple variable', () => {
    const ev = new VariableEvaluator({ name: 'Alice' });
    expect(ev.evaluateString('Hello {{name}}!')).toBe('Hello Alice!');
  });

  test('replaces nested path', () => {
    const ev = new VariableEvaluator({ user: { profile: { name: 'Bob' } } });
    expect(ev.evaluateString('{{user.profile.name}}')).toBe('Bob');
  });

  test('missing variable resolves to empty string', () => {
    const ev = new VariableEvaluator({});
    expect(ev.evaluateString('{{missing}}')).toBe('');
  });

  test('evaluateBoolean: equality comparison', () => {
    const ev = new VariableEvaluator({ x: 5 });
    expect(ev.evaluateBoolean('{{x}} == 5')).toBe(true);
    expect(ev.evaluateBoolean('{{x}} == 6')).toBe(false);
  });

  test('evaluateBoolean: greater than', () => {
    const ev = new VariableEvaluator({ count: 10 });
    expect(ev.evaluateBoolean('{{count}} > 5')).toBe(true);
    expect(ev.evaluateBoolean('{{count}} >= 10')).toBe(true);
    expect(ev.evaluateBoolean('{{count}} > 10')).toBe(false);
  });

  test('evaluateBoolean: less than', () => {
    const ev = new VariableEvaluator({ count: 3 });
    expect(ev.evaluateBoolean('{{count}} < 5')).toBe(true);
    expect(ev.evaluateBoolean('{{count}} <= 3')).toBe(true);
    expect(ev.evaluateBoolean('{{count}} < 3')).toBe(false);
  });

  test('evaluateBoolean: inequality', () => {
    const ev = new VariableEvaluator({ x: 5 });
    expect(ev.evaluateBoolean('{{x}} != 5')).toBe(false);
    expect(ev.evaluateBoolean('{{x}} != 6')).toBe(true);
  });

  test('evaluateBoolean: boolean literals', () => {
    const ev = new VariableEvaluator({});
    expect(ev.evaluateBoolean('true')).toBe(true);
    expect(ev.evaluateBoolean('false')).toBe(false);
  });

  test('evaluateBoolean: ternary in string context', () => {
    const ev = new VariableEvaluator({ flag: true });
    const result = ev.evaluateString('{{flag == true ? "yes" : "no"}}');
    expect(result).toBe('yes');
  });

  test('multiple substitutions in one string', () => {
    const ev = new VariableEvaluator({ first: 'John', last: 'Doe' });
    expect(ev.evaluateString('{{first}} {{last}}')).toBe('John Doe');
  });
});

// ─── Arrangement mapping tests ────────────────────────────────────────────────

describe('resolveArrangement', () => {
  const baseArrangement: ChildArrangement = { strategy: 'spaced', spacing: 8 };

  test('spaced → flex-start + gap', () => {
    const result = resolveArrangement({ strategy: 'spaced', spacing: 8 }, 'column');
    expect(result.justifyContent).toBe('flex-start');
    expect(result.gap).toBe(8);
    expect(result.alignItems).toBe('flex-start');
  });

  test('space_between → space-between, no gap', () => {
    const result = resolveArrangement({ strategy: 'space_between' }, 'row');
    expect(result.justifyContent).toBe('space-between');
    expect(result.gap).toBeUndefined();
    expect(result.alignItems).toBe('flex-start');
  });

  test('space_evenly → space-evenly', () => {
    const result = resolveArrangement({ strategy: 'space_evenly' }, 'column');
    expect(result.justifyContent).toBe('space-evenly');
  });

  test('space_around → space-around', () => {
    const result = resolveArrangement({ strategy: 'space_around' }, 'column');
    expect(result.justifyContent).toBe('space-around');
  });

  test('start → flex-start', () => {
    const result = resolveArrangement({ strategy: 'start' }, 'row');
    expect(result.justifyContent).toBe('flex-start');
    expect(result.gap).toBeUndefined();
  });

  test('center → center', () => {
    const result = resolveArrangement({ strategy: 'center' }, 'column');
    expect(result.justifyContent).toBe('center');
  });

  test('end → flex-end', () => {
    const result = resolveArrangement({ strategy: 'end' }, 'row');
    expect(result.justifyContent).toBe('flex-end');
  });

  test('always sets alignItems to flex-start (RN nuance #1)', () => {
    const strategies: ChildArrangement['strategy'][] = [
      'spaced', 'space_between', 'space_evenly', 'space_around', 'start', 'center', 'end',
    ];
    for (const strategy of strategies) {
      const result = resolveArrangement({ strategy }, 'column');
      expect(result.alignItems).toBe('flex-start');
    }
  });

  test('spaced with spacing=0 omits gap', () => {
    const result = resolveArrangement({ strategy: 'spaced', spacing: 0 }, 'column');
    expect(result.gap).toBeUndefined();
  });

  test('flexDirection matches the direction arg', () => {
    expect(resolveArrangement(baseArrangement, 'row').flexDirection).toBe('row');
    expect(resolveArrangement(baseArrangement, 'column').flexDirection).toBe('column');
  });
});
