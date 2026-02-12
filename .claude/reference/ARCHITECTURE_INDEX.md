# Architecture Documentation - Download Guide

## 📦 All Documents Ready for Download!

I've created **5 comprehensive architecture documents** for your project. All are now available in the outputs directory.

---

## 📄 Document List

### 1. ADAPTIVE_ARCHITECTURE.md ⭐ **Most Important**

**What it covers**:
- ✅ How to start with everything together (Phase 1)
- ✅ How to evolve to split APIs later (Phase 2+)
- ✅ Zero breaking changes migration path
- ✅ Universal data model that works for both
- ✅ Smart loader that auto-detects mode

**Key insight**: Build for monolithic JSON NOW, automatically support split APIs LATER with the same code!

**Size**: ~17KB, very detailed

**Use this**: As your main architecture reference

---

### 2. SCALABLE_ARCHITECTURE.md

**What it covers**:
- ✅ Style inheritance with nested containers
- ✅ Variables WITHOUT state management (Phase 1)
- ✅ How to add reactive state later (Phase 2+)
- ✅ Future-proof data model design
- ✅ Phased rollout plan

**Key insight**: Cascading styles (like CSS) work perfectly with nesting. Variables start static, become reactive later.

**Size**: ~16KB

**Use this**: For understanding style system and variable system

---

### 3. TEMPLATE_DATA_EXAMPLE.md

**What it covers**:
- ✅ Complete real-world example (product card)
- ✅ Visual mockups showing rendered UI
- ✅ Full template JSON (200 lines)
- ✅ Multiple data sets (3 different products)
- ✅ 12 bindings example
- ✅ Bandwidth savings calculation (93%!)

**Key insight**: One template, many data sets. Layout IS in template, data is just values.

**Size**: ~20KB, lots of examples

**Use this**: To visualize how template + data work together

---

### 4. LAYOUT_IN_TEMPLATE_EXPLAINED.md

**What it covers**:
- ✅ Where layout information lives (in template!)
- ✅ What goes in template vs data
- ✅ How mobile app combines them
- ✅ Complete rendering process
- ✅ Visual breakdowns

**Key insight**: Template = blueprint (has all layout), Data = paint (just values)

**Size**: ~13KB

**Use this**: To understand the separation clearly

---

### 5. LAYOUT_CONTENT_SEPARATION.md

**What it covers**:
- ✅ 5 different approaches compared
- ✅ Pros and cons of each
- ✅ Comparison matrix
- ✅ Recommendations for your use case
- ✅ Discussion questions

**Key insight**: Multiple ways to separate concerns, each with trade-offs.

**Size**: ~14KB

**Use this**: To understand WHY we chose the adaptive approach

---

## 🎯 Quick Start Guide

### For Implementation (Read First)

1. **ADAPTIVE_ARCHITECTURE.md** ⭐
   - Your main reference
   - Shows exactly what to build
   - Phase 1 and Phase 2+ approach

2. **SCALABLE_ARCHITECTURE.md**
   - Style system details
   - Variable system details
   - Future state management

### For Understanding (Read Second)

3. **TEMPLATE_DATA_EXAMPLE.md**
   - Concrete example with visuals
   - See it all working together

4. **LAYOUT_IN_TEMPLATE_EXPLAINED.md**
   - Clarifies where layout lives
   - Step-by-step rendering process

### For Context (Optional)

5. **LAYOUT_CONTENT_SEPARATION.md**
   - Different approaches compared
   - Why we chose this design

---

## 📊 Key Decisions Summary

### Decision 1: Monolithic Now, Split Later ✅

**Phase 1** (Now):
```json
{
  "theme": { },
  "styleClasses": [ ],
  "variables": { },
  "root": { }
}
```

**Phase 2+** (Future):
```json
{
  "templateRef": { "templateId": "..." },
  "styleRef": { "styleId": "..." },
  "dataRef": { "url": "..." }
}
```

**Same mobile code works for both!**

---

### Decision 2: Nested Containers ✅

```
Container
├── Container (Card with shadow)
│   ├── Text
│   ├── Image
│   └── Container (Button row)
│       ├── Button 1
│       └── Button 2
└── Container (Footer)
```

**Unlimited nesting = maximum flexibility**

---

### Decision 3: Style Inheritance ✅

**Cascading properties** (like CSS):
- ✅ textColor, fontSize, fontWeight → Inherit down tree
- ❌ backgroundColor, borderRadius, shadowRadius → Don't inherit

**Priority**:
1. Inline style (highest)
2. Style class
3. Inherited from parent
4. Theme default (lowest)

---

### Decision 4: Variables (Static → Reactive) ✅

**Phase 1**: Static variables
```json
{
  "variables": { "userName": "John" },
  "root": {
    "bindings": { "text": "{{userName}}" }
  }
}
```

**Phase 2+**: Add StateFlow/Compose State
```kotlin
val variables = MutableStateFlow(initialVariables)
// UI auto-updates when variables change
```

**No schema changes needed!**

---

### Decision 5: Layout in Template ✅

**Template has**:
- ✅ Structure (what elements)
- ✅ Layout (sizes, spacing)
- ✅ Style (colors, fonts)
- ✅ Bindings (placeholders)

**Data has**:
- ✅ Values only
- ❌ No layout
- ❌ No style

---

## 🏗️ Data Model (Final)

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String = "1.0",
    
    // Phase 1: Inline (everything together)
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode? = null,
    
    // Phase 2+: References (split APIs)
    val templateRef: TemplateReference? = null,
    val styleRef: StyleReference? = null,
    val dataRef: DataReference? = null
)

sealed class NativeDisplayNode {
    abstract val id: String
    abstract val layout: Layout?
    abstract val style: Style?
    abstract val styleClass: String?
    abstract val visible: String?  // "{{expression}}"
}

data class NativeDisplayContainer(
    override val id: String,
    val containerType: ContainerType,  // VERTICAL, HORIZONTAL, BOX
    val children: List<NativeDisplayNode>,
    // ... layout, style, etc.
) : NativeDisplayNode()

data class NativeDisplayElement(
    override val id: String,
    val elementType: ElementType,  // TEXT, IMAGE, BUTTON, etc.
    val bindings: Map<String, String>,  // "text" → "userName"
    // ... layout, style, etc.
) : NativeDisplayNode()
```

---

## 🎨 Example JSON (Phase 1)

```json
{
  "version": "1.0",
  
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14
    }
  },
  
  "styleClasses": [
    {
      "name": "button-primary",
      "style": {
        "backgroundColor": "#007AFF",
        "textColor": "#FFFFFF"
      }
    }
  ],
  
  "variables": {
    "userName": "John Doe",
    "price": "$99.99"
  },
  
  "root": {
    "type": "container",
    "containerType": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 20, "unit": "dp" }
    },
    "children": [
      {
        "type": "element",
        "elementType": "text",
        "bindings": {
          "text": "{{userName}}"
        },
        "layout": {
          "width": { "value": 100, "unit": "percent" }
        },
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      },
      {
        "type": "element",
        "elementType": "button",
        "bindings": {
          "text": "Buy for {{price}}"
        },
        "styleClass": "button-primary"
      }
    ]
  }
}
```

---

## 📦 How to Use These Files

### Step 1: Download All Files

From the outputs panel in Claude:
- ADAPTIVE_ARCHITECTURE.md
- SCALABLE_ARCHITECTURE.md
- TEMPLATE_DATA_EXAMPLE.md
- LAYOUT_IN_TEMPLATE_EXPLAINED.md
- LAYOUT_CONTENT_SEPARATION.md

### Step 2: Copy to Your Project

```bash
cd /Users/lalitkumar/StudioProjects/clevertap-native-ui-kit

# Copy downloaded files
cp ~/Downloads/ADAPTIVE_ARCHITECTURE.md .
cp ~/Downloads/SCALABLE_ARCHITECTURE.md .
cp ~/Downloads/TEMPLATE_DATA_EXAMPLE.md .
cp ~/Downloads/LAYOUT_IN_TEMPLATE_EXPLAINED.md .
cp ~/Downloads/LAYOUT_CONTENT_SEPARATION.md .
```

### Step 3: Read in Order

1. ADAPTIVE_ARCHITECTURE.md (main reference)
2. SCALABLE_ARCHITECTURE.md (style & variables)
3. TEMPLATE_DATA_EXAMPLE.md (concrete example)

### Step 4: Start Coding!

You now have complete architecture documentation to build:
- ✅ Phase 1: Monolithic JSON
- ✅ Phase 2+: Split APIs (future-proof)
- ✅ Nested containers
- ✅ Style inheritance
- ✅ Variable system
- ✅ Zero breaking changes migration

---

## ✅ What You Have Now

| Document | Purpose | Size | Priority |
|----------|---------|------|----------|
| ADAPTIVE_ARCHITECTURE.md | Main implementation guide | 17KB | ⭐⭐⭐ Must read |
| SCALABLE_ARCHITECTURE.md | Style & variable systems | 16KB | ⭐⭐⭐ Must read |
| TEMPLATE_DATA_EXAMPLE.md | Complete working example | 20KB | ⭐⭐ Very helpful |
| LAYOUT_IN_TEMPLATE_EXPLAINED.md | Clarifies layout location | 13KB | ⭐ If confused |
| LAYOUT_CONTENT_SEPARATION.md | Design comparison | 14KB | ⭐ For context |

**Total**: 80KB of comprehensive documentation!

---

## 🚀 You're Ready to Build!

**Your architecture**:
- ✅ Starts simple (monolithic)
- ✅ Evolves gracefully (split APIs)
- ✅ Zero breaking changes
- ✅ Nested containers
- ✅ Style inheritance
- ✅ Variable system
- ✅ Future-proof

**Next step**: Download the files and start implementing! 🎉

---

## 📞 Quick Reference

### Phase 1 JSON (Everything Together)
```
theme + styleClasses + variables + root = Complete config
```

### Phase 2+ JSON (References)
```
templateRef + styleRef + dataRef = Fetch and combine
```

### Mobile Code
```
Same code works for both! (adaptive loader)
```

### Migration
```
Zero breaking changes! (optional fields)
```

---

**Download all files now and start building!** 🚀
