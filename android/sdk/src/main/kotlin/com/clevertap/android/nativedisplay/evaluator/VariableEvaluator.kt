package com.clevertap.android.nativedisplay.evaluator

import kotlinx.serialization.json.*

/**
 * Evaluates variable expressions in templates (Phase 1 - static variables).
 * 
 * Supports:
 * - Variable interpolation: {{userName}}
 * - Comparisons: {{itemCount > 0}}
 * - Ternary expressions: {{isPremium ? 'Premium' : 'Free'}}
 * 
 * Phase 2+ will add reactive state management.
 */
class VariableEvaluator(
    private val variables: Map<String, JsonElement>
) {
    companion object {
        private val TEMPLATE_PATTERN = Regex("\\{\\{([^}]+)\\}\\}")
    }
    
    /**
     * Evaluate a string template, replacing {{expressions}} with values.
     * 
     * Examples:
     * - "Hello {{userName}}" → "Hello John"
     * - "{{itemCount}} items" → "5 items"
     */
    fun evaluateString(template: String): String {
        var result = template
        
        TEMPLATE_PATTERN.findAll(template).forEach { match ->
            val expression = match.groupValues[1].trim()
            val value = evaluateExpression(expression)
            result = result.replace(match.value, value.toString())
        }
        
        return result
    }
    
    /**
     * Evaluate a boolean expression.
     * 
     * Examples:
     * - "{{itemCount > 0}}" → true/false
     * - "{{isPremium}}" → true/false
     */
    fun evaluateBoolean(expression: String): Boolean {
        val cleaned = expression.trim().removePrefix("{{").removeSuffix("}}").trim()
        
        return when {
            // Comparison operators
            cleaned.contains(">") -> evaluateComparison(cleaned, ">")
            cleaned.contains("<") -> evaluateComparison(cleaned, "<")
            cleaned.contains(">=") -> evaluateComparison(cleaned, ">=")
            cleaned.contains("<=") -> evaluateComparison(cleaned, "<=")
            cleaned.contains("==") -> evaluateEquality(cleaned, "==")
            cleaned.contains("!=") -> evaluateEquality(cleaned, "!=")
            
            // Direct boolean variable
            else -> {
                val value = getVariable(cleaned)
                when (value) {
                    is JsonPrimitive -> value.booleanOrNull ?: false
                    else -> false
                }
            }
        }
    }
    
    /**
     * Evaluate an expression to get its value.
     * Supports ternary operator and variable lookup.
     */
    private fun evaluateExpression(expression: String): Any {
        // Check for ternary operator: condition ? trueValue : falseValue
        val ternaryPattern = Regex("(.+?)\\?(.+?):(.+)")
        val ternaryMatch = ternaryPattern.matchEntire(expression)
        
        if (ternaryMatch != null) {
            val condition = ternaryMatch.groupValues[1].trim()
            val trueValue = ternaryMatch.groupValues[2].trim().removeSurrounding("'", "'")
            val falseValue = ternaryMatch.groupValues[3].trim().removeSurrounding("'", "'")
            
            return if (evaluateBoolean("{{$condition}}")) trueValue else falseValue
        }
        
        // Simple variable lookup
        val value = getVariable(expression)
        return when (value) {
            is JsonPrimitive -> {
                value.contentOrNull 
                    ?: value.intOrNull 
                    ?: value.doubleOrNull 
                    ?: value.booleanOrNull 
                    ?: ""
            }
            else -> ""
        }
    }
    
    /**
     * Evaluate a comparison expression (>, <, >=, <=).
     */
    private fun evaluateComparison(expression: String, operator: String): Boolean {
        val parts = expression.split(operator).map { it.trim() }
        if (parts.size != 2) return false
        
        val left = getNumericValue(parts[0])
        val right = getNumericValue(parts[1])
        
        if (left == null || right == null) return false
        
        return when (operator) {
            ">" -> left > right
            "<" -> left < right
            ">=" -> left >= right
            "<=" -> left <= right
            else -> false
        }
    }
    
    /**
     * Evaluate an equality expression (==, !=).
     */
    private fun evaluateEquality(expression: String, operator: String): Boolean {
        val parts = expression.split(operator).map { it.trim() }
        if (parts.size != 2) return false
        
        val left = getVariableValue(parts[0])
        val right = getVariableValue(parts[1])
        
        return when (operator) {
            "==" -> left == right
            "!=" -> left != right
            else -> false
        }
    }
    
    /**
     * Get a variable from the map.
     */
    private fun getVariable(name: String): JsonElement? {
        return variables[name]
    }
    
    /**
     * Get numeric value from variable or literal.
     */
    private fun getNumericValue(value: String): Double? {
        // Try as literal number
        value.toDoubleOrNull()?.let { return it }
        
        // Try as variable
        val variable = getVariable(value)
        if (variable is JsonPrimitive) {
            return variable.doubleOrNull ?: variable.intOrNull?.toDouble()
        }
        
        return null
    }
    
    /**
     * Get value from variable or literal for equality comparison.
     */
    private fun getVariableValue(value: String): Any? {
        // Try as variable first
        val variable = getVariable(value)
        if (variable is JsonPrimitive) {
            return variable.contentOrNull 
                ?: variable.intOrNull 
                ?: variable.doubleOrNull 
                ?: variable.booleanOrNull
        }
        
        // Return as literal
        return value.removeSurrounding("'", "'")
    }
}
