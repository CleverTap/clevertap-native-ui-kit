# Scalable Architecture - Styles, Variables & Future State

## 🎯 Your Questions Answered

### Q1: Does nested structure work with themes/styles?
**✅ YES** - Actually works BETTER with proper design!

### Q2: Can we support variables without full state management?
**✅ YES** - Variables in Phase 1, state in Phase 2+

### Q3: Will this scale without breaking changes?
**✅ YES** - With proper architecture from day 1!

---

## 🎨 Part 1: Style System with Nesting

### Problem: Style Inheritance

With nested containers, we need to decide:
```
Container (fontSize: 16)
└── Container (???)
    └── Text (???)
```

**Should Text inherit fontSize=16 from root?**

### Solution: Cascading Styles (Like CSS)

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String,
    val theme: Theme,
    val styleClasses: List<StyleClass> = emptyList(),
    val root: NativeDisplayNode
)

// Style resolution context carries parent styles
data class StyleContext(
    val theme: Theme,
    val styleClasses: Map<String, StyleClass>,
    val inheritedStyle: Style? = null  // ← Parent's resolved style
)
```

### Cascading Properties

**Some properties cascade** (children inherit):
- ✅ `textColor`
- ✅ `fontSize`
- ✅ `fontFamily`
- ✅ `fontWeight`

**Some properties don't cascade** (container-only):
- ❌ `backgroundColor` (don't inherit)
- ❌ `borderRadius` (don't inherit)
- ❌ `shadowRadius` (don't inherit)
- ❌ `padding` (don't inherit)

### Implementation

```kotlin
class StyleResolver(
    private val theme: Theme,
    private val styleClasses: Map<String, StyleClass>
) {
    /**
     * Resolves style with inheritance
     * Priority: inline > styleClass > inherited > theme
     */
    fun resolve(
        node: NativeDisplayNode,
        inheritedStyle: Style? = null
    ): ResolvedStyle {
        val classStyle = node.styleClass?.let { styleClasses[it]?.style }
        
        return merge(
            base = theme.defaultStyle,
            inherited = inheritedStyle,      // ← From parent
            override1 = classStyle,
            override2 = node.style
        )
    }
    
    private fun merge(
        base: Style,
        inherited: Style?,
        override1: Style?,
        override2: Style?
    ): Style {
        return Style(
            // Cascading properties (inherit from parent)
            textColor = override2?.textColor 
                ?: override1?.textColor 
                ?: inherited?.textColor      // ← Inherit!
                ?: base.textColor,
                
            fontSize = override2?.fontSize 
                ?: override1?.fontSize 
                ?: inherited?.fontSize        // ← Inherit!
                ?: base.fontSize,
                
            // Non-cascading properties (container-specific)
            backgroundColor = override2?.backgroundColor 
                ?: override1?.backgroundColor 
                // ← NO inherited here!
                ?: base.backgroundColor,
                
            borderRadius = override2?.borderRadius 
                ?: override1?.borderRadius 
                // ← NO inherited here!
                ?: base.borderRadius
        )
    }
}
```

### Rendering with Inheritance

```kotlin
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    resolver: StyleResolver,
    parentStyle: Style? = null  // ← Pass parent's style
) {
    when (node) {
        is NativeDisplayContainer -> {
            val style = resolver.resolve(node, parentStyle)
            
            Box(modifier = Modifier.applyStyle(style)) {
                // Render children with THIS container's style
                node.children.forEach { child ->
                    RenderNode(child, resolver, style)  // ← Pass style down
                }
            }
        }
        is NativeDisplayElement -> {
            val style = resolver.resolve(node, parentStyle)
            RenderElement(node, style)
        }
    }
}
```

### Example: Style Inheritance

```json
{
  "theme": {
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14
    }
  },
  "root": {
    "type": "container",
    "style": {
      "fontSize": 18,
      "backgroundColor": "#F0F0F0"
    },
    "children": [
      {
        "type": "container",
        "style": {
          "backgroundColor": "#FFFFFF"
        },
        "children": [
          {
            "type": "element",
            "elementType": "text",
            "content": { "text": "This text" }
          }
        ]
      }
    ]
  }
}
```

**Resolution**:
```
Root Container:
  fontSize: 18 (from inline)
  backgroundColor: #F0F0F0 (from inline)

Inner Container:
  fontSize: 18 (inherited from parent!)
  backgroundColor: #FFFFFF (from inline, NOT inherited)

Text Element:
  fontSize: 18 (inherited from ancestors!)
  textColor: #000000 (from theme)
```

**✅ This works perfectly with nested structure!**

---

## 🔄 Part 2: Variables & Reactivity (Phase 1)

### Concept: Variables WITHOUT State Management

```json
{
  "version": "1.0",
  "variables": {
    "userName": "John Doe",
    "itemCount": 5,
    "isPremium": true,
    "discount": 20
  },
  "root": {
    "children": [
      {
        "type": "element",
        "elementType": "text",
        "content": {
          "text": "Hello {{userName}}!"
        }
      },
      {
        "type": "element",
        "elementType": "text",
        "content": {
          "text": "You have {{itemCount}} items"
        },
        "visible": "{{itemCount > 0}}"
      },
      {
        "type": "element",
        "elementType": "text",
        "content": {
          "text": "{{isPremium ? 'Premium Member' : 'Free Member'}}"
        },
        "style": {
          "textColor": "{{isPremium ? '#FFD700' : '#000000'}}"
        }
      }
    ]
  }
}
```

### Data Model

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String,
    val variables: Map<String, JsonElement> = emptyMap(),  // ← Variables
    val theme: Theme,
    val root: NativeDisplayNode
)
```

### Variable Evaluation Engine

```kotlin
class VariableEvaluator(
    private val variables: Map<String, Any>
) {
    /**
     * Evaluates a string with variable placeholders
     * Example: "Hello {{userName}}" → "Hello John Doe"
     */
    fun evaluateString(template: String): String {
        var result = template
        
        // Replace {{variableName}} with actual value
        val pattern = Regex("\\{\\{([^}]+)\\}\\}")
        pattern.findAll(template).forEach { match ->
            val expression = match.groupValues[1].trim()
            val value = evaluateExpression(expression)
            result = result.replace(match.value, value.toString())
        }
        
        return result
    }
    
    /**
     * Evaluates a boolean expression
     * Example: "{{itemCount > 0}}" → true/false
     */
    fun evaluateBoolean(expression: String): Boolean {
        val cleaned = expression.replace("{{", "").replace("}}", "").trim()
        return evaluateExpression(cleaned) as? Boolean ?: false
    }
    
    /**
     * Simple expression evaluator
     * Phase 1: Support basic operations
     * Phase 2+: Use full expression library
     */
    private fun evaluateExpression(expr: String): Any {
        // Simple variable lookup
        if (!expr.contains(" ")) {
            return variables[expr] ?: ""
        }
        
        // Ternary operator: condition ? trueValue : falseValue
        if (expr.contains("?") && expr.contains(":")) {
            val parts = expr.split("?")
            val condition = evaluateBoolean("{{${parts[0].trim()}}}")
            val values = parts[1].split(":")
            return if (condition) {
                values[0].trim().removeSurrounding("'")
            } else {
                values[1].trim().removeSurrounding("'")
            }
        }
        
        // Comparison operators
        when {
            expr.contains(">") -> {
                val (left, right) = expr.split(">").map { it.trim() }
                val leftVal = (variables[left] as? Number)?.toDouble() ?: 0.0
                val rightVal = right.toDoubleOrNull() ?: 0.0
                return leftVal > rightVal
            }
            expr.contains("<") -> {
                val (left, right) = expr.split("<").map { it.trim() }
                val leftVal = (variables[left] as? Number)?.toDouble() ?: 0.0
                val rightVal = right.toDoubleOrNull() ?: 0.0
                return leftVal < rightVal
            }
        }
        
        return ""
    }
}
```

### Rendering with Variables

```kotlin
@Composable
fun RenderNode(
    node: NativeDisplayNode,
    evaluator: VariableEvaluator,
    resolver: StyleResolver
) {
    // Check visibility condition
    if (!isVisible(node, evaluator)) {
        return  // Don't render
    }
    
    when (node) {
        is NativeDisplayElement -> {
            // Evaluate content variables
            val evaluatedContent = node.content.mapValues { (_, value) ->
                evaluator.evaluateString(value)
            }
            
            RenderElement(node.copy(content = evaluatedContent))
        }
        // ... container handling
    }
}

fun isVisible(node: NativeDisplayNode, evaluator: VariableEvaluator): Boolean {
    val visibleExpr = node.visible ?: return true
    return evaluator.evaluateBoolean(visibleExpr)
}
```

### Phase 1: Static Variables

```kotlin
// Variables provided by backend, never change during display
val config = NativeDisplayConfig(
    variables = mapOf(
        "userName" to "John Doe",
        "itemCount" to 5
    ),
    root = ...
)

// Render once with these variables
NativeDisplayView(config)
```

**✅ No state management needed in Phase 1!**

---

## 🚀 Part 3: Future State Management (Phase 2+)

### Phase 2: Reactive Variables

Variables that can change during display:

```kotlin
// Phase 2: State management
class NativeDisplayViewModel {
    private val _variables = MutableStateFlow<Map<String, Any>>(emptyMap())
    val variables: StateFlow<Map<String, Any>> = _variables
    
    fun updateVariable(name: String, value: Any) {
        _variables.value = _variables.value + (name to value)
    }
}

@Composable
fun NativeDisplayView(
    config: NativeDisplayConfig,
    viewModel: NativeDisplayViewModel
) {
    val variables by viewModel.variables.collectAsState()
    val evaluator = remember(variables) { VariableEvaluator(variables) }
    
    // UI automatically re-renders when variables change!
    RenderNode(config.root, evaluator, resolver)
}
```

### Phase 3: Actions Update Variables

```json
{
  "type": "element",
  "elementType": "button",
  "content": { "text": "Add Item" },
  "actions": {
    "onClick": {
      "type": "updateVariable",
      "variable": "itemCount",
      "operation": "increment"
    }
  }
}
```

---

## 📐 Part 4: Scalability Analysis

### Current Structure

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String,
    val variables: Map<String, JsonElement> = emptyMap(),
    val theme: Theme,
    val styleClasses: List<StyleClass> = emptyList(),
    val root: NativeDisplayNode
)

@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    abstract val visible: String?  // ← Expression for visibility
}
```

### ✅ Will This Scale?

#### Phase 1: Static Variables
```json
{
  "variables": { "userName": "John" },
  "root": {
    "children": [
      {
        "content": { "text": "Hello {{userName}}" }
      }
    ]
  }
}
```
**✅ Supported!** Just template string replacement.

#### Phase 2: Reactive Variables
```kotlin
// Same JSON schema!
// Just add StateFlow/Compose State
val variables = remember { mutableStateOf(initialVariables) }
```
**✅ No schema changes needed!**

#### Phase 3: User Interactions
```json
{
  "type": "element",
  "elementType": "button",
  "actions": {
    "onClick": {
      "type": "updateVariable",
      "variable": "count",
      "operation": "increment"
    }
  }
}
```
**✅ Just add `actions` property!** No breaking changes.

#### Phase 4: Animations
```json
{
  "type": "element",
  "animation": {
    "type": "fadeIn",
    "duration": 300
  }
}
```
**✅ Just add `animation` property!** No breaking changes.

---

## 🎯 Scalability Guarantees

### 1. Backward Compatibility ✅

```kotlin
@Serializable
data class NativeDisplayNode(
    // Required fields
    val id: String,
    val type: String,
    
    // Optional fields (can add without breaking)
    val layout: Layout? = null,
    val style: Style? = null,
    val styleClass: String? = null,
    val visible: String? = null,      // Phase 1
    val actions: Map<String, Action>? = null,  // Phase 3
    val animation: Animation? = null  // Phase 4
)
```

**Adding optional properties = NO breaking changes!**

### 2. Version Field ✅

```json
{
  "version": "1.0",  // ← Explicit version
  "root": { }
}
```

### 3. Feature Detection ✅

```kotlin
// Check if features are supported
if (config.root.actions != null) {
    // Phase 3+ feature
}
```

---

## 📊 Phased Rollout Plan

### Phase 1: Static UI with Variables ✅
**Target**: Q1 2025

Features:
- ✅ Nested containers
- ✅ Style system with inheritance
- ✅ Static variables (`{{variableName}}`)
- ✅ Conditional visibility (`visible: "{{expr}}"`)
- ✅ Ternary expressions (`{{condition ? a : b}}`)

### Phase 2: Reactive Variables
**Target**: Q2 2025

Features:
- ✅ Variables change during display
- ✅ UI auto-updates
- ✅ No schema changes!

### Phase 3: User Interactions
**Target**: Q3 2025

Features:
- ✅ onClick, onLongPress actions
- ✅ Update variables from UI

---

## ✅ Summary: All Your Concerns Addressed

### Q1: Style System with Nesting
**✅ SOLVED**:
- Style inheritance (cascading properties)
- Theme works at any nesting level
- StyleClass resolution unchanged

### Q2: Variables Without State Management
**✅ SOLVED**:
- Phase 1: Static variables with template strings
- Variables in JSON config
- Simple expression evaluation
- Easy upgrade path to reactive variables

### Q3: Scalability
**✅ GUARANTEED**:
- Optional properties = no breaking changes
- Version field for format evolution
- Feature detection built-in
- Clear phased rollout plan

---

## 🎯 Recommended Data Model (Final)

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String = "1.0",
    val variables: Map<String, JsonElement> = emptyMap(),
    val theme: Theme,
    val styleClasses: List<StyleClass> = emptyList(),
    val root: NativeDisplayNode
)

@Serializable
sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    abstract val visible: String?
    abstract val actions: Map<String, Action>?
    abstract val animation: Animation?
}

@Serializable
@SerialName("container")
data class NativeDisplayContainer(
    override val id: String,
    val containerType: ContainerType,
    val children: List<NativeDisplayNode>,
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val actions: Map<String, Action>? = null,
    override val animation: Animation? = null
) : NativeDisplayNode()

@Serializable
@SerialName("element")
data class NativeDisplayElement(
    override val id: String,
    val elementType: ElementType,
    val content: Map<String, String> = emptyMap(),
    override val layout: Layout? = null,
    override val style: Style? = null,
    override val styleClass: String? = null,
    override val visible: String? = null,
    override val actions: Map<String, Action>? = null,
    override val animation: Animation? = null
) : NativeDisplayNode()
```

---

## 🚀 Next Steps

1. ✅ Nested structure is correct
2. ✅ Add style inheritance
3. ✅ Add variable support
4. ✅ Start with Phase 1
5. ✅ Plan for future phases

**Your architecture is solid and will scale!** 🎉
