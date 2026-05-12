const TEMPLATE_PATTERN = /\{\{([^}]+)\}\}/g;

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

    // Single template variable: {{varName}}
    const singleVarMatch = /^\{\{([^}]+)\}\}$/.exec(trimmed);
    if (singleVarMatch) {
      const value = this._getVariable(singleVarMatch[1]!.trim());
      if (typeof value === 'boolean') return value;
      if (value === 'true') return true;
      if (value === 'false') return false;
      return Boolean(value);
    }

    // Multi-operator checks: >= and <= must come before > and <
    if (trimmed.includes('>=')) return this._evaluateBinaryExpr(trimmed, '>=');
    if (trimmed.includes('<=')) return this._evaluateBinaryExpr(trimmed, '<=');
    if (trimmed.includes('>')) return this._evaluateBinaryExpr(trimmed, '>');
    if (trimmed.includes('<')) return this._evaluateBinaryExpr(trimmed, '<');
    if (trimmed.includes('!=')) return this._evaluateBinaryExpr(trimmed, '!=');
    if (trimmed.includes('==')) return this._evaluateBinaryExpr(trimmed, '==');

    const value = this._resolveOperand(trimmed);
    if (typeof value === 'boolean') return value;
    const b = this._strictBool(String(value));
    return b ?? false;
  }

  private _evaluateExpression(expression: string): unknown {
    // Ternary: condition ? trueValue : falseValue
    const ternaryMatch = /^(.+?)\?(.+?):(.+)$/.exec(expression);
    if (ternaryMatch) {
      const condition = ternaryMatch[1]!.trim();
      const trueVal = ternaryMatch[2]!.trim().replace(/^['"]|['"]$/g, '');
      const falseVal = ternaryMatch[3]!.trim().replace(/^['"]|['"]$/g, '');
      // Evaluate condition directly (not re-wrapped in {{}})
      return this.evaluateBoolean(condition) ? trueVal : falseVal;
    }

    // Inside {{...}} context: treat expression as a variable path; missing → ''
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

    // Equality: coerce both sides to string
    const leftStr = String(leftVal ?? '');
    const rightStr = String(rightVal ?? '');
    return operator === '==' ? leftStr === rightStr : leftStr !== rightStr;
  }

  private _resolveOperand(raw: string): unknown {
    // Template variable: {{varName}}
    const templateMatch = /^\{\{([^}]+)\}\}$/.exec(raw);
    if (templateMatch) {
      return this._getVariable(templateMatch[1]!.trim()) ?? '';
    }
    // Quoted string (single or double quotes)
    if (
      (raw.startsWith('"') && raw.endsWith('"')) ||
      (raw.startsWith("'") && raw.endsWith("'"))
    ) {
      return raw.slice(1, -1);
    }
    // Number
    const num = parseFloat(raw);
    if (!isNaN(num) && String(num) === raw) return num;
    // Boolean literal
    if (raw === 'true') return true;
    if (raw === 'false') return false;
    // Bare variable name (no template syntax)
    const varValue = this._getVariable(raw);
    if (varValue !== undefined) return varValue;
    // Unquoted string literal
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
