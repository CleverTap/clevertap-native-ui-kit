# Adaptive Architecture - Monolithic to Split APIs

## 🎯 Goal: Start Simple, Evolve Gracefully

### Phase 1 (Now)
Backend sends: **One JSON with everything**
```
Single API → { structure + layout + style + data }
```

### Phase 2+ (Future)
Backend can send: **Separate APIs**
```
Template API → { structure + layout + style }
Data API → { data values }
Style API → { themes + style classes }
```

**Key**: Same mobile code works for both! 🎉

---

## 📊 Phase 1: Current (Everything Together)

### JSON Structure

```json
{
  "version": "1.0",
  "id": "product-promo-123",
  "timestamp": "2024-01-15T10:30:00Z",
  
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14
    },
    "colors": {
      "primary": "#007AFF"
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
    "productName": "Wireless Headphones",
    "price": "$224.99",
    "discount": 25
  },
  
  "root": {
    "type": "container",
    "containerType": "vertical",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 20, "unit": "dp" }
    },
    "style": {
      "backgroundColor": "#F5F5F5"
    },
    "children": [
      {
        "type": "element",
        "elementType": "text",
        "bindings": {
          "text": "{{userName}}"
        },
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "height": { "value": 40, "unit": "dp" }
        },
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      },
      {
        "type": "element",
        "elementType": "text",
        "bindings": {
          "text": "{{productName}}"
        },
        "styleClass": "product-name"
      }
    ]
  }
}
```

**Characteristics**:
- ✅ Everything in one JSON
- ✅ Backend sends complete config
- ✅ Simple to implement
- ✅ Works today!

---

## 📊 Phase 2+: Future (Split APIs)

### API 1: Template (Structure + Layout)

**Endpoint**: `GET /api/templates/product-promo-v1`

```json
{
  "templateId": "product-promo-v1",
  "version": "1.0",
  "cacheTTL": 604800,
  
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
          "text": "userName"
        },
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "height": { "value": 40, "unit": "dp" }
        },
        "style": {
          "fontSize": 24,
          "fontWeight": "bold"
        }
      },
      {
        "type": "element",
        "elementType": "text",
        "bindings": {
          "text": "productName"
        },
        "styleClass": "product-name"
      }
    ]
  }
}
```

**Cached**: 7 days

---

### API 2: Style (Themes + Classes)

**Endpoint**: `GET /api/styles/default-theme-v1`

```json
{
  "styleId": "default-theme-v1",
  "version": "1.0",
  "cacheTTL": 604800,
  
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14
    },
    "colors": {
      "primary": "#007AFF"
    }
  },
  
  "styleClasses": [
    {
      "name": "button-primary",
      "style": {
        "backgroundColor": "#007AFF",
        "textColor": "#FFFFFF"
      }
    },
    {
      "name": "product-name",
      "style": {
        "fontSize": 20,
        "fontWeight": "bold"
      }
    }
  ]
}
```

**Cached**: 7 days

---

### API 3: Data (Just Values)

**Endpoint**: `GET /api/displays/product-promo-123/data`

```json
{
  "displayId": "product-promo-123",
  "templateId": "product-promo-v1",
  "styleId": "default-theme-v1",
  "timestamp": "2024-01-15T10:30:00Z",
  
  "values": {
    "userName": "John Doe",
    "productName": "Wireless Headphones",
    "price": "$224.99",
    "discount": 25
  }
}
```

**Not cached**: Fresh data every time

---

## 🏗️ Adaptive Data Model

### Universal Config (Works for Both!)

```kotlin
@Serializable
data class NativeDisplayConfig(
    val version: String = "1.0",
    
    // Phase 1: All inline (provided directly)
    val theme: Theme? = null,
    val styleClasses: List<StyleClass> = emptyList(),
    val variables: Map<String, JsonElement> = emptyMap(),
    val root: NativeDisplayNode,
    
    // Phase 2+: References to external resources (optional)
    val templateRef: TemplateReference? = null,
    val styleRef: StyleReference? = null,
    val dataRef: DataReference? = null
)

@Serializable
data class TemplateReference(
    val templateId: String,
    val version: String,
    val url: String? = null  // Optional direct URL
)

@Serializable
data class StyleReference(
    val styleId: String,
    val version: String,
    val url: String? = null
)

@Serializable
data class DataReference(
    val dataId: String,
    val url: String
)
```

---

## 🔄 How Mobile App Handles Both

### Universal Loader

```kotlin
class NativeDisplayLoader(
    private val templateCache: TemplateCache,
    private val styleCache: StyleCache,
    private val apiClient: ApiClient
) {
    suspend fun load(configJson: String): ResolvedConfig {
        val config = Json.decodeFromString<NativeDisplayConfig>(configJson)
        
        // Detect which mode we're in
        return when {
            // Phase 1: Everything inline
            config.isMonolithic() -> loadMonolithic(config)
            
            // Phase 2+: References to external resources
            config.hasReferences() -> loadSplit(config)
            
            else -> throw IllegalStateException("Invalid config")
        }
    }
    
    private suspend fun loadMonolithic(config: NativeDisplayConfig): ResolvedConfig {
        // Everything is already in the config!
        return ResolvedConfig(
            theme = config.theme!!,
            styleClasses = config.styleClasses,
            variables = config.variables,
            root = config.root
        )
    }
    
    private suspend fun loadSplit(config: NativeDisplayConfig): ResolvedConfig {
        // Fetch template (cached)
        val template = if (config.templateRef != null) {
            templateCache.getOrFetch(
                id = config.templateRef.templateId,
                url = config.templateRef.url ?: buildTemplateUrl(config.templateRef)
            )
        } else {
            // Fallback: use inline root
            TemplateData(root = config.root)
        }
        
        // Fetch styles (cached)
        val styles = if (config.styleRef != null) {
            styleCache.getOrFetch(
                id = config.styleRef.styleId,
                url = config.styleRef.url ?: buildStyleUrl(config.styleRef)
            )
        } else {
            // Fallback: use inline theme/styleClasses
            StyleData(
                theme = config.theme,
                styleClasses = config.styleClasses
            )
        }
        
        // Fetch data (NOT cached)
        val data = if (config.dataRef != null) {
            apiClient.fetchData(config.dataRef.url)
        } else {
            // Fallback: use inline variables
            DataValues(values = config.variables)
        }
        
        // Combine everything
        return ResolvedConfig(
            theme = styles.theme ?: config.theme!!,
            styleClasses = styles.styleClasses + config.styleClasses,
            variables = data.values,
            root = template.root ?: config.root
        )
    }
}

// Helper to detect config type
private fun NativeDisplayConfig.isMonolithic(): Boolean {
    return theme != null && 
           root != null && 
           templateRef == null && 
           styleRef == null && 
           dataRef == null
}

private fun NativeDisplayConfig.hasReferences(): Boolean {
    return templateRef != null || 
           styleRef != null || 
           dataRef != null
}
```

---

## 📋 Example: Both Phases Work

### Phase 1: Backend Sends Everything

**Request**:
```
GET /api/displays/123
```

**Response** (one JSON, ~10KB):
```json
{
  "version": "1.0",
  "theme": { },
  "styleClasses": [ ],
  "variables": { },
  "root": { }
}
```

**Mobile App**:
```kotlin
val config = loader.load(responseJson)
// Everything is already there, render immediately!
NativeDisplayView(config)
```

**Bandwidth**: 10KB per display

---

### Phase 2+: Backend Sends References

**Request**:
```
GET /api/displays/123
```

**Response** (tiny, ~0.5KB):
```json
{
  "version": "2.0",
  "templateRef": {
    "templateId": "product-promo-v1",
    "version": "1.0"
  },
  "styleRef": {
    "styleId": "default-theme-v1",
    "version": "1.0"
  },
  "dataRef": {
    "dataId": "data-123",
    "url": "/api/data/123"
  }
}
```

**Mobile App**:
```kotlin
val config = loader.load(responseJson)
// Loader automatically:
// 1. Fetches template (8KB, cached!)
// 2. Fetches styles (2KB, cached!)
// 3. Fetches data (0.5KB, fresh)
// 4. Combines all three
NativeDisplayView(config)
```

**Bandwidth**: 
- First time: 10.5KB (template + styles + data)
- Second time: 0.5KB (only data, rest cached!)

**Savings**: 95% after first load! 🎉

---

## 🎯 Hybrid Mode (Best of Both!)

Backend can also send **partial inline + partial references**:

```json
{
  "version": "2.0",
  
  "theme": {
    "id": "inline-override",
    "defaultStyle": { }
  },
  
  "templateRef": {
    "templateId": "product-promo-v1"
  },
  
  "variables": {
    "userName": "John Doe"
  },
  
  "dataRef": {
    "url": "/api/additional-data/123"
  }
}
```

**Mobile App**:
```kotlin
// Loader automatically:
// 1. Uses inline theme
// 2. Fetches template (cached)
// 3. Merges inline variables + fetched data
// 4. Combines everything
```

**Flexibility**: Mix and match as needed!

---

## 📊 Migration Strategy

### Step 1: Today (Phase 1)

**Backend**:
```kotlin
// Single endpoint returns everything
@GET("/api/displays/{id}")
fun getDisplay(@Path("id") id: String): DisplayConfig {
    return DisplayConfig(
        theme = buildTheme(),
        styleClasses = buildStyles(),
        variables = buildVariables(userId),
        root = buildLayout()
    )
}
```

**Mobile**:
```kotlin
val config = apiClient.getDisplay("123")
// Everything inline, works immediately
```

---

### Step 2: Extract Styles (Phase 2a)

**Backend**:
```kotlin
// New endpoint for styles
@GET("/api/styles/{id}")
fun getStyles(@Path("id") id: String): StyleData

// Display now references styles
@GET("/api/displays/{id}")
fun getDisplay(@Path("id") id: String): DisplayConfig {
    return DisplayConfig(
        styleRef = StyleReference(
            styleId = "default-theme-v1",
            version = "1.0"
        ),
        variables = buildVariables(userId),
        root = buildLayout()
    )
}
```

**Mobile**: Same code, automatically detects and fetches styles!

---

### Step 3: Extract Template (Phase 2b)

**Backend**:
```kotlin
// New endpoint for templates
@GET("/api/templates/{id}")
fun getTemplate(@Path("id") id: String): TemplateData

// Display now references template
@GET("/api/displays/{id}")
fun getDisplay(@Path("id") id: String): DisplayConfig {
    return DisplayConfig(
        templateRef = TemplateReference(
            templateId = "product-promo-v1",
            version = "1.0"
        ),
        styleRef = StyleReference(
            styleId = "default-theme-v1",
            version = "1.0"
        ),
        variables = buildVariables(userId)
    )
}
```

**Mobile**: Same code, automatically detects and fetches template!

---

### Step 4: Extract Data (Phase 2c)

**Backend**:
```kotlin
// New endpoint for data
@GET("/api/data/{id}")
fun getData(@Path("id") id: String): DataValues

// Display now only has references
@GET("/api/displays/{id}")
fun getDisplay(@Path("id") id: String): DisplayConfig {
    return DisplayConfig(
        templateRef = TemplateReference("product-promo-v1"),
        styleRef = StyleReference("default-theme-v1"),
        dataRef = DataReference(
            dataId = "data-$userId",
            url = "/api/data/$userId"
        )
    )
}
```

**Mobile**: Same code, automatically fetches everything!

---

## 🎨 Implementation

### Phase 1: Monolithic Loader

```kotlin
class MonolithicLoader : DisplayLoader {
    override suspend fun load(configJson: String): ResolvedConfig {
        val config = Json.decodeFromString<NativeDisplayConfig>(configJson)
        
        // Everything is inline!
        return ResolvedConfig(
            theme = config.theme!!,
            styleClasses = config.styleClasses,
            variables = config.variables,
            root = config.root
        )
    }
}
```

---

### Phase 2+: Adaptive Loader

```kotlin
class AdaptiveLoader(
    private val templateCache: TemplateCache,
    private val styleCache: StyleCache,
    private val apiClient: ApiClient
) : DisplayLoader {
    override suspend fun load(configJson: String): ResolvedConfig {
        val config = Json.decodeFromString<NativeDisplayConfig>(configJson)
        
        // Fetch what's needed (with caching)
        val template = loadTemplate(config)
        val styles = loadStyles(config)
        val data = loadData(config)
        
        // Merge everything
        return ResolvedConfig(
            theme = styles.theme ?: config.theme!!,
            styleClasses = styles.styleClasses + config.styleClasses,
            variables = data.values + config.variables,
            root = template.root ?: config.root
        )
    }
    
    private suspend fun loadTemplate(config: NativeDisplayConfig): TemplateData {
        return when {
            config.templateRef != null -> {
                // Fetch from cache or API
                templateCache.getOrFetch(config.templateRef)
            }
            config.root != null -> {
                // Use inline
                TemplateData(root = config.root)
            }
            else -> throw IllegalStateException("No template")
        }
    }
    
    private suspend fun loadStyles(config: NativeDisplayConfig): StyleData {
        return when {
            config.styleRef != null -> {
                // Fetch from cache or API
                styleCache.getOrFetch(config.styleRef)
            }
            config.theme != null -> {
                // Use inline
                StyleData(
                    theme = config.theme,
                    styleClasses = config.styleClasses
                )
            }
            else -> throw IllegalStateException("No styles")
        }
    }
    
    private suspend fun loadData(config: NativeDisplayConfig): DataValues {
        return when {
            config.dataRef != null -> {
                // Fetch fresh data
                apiClient.fetchData(config.dataRef.url)
            }
            config.variables.isNotEmpty() -> {
                // Use inline
                DataValues(values = config.variables)
            }
            else -> DataValues(emptyMap())
        }
    }
}
```

---

## ✅ Benefits of This Approach

### Phase 1 (Now)
```
Backend: Simple (one JSON)
Mobile: Simple (load and render)
Performance: Good
Bandwidth: ~10KB per display
```

### Phase 2+ (Future)
```
Backend: Flexible (split APIs)
Mobile: Same code! (automatic detection)
Performance: Excellent (caching)
Bandwidth: ~0.5KB after first load (95% savings!)
```

### Migration
```
Zero breaking changes!
Backend migrates API by API
Mobile auto-adapts
Old displays still work
New displays use caching
```

---

## 📊 Comparison

| Feature | Phase 1 (Monolithic) | Phase 2+ (Split) |
|---------|---------------------|------------------|
| **Backend complexity** | Simple ✅ | Complex ⚠️ |
| **Mobile complexity** | Simple ✅ | Same! ✅ |
| **First load** | 10KB | 10.5KB |
| **Second load** | 10KB | 0.5KB ✅ |
| **100 displays** | 1000KB | 58KB ✅ |
| **Caching** | None | Excellent ✅ |
| **A/B testing** | Hard | Easy ✅ |
| **Template reuse** | No | Yes ✅ |

---

## 🎯 Recommendation

### Start with Phase 1 ✅

```json
{
  "version": "1.0",
  "theme": { },
  "styleClasses": [ ],
  "variables": { },
  "root": { }
}
```

**Why**:
- ✅ Backend is simple
- ✅ Mobile is simple
- ✅ Ships quickly
- ✅ Works today

### Evolve to Phase 2+ when ready ✅

```json
{
  "version": "2.0",
  "templateRef": { "templateId": "..." },
  "styleRef": { "styleId": "..." },
  "dataRef": { "url": "..." }
}
```

**When**:
- Backend team has bandwidth
- Scale demands it (1000s of displays)
- Want A/B testing
- Want template reuse

**Impact**:
- ✅ Zero mobile code changes!
- ✅ Automatic caching
- ✅ 95% bandwidth savings

---

## 🚀 Summary

**You get the best of both worlds**:

1. **Phase 1**: Start simple, everything together
2. **Phase 2+**: Backend splits APIs when ready
3. **Mobile**: Same code works for both!
4. **Migration**: Zero breaking changes
5. **Performance**: Excellent caching in Phase 2+

**Your system adapts automatically!** 🎉

---

## 📝 Next Steps

1. ✅ Build Phase 1 data models (monolithic)
2. ✅ Add optional reference fields (future-proof)
3. ✅ Implement adaptive loader
4. ✅ Test with Phase 1 JSON
5. ⏳ When backend ready, add split APIs
6. ✅ Same mobile code automatically uses caching!

**Start coding Phase 1, you're already future-proof!** 🚀
