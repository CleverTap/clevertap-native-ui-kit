class VariableEvaluator {
  final Map<String, dynamic> variables;

  const VariableEvaluator(this.variables);

  static final _pattern = RegExp(r'\{\{([^}]+)\}\}');

  String evaluateString(String template) {
    return template.replaceAllMapped(_pattern, (match) {
      final expr = match.group(1)!.trim();
      return _evaluateExpr(expr)?.toString() ?? '';
    });
  }

  bool evaluateBoolean(String? expr) {
    if (expr == null) return true;
    if (expr == 'true') return true;
    if (expr == 'false') return false;
    final clean = expr.startsWith('{{') && expr.endsWith('}}')
        ? expr.substring(2, expr.length - 2).trim()
        : expr;
    return _evalBoolean(clean);
  }

  dynamic _evaluateExpr(String expr) {
    final ternary = _tryTernary(expr);
    if (ternary != null) return ternary;
    final comparison = _tryComparison(expr);
    if (comparison != null) return comparison;
    return _lookupVariable(expr);
  }

  bool _evalBoolean(String expr) {
    final result = _evaluateExpr(expr);
    if (result is bool) return result;
    if (result is String) return result.isNotEmpty && result != 'false';
    if (result is num) return result != 0;
    return false;
  }

  String? _tryTernary(String expr) {
    final qIdx = expr.indexOf('?');
    final cIdx = expr.lastIndexOf(':');
    if (qIdx < 0 || cIdx <= qIdx) return null;
    final condition = expr.substring(0, qIdx).trim();
    final trueVal = expr.substring(qIdx + 1, cIdx).trim().replaceAll("'", '');
    final falseVal = expr.substring(cIdx + 1).trim().replaceAll("'", '');
    return _evalBoolean(condition) ? trueVal : falseVal;
  }

  bool? _tryComparison(String expr) {
    for (final op in ['>=', '<=', '!=', '==', '>', '<']) {
      final idx = expr.indexOf(op);
      if (idx < 0) continue;
      final left = _lookupVariable(expr.substring(0, idx).trim());
      final right = _parseValue(expr.substring(idx + op.length).trim());
      final l = _toNum(left);
      final r = _toNum(right);
      if (l != null && r != null) {
        return switch (op) {
          '>=' => l >= r,
          '<=' => l <= r,
          '!=' => l != r,
          '==' => l == r,
          '>' => l > r,
          '<' => l < r,
          _ => null,
        };
      }
      return switch (op) {
        '==' => left?.toString() == right?.toString(),
        '!=' => left?.toString() != right?.toString(),
        _ => null,
      };
    }
    return null;
  }

  dynamic _lookupVariable(String name) {
    if (name.contains('.')) {
      final parts = name.split('.');
      dynamic current = variables[parts[0]];
      for (final part in parts.skip(1)) {
        if (current is Map) {
          current = current[part];
        } else {
          return null;
        }
      }
      return current;
    }
    return variables[name];
  }

  dynamic _parseValue(String s) {
    if (s.startsWith("'") && s.endsWith("'")) return s.substring(1, s.length - 1);
    return num.tryParse(s) ?? s;
  }

  num? _toNum(dynamic v) {
    if (v is num) return v;
    if (v is String) return num.tryParse(v);
    return null;
  }
}
