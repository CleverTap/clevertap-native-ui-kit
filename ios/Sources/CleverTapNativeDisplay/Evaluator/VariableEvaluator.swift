// MARK: - Variable Evaluator
// Evaluates variable expressions in templates

import Foundation

/// Evaluates variable expressions in templates (Phase 1 - static variables).
///
/// Supports:
/// - Variable interpolation: {{userName}}
/// - Comparisons: {{itemCount > 0}}
/// - Ternary expressions: {{isPremium ? 'Premium' : 'Free'}}
///
/// Phase 2+ will add reactive state management.
class VariableEvaluator {

    private let variables: [String: AnyCodable]
    private static let templatePattern = try! NSRegularExpression(
        pattern: "\\{\\{([^}]+)\\}\\}",
        options: []
    )

    init(variables: [String: AnyCodable]) {
        self.variables = variables
    }
    
    /// Evaluate a string template, replacing {{expressions}} with values.
    ///
    /// Examples:
    /// - "Hello {{userName}}" → "Hello John"
    /// - "{{itemCount}} items" → "5 items"
    func evaluateString(_ template: String) -> String {
        var result = template
        let range = NSRange(template.startIndex..., in: template)
        
        let matches = Self.templatePattern.matches(in: template, options: [], range: range)
        
        // Process matches in reverse order to preserve indices
        for match in matches.reversed() {
            guard let expressionRange = Range(match.range(at: 1), in: template),
                  let fullRange = Range(match.range, in: template) else {
                continue
            }
            
            let expression = String(template[expressionRange]).trimmingCharacters(in: .whitespaces)
            let value = evaluateExpression(expression)
            result = result.replacingCharacters(in: fullRange, with: "\(value)")
        }
        
        return result
    }
    
    /// Evaluate a boolean expression.
    ///
    /// Examples:
    /// - "{{itemCount > 0}}" → true/false
    /// - "{{isPremium}}" → true/false
    func evaluateBoolean(_ expression: String) -> Bool {
        let cleaned = expression
            .trimmingCharacters(in: .whitespaces)
            .replacingOccurrences(of: "{{", with: "")
            .replacingOccurrences(of: "}}", with: "")
            .trimmingCharacters(in: .whitespaces)
        
        // Check for comparison operators
        if cleaned.contains(">=") {
            return evaluateComparison(cleaned, operator: ">=")
        } else if cleaned.contains("<=") {
            return evaluateComparison(cleaned, operator: "<=")
        } else if cleaned.contains(">") {
            return evaluateComparison(cleaned, operator: ">")
        } else if cleaned.contains("<") {
            return evaluateComparison(cleaned, operator: "<")
        } else if cleaned.contains("==") {
            return evaluateEquality(cleaned, operator: "==")
        } else if cleaned.contains("!=") {
            return evaluateEquality(cleaned, operator: "!=")
        }
        
        // Handle plain string literals "true" / "false" sent directly in bindings
        switch cleaned.lowercased() {
        case "true": return true
        case "false": return false
        default: break
        }

        // Fall back to variable lookup for {{variableName}} expressions
        if let value = getVariable(cleaned) {
            return asBool(value) ?? false
        }

        return false
    }
    
    /// Evaluate an expression to get its value.
    /// Supports ternary operator and variable lookup.
    private func evaluateExpression(_ expression: String) -> Any {
        // Check for ternary operator: condition ? trueValue : falseValue
        let ternaryPattern = try? NSRegularExpression(
            pattern: "(.+?)\\?(.+?):(.+)",
            options: []
        )
        
        if let regex = ternaryPattern {
            let range = NSRange(expression.startIndex..., in: expression)
            if let match = regex.firstMatch(in: expression, options: [], range: range) {
                if let conditionRange = Range(match.range(at: 1), in: expression),
                   let trueRange = Range(match.range(at: 2), in: expression),
                   let falseRange = Range(match.range(at: 3), in: expression) {
                    
                    let condition = String(expression[conditionRange]).trimmingCharacters(in: .whitespaces)
                    let trueValue = String(expression[trueRange])
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    let falseValue = String(expression[falseRange])
                        .trimmingCharacters(in: .whitespaces)
                        .trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
                    
                    return evaluateBoolean("{{\(condition)}}") ? trueValue : falseValue
                }
            }
        }
        
        // Simple variable lookup
        if let value = getVariable(expression) {
            return extractValue(value) ?? ""
        }
        
        return ""
    }
    
    /// Evaluate a comparison expression (>, <, >=, <=).
    private func evaluateComparison(_ expression: String, operator op: String) -> Bool {
        let parts = expression.components(separatedBy: op).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2,
              let left = getNumericValue(parts[0]),
              let right = getNumericValue(parts[1]) else {
            return false
        }
        
        switch op {
        case ">": return left > right
        case "<": return left < right
        case ">=": return left >= right
        case "<=": return left <= right
        default: return false
        }
    }
    
    /// Evaluate an equality expression (==, !=).
    private func evaluateEquality(_ expression: String, operator op: String) -> Bool {
        let parts = expression.components(separatedBy: op).map { $0.trimmingCharacters(in: .whitespaces) }
        guard parts.count == 2 else { return false }
        
        let left = getVariableValue(parts[0])
        let right = getVariableValue(parts[1])
        
        switch op {
        case "==": return isEqual(left, right)
        case "!=": return !isEqual(left, right)
        default: return false
        }
    }
    
    /// Get a variable from the map.
    private func getVariable(_ name: String) -> AnyCodable? {
        // Handle nested paths like "user.name"
        let parts = name.components(separatedBy: ".")
        guard let first = parts.first else { return nil }
        
        var current: Any? = variables[first]?.value
        
        for part in parts.dropFirst() {
            guard let dict = current as? [String: Any] else { return nil }
            current = dict[part]
        }
        
        if let value = current {
            return AnyCodable(value)
        }
        return nil
    }
    
    /// Get numeric value from variable or literal.
    private func getNumericValue(_ value: String) -> Double? {
        // Try as literal number
        if let number = Double(value) {
            return number
        }
        
        // Try as variable
        if let variable = getVariable(value) {
            return asDouble(variable)
        }
        
        return nil
    }
    
    /// Get value from variable or literal for equality comparison.
    private func getVariableValue(_ value: String) -> Any? {
        // Try as variable first
        if let variable = getVariable(value) {
            return extractValue(variable)
        }
        
        // Return as literal (removing quotes)
        return value.trimmingCharacters(in: CharacterSet(charactersIn: "'\""))
    }
    
    /// Extract the underlying value from AnyCodable.
    private func extractValue(_ codable: AnyCodable) -> Any? {
        return codable.value
    }
    
    /// Convert AnyCodable to Bool.
    private func asBool(_ codable: AnyCodable) -> Bool? {
        switch codable.value {
        case let bool as Bool:
            return bool
        case let int as Int:
            return int != 0
        case let string as String:
            return string.lowercased() == "true"
        default:
            return nil
        }
    }
    
    /// Convert AnyCodable to Double.
    private func asDouble(_ codable: AnyCodable) -> Double? {
        switch codable.value {
        case let int as Int:
            return Double(int)
        case let double as Double:
            return double
        case let string as String:
            return Double(string)
        default:
            return nil
        }
    }
    
    /// Check equality between two values.
    private func isEqual(_ lhs: Any?, _ rhs: Any?) -> Bool {
        switch (lhs, rhs) {
        case (nil, nil):
            return true
        case (let l as Bool, let r as Bool):
            return l == r
        case (let l as Int, let r as Int):
            return l == r
        case (let l as Double, let r as Double):
            return l == r
        case (let l as String, let r as String):
            return l == r
        case (let l as Int, let r as Double):
            return Double(l) == r
        case (let l as Double, let r as Int):
            return l == Double(r)
        default:
            return false
        }
    }
}
