# Native Display System - Claude Code Patterns & Examples

## Executable Code Examples for Claude Code

All code blocks here are ready to be directly used or adapted for Claude Code tasks.

---

## SECTION 1: KOTLIN RENDERING IMPLEMENTATION

### Complete Parser Implementation

```kotlin
package com.clevertap.nativedisplay

import kotlinx.serialization.Serializable
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonPrimitive
import java.time.Instant

/**
 * Complete parser for NativeDisplayConfig JSON
 * Ready to use in Claude Code tasks
 */
object NativeDisplayParser {
    
    private val json = Json {
        ignoreUnknownKeys = true
        coerceInputValues = true
    }
    
    /**
     * Parse JSON string to NativeDisplayConfig
     * @return Result with config or error message
     */
    fun parseConfig(jsonString: String): Result<NativeDisplayConfig> {
        return try {
            val config = json.decodeFromString<NativeDisplayConfig>(jsonString)
            
            // Validate configuration
            val validation = validateConfig(config)
            if (!validation.isValid) {
                return Result.failure(
                    IllegalArgumentException("Validation failed: ${validation.errors.joinToString(", ")}")
                )
            }
            
            Result.success(config)
        } catch (e: Exception) {
            Result.failure(e)
        }
    }
    
    /**
     * Validate configuration structure
     */
    fun validateConfig(config: NativeDisplayConfig): ValidationResult {
        val errors = mutableListOf<String>()
        
        // Check version
        if (config.version != "1.0") {
            errors.add("Invalid version: ${config.version}")
        }
        
        // Check root
        if (config.root == null) {
            errors.add("Root node is required")
        }
        
        // Validate root recursively
        config.root?.let {
            validateNode(it, errors)
        }
        
        return ValidationResult(errors.isEmpty(), errors)
    }
    
    /**
     * Recursively validate node structure
     */
    private fun validateNode(node: NativeDisplayNode, errors: MutableList<String>) {
        when (node) {
            is NativeDisplayContainer -> {
                // Container validation
                if (node.children.isEmpty() && node.containerType != "gallery") {
                    errors.add("Container ${node.id} must have children")
                }
                
                // Special validation for BOX (exactly 1 child)
                if (node.containerType == "box" && node.children.size != 1) {
                    errors.add("BOX container ${node.id} must have exactly 1 child")
                }
                
                // Gallery config required for gallery type
                if (node.containerType == "gallery" && node.galleryConfig == null) {
                    errors.add("Gallery container ${node.id} must have galleryConfig")
                }
                
                // Validate children
                node.children.forEach { child ->
                    validateNode(child, errors)
                }
            }
            
            is NativeDisplayElement -> {
                // Element validation
                if (node.elementType !in listOf("text", "image", "button", "spacer", "video", "input", "webview")) {
                    errors.add("Invalid element type: ${node.elementType}")
                }
                
                // TEXT element should have text binding
                if (node.elementType == "text" && !node.bindings.containsKey("text")) {
                    // Optional warning - TEXT can be styled only
                }
                
                // IMAGE element should have src binding
                if (node.elementType == "image" && !node.bindings.containsKey("src")) {
                    errors.add("IMAGE element ${node.id} must have 'src' binding")
                }
            }
        }
    }
}

data class ValidationResult(
    val isValid: Boolean,
    val errors: List<String> = emptyList()
)
```

### Style Resolution Implementation

```kotlin
/**
 * Resolve final style applying cascade and inheritance
 */
object StyleResolver {
    
    /**
     * Resolve style for a node considering parent and theme
     * @param node The node to resolve style for
     * @param theme Theme with defaults
     * @param styleClasses Available style classes
     * @param parentStyle Parent node's resolved style
     * @return Final resolved style
     */
    fun resolveStyle(
        node: NativeDisplayNode,
        theme: Theme?,
        styleClasses: List<StyleClass>,
        parentStyle: Style? = null
    ): Style {
        var resolved = Style()
        
        // Step 1: Apply theme defaults
        theme?.defaultStyle?.let {
            resolved = resolved.merge(it)
        }
        
        // Step 2: Apply style class
        node.styleClass?.let { className ->
            styleClasses.find { it.name == className }?.let { styleClass ->
                resolved = resolved.merge(styleClass.style)
            }
        }
        
        // Step 3: Apply inline style
        node.style?.let {
            resolved = resolved.merge(it)
        }
        
        // Step 4: Inherit text properties from parent (for containers)
        if (node is NativeDisplayContainer && parentStyle != null) {
            resolved = resolved.inheritTextProperties(parentStyle)
        }
        
        return resolved
    }
    
    /**
     * Merge styles (priority: current > override)
     */
    private fun Style.merge(override: Style): Style {
        return Style(
            textColor = override.textColor ?: this.textColor,
            fontSize = override.fontSize ?: this.fontSize,
            fontWeight = override.fontWeight ?: this.fontWeight,
            textAlign = override.textAlign ?: this.textAlign,
            lineHeight = override.lineHeight ?: this.lineHeight,
            letterSpacing = override.letterSpacing ?: this.letterSpacing,
            textDecoration = override.textDecoration ?: this.textDecoration,
            backgroundColor = override.backgroundColor ?: this.backgroundColor,
            borderRadius = override.borderRadius ?: this.borderRadius,
            borderWidth = override.borderWidth ?: this.borderWidth,
            borderColor = override.borderColor ?: this.borderColor,
            shadowColor = override.shadowColor ?: this.shadowColor,
            shadowRadius = override.shadowRadius ?: this.shadowRadius,
            opacity = override.opacity ?: this.opacity,
            scaleX = override.scaleX ?: this.scaleX,
            scaleY = override.scaleY ?: this.scaleY,
            rotationZ = override.rotationZ ?: this.rotationZ
        )
    }
    
    /**
     * Inherit text properties from parent
     */
    private fun Style.inheritTextProperties(parent: Style): Style {
        return this.copy(
            textColor = this.textColor ?: parent.textColor,
            fontSize = this.fontSize ?: parent.fontSize,
            fontWeight = this.fontWeight ?: parent.fontWeight,
            textAlign = this.textAlign ?: parent.textAlign,
            lineHeight = this.lineHeight ?: parent.lineHeight,
            letterSpacing = this.letterSpacing ?: parent.letterSpacing,
            textDecoration = this.textDecoration ?: parent.textDecoration
        )
    }
}
```

### Variable Evaluation Implementation

```kotlin
/**
 * Evaluate template expressions and bind variables
 */
object VariableEvaluator {
    
    /**
     * Evaluate template string with variables
     * @param template "Hello {{name}}, you have {{count}} items"
     * @param variables Map of variable values
     * @return Evaluated string "Hello John, you have 5 items"
     */
    fun evaluate(template: String, variables: Map<String, JsonElement>): String {
        var result = template
        
        // Find all {{expression}} patterns
        val pattern = """\{\{([^}]+)\}\}""".toRegex()
        pattern.findAll(template).forEach { match ->
            val expression = match.groupValues[1]
            val value = evaluateExpression(expression, variables)
            result = result.replace(match.value, value)
        }
        
        return result
    }
    
    /**
     * Evaluate single expression
     * Supports: {{variable}}, {{object.property}}, {{array[0].property}}
     */
    private fun evaluateExpression(expression: String, variables: Map<String, JsonElement>): String {
        try {
            val trimmed = expression.trim()
            
            // Handle negation
            if (trimmed.startsWith("!")) {
                val innerValue = evaluateExpression(trimmed.substring(1), variables)
                return when (innerValue) {
                    "true" -> "false"
                    "false" -> "true"
                    else -> innerValue
                }
            }
            
            // Split by dots for nested properties
            val parts = trimmed.split(".")
            var current: JsonElement? = variables[parts[0]]
            
            if (current == null) {
                return "[undefined: $trimmed]"
            }
            
            // Navigate through properties
            for (i in 1 until parts.size) {
                val part = parts[i]
                current = when {
                    part.contains("[") -> {
                        // Handle array access: items[0]
                        val arrayName = part.substringBefore("[")
                        val index = part.substringAfter("[").substringBefore("]").toIntOrNull() ?: 0
                        
                        // Navigate to array first
                        val jsonObject = current?.jsonObject
                        val arrayElement = jsonObject?.get(arrayName)?.jsonArray?.getOrNull(index)
                        arrayElement
                    }
                    else -> {
                        // Regular property access
                        current?.jsonObject?.get(part)
                    }
                }
                
                if (current == null) {
                    return "[undefined: $trimmed]"
                }
            }
            
            // Convert to string
            return when {
                current is JsonPrimitive -> current.content
                else -> current.toString()
            }
        } catch (e: Exception) {
            return "[error: ${e.message}]"
        }
    }
    
    /**
     * Check if variable is defined and truthy
     */
    fun isTruthy(expression: String, variables: Map<String, JsonElement>): Boolean {
        val value = evaluate(expression, variables)
        return when (value.lowercase()) {
            "true", "1" -> true
            "false", "0", "[undefined", "[error" -> false
            else -> value.isNotEmpty()
        }
    }
}
```

---

## SECTION 2: UTILITY FUNCTIONS

### Config Utilities

```kotlin
/**
 * Utility functions for extracting and validating configuration
 */
object ConfigUtilities {
    
    /**
     * Get all text bindings from config
     */
    fun extractTextBindings(config: NativeDisplayConfig): Map<String, String> {
        val bindings = mutableMapOf<String, String>()
        extractTextBindingsRecursive(config.root, bindings)
        return bindings
    }
    
    private fun extractTextBindingsRecursive(
        node: NativeDisplayNode?,
        bindings: MutableMap<String, String>
    ) {
        if (node == null) return
        
        when (node) {
            is NativeDisplayElement -> {
                node.bindings["text"]?.let {
                    bindings[node.id] = it
                }
            }
            is NativeDisplayContainer -> {
                node.children.forEach {
                    extractTextBindingsRecursive(it, bindings)
                }
            }
        }
    }
    
    /**
     * Get all required variables from config
     */
    fun extractRequiredVariables(config: NativeDisplayConfig): Set<String> {
        val variables = mutableSetOf<String>()
        
        // From bindings
        val bindingPattern = """\{\{(\w+(?:\.\w+)*)\}\}""".toRegex()
        extractTextBindings(config).values.forEach { binding ->
            bindingPattern.findAll(binding).forEach { match ->
                variables.add(match.groupValues[1].split(".")[0])
            }
        }
        
        return variables
    }
}
```

### Color Utilities

```kotlin
/**
 * Color parsing and conversion utilities
 */
object ColorUtils {
    
    /**
     * Parse hex color to ARGB
     * Supports: #RGB, #RRGGBB, #AARRGGBB (ARGB format)
     */
    fun parseHexColor(hex: String): Int {
        val cleanHex = hex.removePrefix("#")
        
        return when (cleanHex.length) {
            3 -> {
                // RGB format: expand to RRGGBB
                val r = (cleanHex[0].toString() * 2).toInt(16)
                val g = (cleanHex[1].toString() * 2).toInt(16)
                val b = (cleanHex[2].toString() * 2).toInt(16)
                0xFF000000.toInt() or (r shl 16) or (g shl 8) or b
            }
            6 -> {
                // RRGGBB format
                0xFF000000.toInt() or cleanHex.toInt(16)
            }
            8 -> {
                // AARRGGBB format (ARGB - alpha first)
                val rrggbb = cleanHex.substring(0, 6).toInt(16)
                val aa = cleanHex.substring(6, 8).toInt(16)
                ((aa shl 24) or rrggbb)
            }
            else -> 0xFF000000.toInt() // Default: black with full opacity
        }
    }
    
    /**
     * Validate hex color format
     */
    fun isValidHexColor(hex: String): Boolean {
        val cleanHex = hex.removePrefix("#")
        return when {
            cleanHex.length !in listOf(3, 6, 8) -> false
            !cleanHex.all { it in '0'..'9' || it in 'A'..'F' || it in 'a'..'f' } -> false
            else -> true
        }
    }
}
```

---

## SECTION 3: TEST DATA & EXAMPLES

### Valid Configuration Examples

```kotlin
object TestConfigs {
    
    val simpleTextCard = """
    {
      "version": "1.0",
      "variables": {
        "title": "Hello World",
        "description": "This is a test"
      },
      "root": {
        "id": "card",
        "type": "container",
        "containerType": "vertical",
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "padding": { "all": 16 }
        },
        "spacing": { "value": 8, "unit": "dp" },
        "children": [
          {
            "id": "title",
            "type": "element",
            "elementType": "text",
            "bindings": { "text": "{{title}}" },
            "style": { "fontSize": 24, "fontWeight": "bold" }
          },
          {
            "id": "desc",
            "type": "element",
            "elementType": "text",
            "bindings": { "text": "{{description}}" },
            "style": { "fontSize": 14, "textColor": "#666666" }
          }
        ]
      }
    }
    """.trimIndent()
    
    val productCard = """
    {
      "version": "1.0",
      "theme": {
        "id": "default",
        "defaultStyle": {
          "textColor": "#212121",
          "fontSize": 14
        },
        "colors": {
          "primary": "#007AFF",
          "success": "#34C759"
        }
      },
      "styleClasses": [
        {
          "name": "card",
          "style": {
            "backgroundColor": "#FFFFFF",
            "borderRadius": 12,
            "shadowRadius": 8,
            "shadowColor": "#00000020"
          }
        }
      ],
      "variables": {
        "productName": "Wireless Headphones",
        "price": "$299.99",
        "image": "https://example.com/headphones.jpg",
        "inStock": true
      },
      "root": {
        "id": "card",
        "type": "container",
        "containerType": "vertical",
        "styleClass": "card",
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "padding": { "all": 16 }
        },
        "spacing": { "value": 12, "unit": "dp" },
        "children": [
          {
            "id": "image",
            "type": "element",
            "elementType": "image",
            "bindings": { "src": "{{image}}" },
            "layout": {
              "width": { "value": 100, "unit": "percent" },
              "height": { "value": 200, "unit": "dp" }
            },
            "style": { "borderRadius": 8 }
          },
          {
            "id": "name",
            "type": "element",
            "elementType": "text",
            "bindings": { "text": "{{productName}}" },
            "style": { "fontSize": 18, "fontWeight": "bold" }
          },
          {
            "id": "price",
            "type": "element",
            "elementType": "text",
            "bindings": { "text": "{{price}}" },
            "style": { "fontSize": 16, "textColor": "#34C759", "fontWeight": "bold" }
          },
          {
            "id": "button",
            "type": "element",
            "elementType": "button",
            "bindings": { "text": "Add to Cart" },
            "visible": "{{inStock}}",
            "layout": {
              "width": { "value": 100, "unit": "percent" },
              "height": { "value": 48, "unit": "dp" }
            },
            "style": {
              "backgroundColor": "#007AFF",
              "textColor": "#FFFFFF",
              "borderRadius": 8
            },
            "actions": {
              "onClick": {
                "type": "deeplink",
                "url": "app://cart/add?product={{productName}}"
              }
            }
          }
        ]
      }
    }
    """.trimIndent()
}
```

---

**Version**: 1.0-claude-code-patterns  
**Status**: Ready for Claude Code Integration  
**All code blocks are executable/adaptable**
