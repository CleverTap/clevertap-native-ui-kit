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
                if (node.elementType !in listOf("text", "image", "button", "video", "html", "spacer", "divider")) {
                    errors.add("Invalid element type: ${node.elementType}")
                }
                
                // TEXT element should have text binding
                if (node.elementType == "text" && !node.bindings.containsKey("text")) {
                    // Optional warning - TEXT can be styled only
                }
                
                // IMAGE element should have url binding
                if (node.elementType == "image" && !node.bindings.containsKey("url")) {
                    errors.add("IMAGE element ${node.id} must have 'url' binding")
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

### Property Extraction Patterns

#### Using Property Extraction in Renderer (Android)

```kotlin
/**
 * Pattern: Rendering TEXT element with property extraction
 * Use this when rendering text elements for better code organization
 */
@Composable
fun RenderTextElement(
    element: NativeDisplayElement,
    resolvedStyle: Style,
    evaluator: VariableEvaluator
) {
    // Extract text properties as a group
    val textProps = resolvedStyle.extractTextProperties()

    val text = element.bindings["text"]?.let {
        evaluator.evaluateString(it)
    } ?: ""

    Text(
        text = text,
        color = parseColor(textProps.color) ?: Color.Black,
        fontSize = (textProps.size ?: 14f).sp,
        fontWeight = resolveFontWeight(textProps.weight),
        textDecoration = resolveTextDecoration(textProps.decoration),
        textAlign = resolveTextAlign(textProps.align),
        lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp
    )
}

/**
 * Pattern: Rendering BUTTON element
 * Use Box + elementModifier (NOT Material3 Button) to avoid the 40dp minimum height
 * enforced by ButtonDefaults. Click handling is done by applyClickable() in RenderNode,
 * not inline here — so ON_LONG_PRESS and ON_DOUBLE_TAP work the same as for all elements.
 * Text is centered (Alignment.Center) — conventional for buttons.
 */
@Composable
fun RenderButtonElement(
    element: NativeDisplayElement,
    resolvedStyle: Style,
    evaluator: VariableEvaluator,
    elementModifier: Modifier   // Includes sizing + padding; click applied upstream by applyClickable()
) {
    val textProps = resolvedStyle.extractTextProperties()

    val buttonText = element.bindings["text"]?.let {
        evaluator.evaluateString(it)
    } ?: "Button"

    Box(
        modifier = elementModifier,
        contentAlignment = Alignment.Center
    ) {
        Text(
            text = buttonText,
            color = parseColor(textProps.color) ?: Color.White,
            fontSize = (textProps.size ?: 16f).sp,
            fontWeight = resolveFontWeight(textProps.weight),
            fontStyle = resolveFontStyle(textProps.style),
            letterSpacing = (textProps.letterSpacing ?: 0f).sp,
            textDecoration = resolveTextDecoration(textProps.decoration),
            textAlign = resolveTextAlign(textProps.align),
            lineHeight = textProps.lineHeight?.sp ?: (textProps.size?.times(1.5f) ?: 21f).sp,
            maxLines = textProps.maxLines ?: Int.MAX_VALUE,
            overflow = resolveTextOverflow(textProps.overflow)
        )
    }
}

/**
 * Pattern: Applying decorations with property extraction
 * Use this for applying borders, shadows, backgrounds consistently
 */
@Composable
private fun Modifier.applyDecorations(style: Style): Modifier {
    var modifier = this

    // Extract property groups for better organization
    val borderProps = style.extractBorderProperties()
    val shadowProps = style.extractShadowProperties()
    val visualProps = style.extractVisualProperties()

    val shape = RoundedCornerShape((borderProps.radius ?: 0f).dp)

    // Apply shadow
    if (shadowProps.radius != null && shadowProps.radius > 0f) {
        modifier = modifier.shadow(
            elevation = shadowProps.radius.dp,
            shape = shape,
            spotColor = parseColor(shadowProps.color) ?: Color.Black.copy(alpha = 0.25f)
        )
    }

    // Apply clip
    if (borderProps.radius != null && borderProps.radius > 0f) {
        modifier = modifier.clip(shape)
    }

    // Apply background
    if (visualProps.background != null) {
        modifier = modifier.applyBackground(visualProps.background)
    } else if (visualProps.backgroundColor != null) {
        modifier = modifier.background(
            color = parseColor(visualProps.backgroundColor) ?: Color.Transparent,
            shape = shape
        )
    }

    // Apply border
    if (borderProps.width != null && borderProps.width > 0f) {
        modifier = modifier.border(
            width = borderProps.width.dp,
            color = parseColor(borderProps.color) ?: Color.Gray,
            shape = shape
        )
    }

    // Apply opacity
    visualProps.opacity?.let { opacity ->
        modifier = modifier.alpha(opacity.coerceIn(0f, 1f))
    }

    return modifier
}
```

#### Using Property Extraction in Renderer (iOS)

```swift
/**
 * Pattern: Rendering TEXT element with property extraction
 * Use this when rendering text elements in SwiftUI.
 *
 * Key requirement: for .multilineTextAlignment() to be visually effective the Text
 * must fill its allocated width. Without .frame(maxWidth: .infinity) a short Text
 * renders at its natural (narrow) width and alignment has no visible effect.
 * Exception: wrap_content TEXT — the element IS its text width, do not expand.
 */
@ViewBuilder
private func renderText() -> some View {
    let text = element.bindings["text"].map { evaluator.evaluateString($0) } ?? ""
    let textProps = resolvedStyle.extractTextProperties()
    let textAlignment = resolveTextAlign(textProps.align)
    let isWrapContent = element.layout?.width?.special == .wrapContent

    let frameAlignment: Alignment = {
        switch textAlignment {
        case .center:   return .center
        case .trailing: return .trailing
        default:        return .leading
        }
    }()

    let coreText = Text(text)
        .foregroundColor(ColorParser.parse(textProps.color) ?? .primary)
        .font(.system(size: textProps.size ?? 14))
        .fontWeight(resolveFontWeight(textProps.weight))
        .multilineTextAlignment(textAlignment)
        .lineSpacing(max(0, (textProps.lineHeight ?? 0) - (textProps.size ?? 14)))

    if isWrapContent {
        coreText.fixedSize(horizontal: false, vertical: true)
    } else {
        coreText
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity, alignment: frameAlignment)
    }
}

/**
 * Pattern: Rendering BUTTON element in SwiftUI
 * Use .buttonStyle(.plain) so DecorationModifier (applied in RenderNode) owns all
 * visual styling (background, border, corner radius). Do NOT apply manual .background /
 * .cornerRadius here — that would double-apply styles.
 * The label uses .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
 * so the tappable area fills the full allocated element bounds and text is centered.
 */
@ViewBuilder
private func renderButton() -> some View {
    let buttonText = element.bindings["text"].map { evaluator.evaluateString($0) } ?? "Button"
    let textProps = resolvedStyle.extractTextProperties()

    Button(action: {
        // ON_CLICK handled here; applyTappable() is skipped for BUTTON elements
        if let onClick = element.actions?[ActionTriggers.onClick] {
            actionHandler?.handleAction(onClick, nodeId: element.id, interactionType: .click)
        }
    }) {
        Text(buttonText)
            .foregroundColor(ColorParser.parse(textProps.color) ?? .white)
            .font(.system(size: textProps.size ?? 16))
            .fontWeight(resolveFontWeight(textProps.weight))
            .multilineTextAlignment(resolveTextAlign(textProps.align))
            .lineSpacing(max(0, (textProps.lineHeight ?? 0) - (textProps.size ?? 16)))
            .lineLimit(textProps.maxLines)
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
    }
    .buttonStyle(.plain)
}

/**
 * Pattern: Applying decorations with property extraction
 * Use this in ViewModifier for consistent decoration application
 */
struct DecorationModifier: ViewModifier {
    let style: Style

    func body(content: Content) -> some View {
        // Extract property groups for better code organization
        let borderProps = style.extractBorderProperties()
        let shadowProps = style.extractShadowProperties()
        let visualProps = style.extractVisualProperties()

        let cornerRadius = borderProps.radius ?? 0

        content
            // Apply background
            .background(
                Group {
                    if let background = visualProps.background {
                        BackgroundView(background: background)
                            .cornerRadius(cornerRadius)
                    } else if let bgColor = visualProps.backgroundColor {
                        ColorParser.parse(bgColor)
                            .cornerRadius(cornerRadius)
                    }
                }
            )
            // Apply clip
            .clipShape(RoundedRectangle(cornerRadius: cornerRadius))
            // Apply border
            .overlay(
                Group {
                    if let borderWidth = borderProps.width, borderWidth > 0 {
                        RoundedRectangle(cornerRadius: cornerRadius)
                            .stroke(
                                ColorParser.parse(borderProps.color) ?? .gray,
                                lineWidth: borderWidth
                            )
                    }
                }
            )
            // Apply shadow
            .shadow(
                color: shadowProps.radius ?? 0 > 0
                    ? (ColorParser.parse(shadowProps.color)?.opacity(0.25) ?? Color.black.opacity(0.15))
                    : .clear,
                radius: shadowProps.radius ?? 0,
                x: shadowProps.offsetX ?? 0,
                y: shadowProps.offsetY ?? 2
            )
            // Apply opacity
            .opacity(Double(visualProps.opacity ?? 1))
    }
}
```

#### When to Use Property Extraction

**✅ Use extraction methods when:**
- Rendering TEXT or BUTTON elements (multiple text properties needed)
- Applying decorations (borders, shadows, backgrounds together)
- Writing new element renderers
- Refactoring existing renderer code

**✅ Direct property access is fine for:**
- Style resolution and merging
- Checking a single property (e.g., `if style.opacity != nil`)
- Cases where only 1-2 properties are accessed

#### Benefits

- **Clearer code**: Property groups make intent obvious
- **Better organization**: Grouped access vs scattered individual accesses
- **Easier maintenance**: Adding properties to a group is clearer
- **No breaking changes**: JSON format unchanged, only internal improvement

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
            "bindings": { "url": "{{image}}" },
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
