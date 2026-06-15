const TEMPLATE_PATTERN = /\{\{([^}]+)\}\}/g;

/**
 * Coerce a JS value into a boolean using FE-renderer / native-renderer
 * semantics. Returns `null` when the value can't be mapped, so callers can
 * fall back to their own default.
 *
 *   - `boolean` → identity.
 *   - `"true"` / `"false"` strings → literal.
 *   - `"1"` / `"0"` strings → true / false (BE often ships numeric flags
 *     as strings; matches Android + iOS behavior after PR #9 / PR #11).
 *   - finite `number` → `n !== 0`.
 *   - everything else (other strings, null, undefined, objects) → `null`.
 *
 * Critically, `"0"` is treated as `false` here. The JS default
 * (`Boolean("0")` → `true`) is the opposite of what the FE renderer does,
 * so without this coercion a node with `visible: "{{flag}}"` and
 * `variables: { flag: 0 }` would render on RN but not on iOS/Android.
 */
function coerceToBool(value: unknown): boolean | null {
  if (typeof value === 'boolean') return value;
  if (typeof value === 'number' && Number.isFinite(value)) return value !== 0;
  if (typeof value === 'string') {
    if (value === 'true') return true;
    if (value === 'false') return false;
    if (value === '1') return true;
    if (value === '0') return false;
  }
  return null;
}

export class VariableEvaluator {
  constructor(private variables: Record<string, unknown>) {}

  evaluateString(template: string): string {
    return template.replace(TEMPLATE_PATTERN, (_, expr: string) => {
      const value = this._evaluateExpression(expr.trim());
      return value == null ? '' : String(value);
    });
  }

  evaluateBoolean(expression: string): boolean {
    const trimmed = expression.trim();

    if (trimmed === 'true') return true;
    if (trimmed === 'false') return false;

    // Single template variable of the form {{varName}}
    const singleVarMatch = /^\{\{([^}]+)\}\}$/.exec(trimmed);
    if (singleVarMatch) {
      const value = this._getVariable(singleVarMatch[1]!.trim());
      const coerced = coerceToBool(value);
      if (coerced != null) return coerced;
      return Boolean(value);
    }

    // Check >= and <= before > and < to avoid partial matches
    if (trimmed.includes('>=')) return this._evaluateBinaryExpr(trimmed, '>=');
    if (trimmed.includes('<=')) return this._evaluateBinaryExpr(trimmed, '<=');
    if (trimmed.includes('>')) return this._evaluateBinaryExpr(trimmed, '>');
    if (trimmed.includes('<')) return this._evaluateBinaryExpr(trimmed, '<');
    if (trimmed.includes('!=')) return this._evaluateBinaryExpr(trimmed, '!=');
    if (trimmed.includes('==')) return this._evaluateBinaryExpr(trimmed, '==');

    const value = this._resolveOperand(trimmed);
    const coerced = coerceToBool(value);
    if (coerced != null) return coerced;
    const b = this._strictBool(String(value));
    return b ?? false;
  }

  private _evaluateExpression(expression: string): unknown {
    // Ternary expression: condition ? trueValue : falseValue
    const ternaryMatch = /^(.+?)\?(.+?):(.+)$/.exec(expression);
    if (ternaryMatch) {
      const condition = ternaryMatch[1]!.trim();
      const trueVal = ternaryMatch[2]!.trim().replace(/^['"]|['"]$/g, '');
      const falseVal = ternaryMatch[3]!.trim().replace(/^['"]|['"]$/g, '');
      // Evaluate the condition as-is, not wrapped in {{}}
      return this.evaluateBoolean(condition) ? trueVal : falseVal;
    }

    // Inside {{...}}: treat the expression as a variable path; return '' if missing
    return this._getVariable(expression) ?? '';
  }

  private _evaluateBinaryExpr(expression: string, operator: string): boolean {
    const idx = expression.indexOf(operator);
    if (idx === -1) return false;
    const leftRaw = expression.slice(0, idx).trim();
    const rightRaw = expression.slice(idx + operator.length).trim();

    const leftVal = this._resolveOperand(leftRaw);
    const rightVal = this._resolveOperand(rightRaw);

    if (operator === '>' || operator === '<' || operator === '>=' || operator === '<=') {
      const left = typeof leftVal === 'number' ? leftVal : parseFloat(String(leftVal));
      const right = typeof rightVal === 'number' ? rightVal : parseFloat(String(rightVal));
      if (isNaN(left) || isNaN(right)) return false;
      switch (operator) {
        case '>': return left > right;
        case '<': return left < right;
        case '>=': return left >= right;
        case '<=': return left <= right;
        default: return false;
      }
    }

    // Equality check: convert both sides to string before comparing
    const leftStr = String(leftVal ?? '');
    const rightStr = String(rightVal ?? '');
    return operator === '==' ? leftStr === rightStr : leftStr !== rightStr;
  }

  private _resolveOperand(raw: string): unknown {
    // Template variable of the form {{varName}}
    const templateMatch = /^\{\{([^}]+)\}\}$/.exec(raw);
    if (templateMatch) {
      return this._getVariable(templateMatch[1]!.trim()) ?? '';
    }
    // Quoted string literal (single or double quotes)
    if (
      (raw.startsWith('"') && raw.endsWith('"')) ||
      (raw.startsWith("'") && raw.endsWith("'"))
    ) {
      return raw.slice(1, -1);
    }
    // Numeric literal
    const num = parseFloat(raw);
    if (!isNaN(num) && String(num) === raw) return num;
    // Boolean literal
    if (raw === 'true') return true;
    if (raw === 'false') return false;
    // Bare variable name without template syntax
    const varValue = this._getVariable(raw);
    if (varValue !== undefined) return varValue;
    // Treat anything else as an unquoted string
    return raw;
  }

  private _getVariable(name: string): unknown {
    const parts = name.split('.');
    let current: unknown = this.variables[parts[0]!];
    if (current === undefined) return undefined;

    for (const part of parts.slice(1)) {
      if (current === null || typeof current !== 'object') return undefined;
      current = (current as Record<string, unknown>)[part];
    }
    return current;
  }

  private _strictBool(value: string): boolean | null {
    if (value === 'true') return true;
    if (value === 'false') return false;
    return null;
  }
}
