# Complete Example: Template + Data Separation

## 🎯 Scenario: Promotional Product Card

A promotional card showing:
- Product image
- Product name
- Discount percentage
- Original price (strikethrough)
- Sale price (bold)
- CTA button
- Stock status
- Premium badge (conditional)

---

## 📋 Visual Mockup

```
┌─────────────────────────────────────┐
│  [Premium Badge]                    │ ← Conditional
│                                     │
│  ┌─────────────────────────────┐   │
│  │                             │   │
│  │     [Product Image]         │   │
│  │                             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Wireless Headphones Pro            │ ← Product name
│  ★★★★☆ 4.5 (234 reviews)           │ ← Rating + reviews
│                                     │
│  Save 25% Today!                    │ ← Discount message
│  $299.99  $224.99                   │ ← Price (old/new)
│                                     │
│  Only 5 left in stock!              │ ← Stock status
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Buy Now                │   │ ← CTA button
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 📄 Part 1: Template (Structure - Cached)

**File**: `product-card-template-v1.json`

```json
{
  "templateId": "product-card-v1",
  "version": "1.0",
  "name": "Product Card Template",
  "description": "Promotional product card with image, pricing, and CTA",
  
  "theme": {
    "id": "default",
    "defaultStyle": {
      "textColor": "#000000",
      "fontSize": 14,
      "fontWeight": "normal"
    },
    "colors": {
      "primary": "#007AFF",
      "danger": "#FF3B30",
      "success": "#34C759",
      "warning": "#FF9500",
      "background": "#F5F5F5",
      "cardBackground": "#FFFFFF"
    }
  },
  
  "styleClasses": [
    {
      "name": "card",
      "style": {
        "backgroundColor": "#FFFFFF",
        "borderRadius": 16,
        "shadowColor": "#00000020",
        "shadowRadius": 12,
        "shadowOffsetY": 4,
        "padding": { "all": 20 }
      }
    },
    {
      "name": "product-name",
      "style": {
        "fontSize": 20,
        "fontWeight": "bold",
        "textColor": "#000000"
      }
    },
    {
      "name": "price-old",
      "style": {
        "fontSize": 16,
        "textColor": "#999999",
        "textDecoration": "strikethrough"
      }
    },
    {
      "name": "price-new",
      "style": {
        "fontSize": 24,
        "fontWeight": "bold",
        "textColor": "#FF3B30"
      }
    },
    {
      "name": "badge",
      "style": {
        "backgroundColor": "#FFD700",
        "textColor": "#000000",
        "fontSize": 12,
        "fontWeight": "bold",
        "borderRadius": 8,
        "padding": { "horizontal": 12, "vertical": 6 }
      }
    },
    {
      "name": "cta-button",
      "style": {
        "backgroundColor": "#007AFF",
        "textColor": "#FFFFFF",
        "fontSize": 18,
        "fontWeight": "bold",
        "borderRadius": 12,
        "padding": { "vertical": 16 }
      }
    }
  ],
  
  "root": {
    "type": "container",
    "id": "card-container",
    "containerType": "vertical",
    "styleClass": "card",
    "layout": {
      "width": { "value": 100, "unit": "percent" },
      "padding": { "all": 20, "unit": "dp" }
    },
    
    "children": [
      {
        "type": "element",
        "id": "premium-badge",
        "elementType": "text",
        "bindings": {
          "text": "premiumBadgeText"
        },
        "styleClass": "badge",
        "visible": "{{isPremium}}",
        "layout": {
          "margin": { "bottom": 16, "unit": "dp" }
        }
      },
      
      {
        "type": "container",
        "id": "image-container",
        "containerType": "box",
        "style": {
          "backgroundColor": "#F0F0F0",
          "borderRadius": 12
        },
        "layout": {
          "width": { "value": 100, "unit": "percent" },
          "height": { "value": 200, "unit": "dp" },
          "margin": { "bottom": 16, "unit": "dp" }
        },
        "children": [
          {
            "type": "element",
            "id": "product-image",
            "elementType": "image",
            "bindings": {
              "url": "productImageUrl"
            },
            "layout": {
              "width": { "value": 100, "unit": "percent" },
              "height": { "value": 100, "unit": "percent" }
            }
          }
        ]
      },
      
      {
        "type": "element",
        "id": "product-name",
        "elementType": "text",
        "bindings": {
          "text": "productName"
        },
        "styleClass": "product-name",
        "layout": {
          "margin": { "bottom": 8, "unit": "dp" }
        }
      },
      
      {
        "type": "container",
        "id": "rating-container",
        "containerType": "horizontal",
        "layout": {
          "margin": { "bottom": 12, "unit": "dp" }
        },
        "children": [
          {
            "type": "element",
            "id": "rating-stars",
            "elementType": "text",
            "bindings": {
              "text": "ratingStars"
            },
            "style": {
              "fontSize": 16,
              "textColor": "#FFD700"
            }
          },
          {
            "type": "element",
            "id": "rating-text",
            "elementType": "text",
            "bindings": {
              "text": "ratingText"
            },
            "style": {
              "fontSize": 14,
              "textColor": "#666666"
            },
            "layout": {
              "margin": { "left": 8, "unit": "dp" }
            }
          }
        ]
      },
      
      {
        "type": "element",
        "id": "discount-message",
        "elementType": "text",
        "bindings": {
          "text": "discountMessage"
        },
        "style": {
          "fontSize": 16,
          "fontWeight": "bold",
          "textColor": "#34C759"
        },
        "visible": "{{hasDiscount}}",
        "layout": {
          "margin": { "bottom": 8, "unit": "dp" }
        }
      },
      
      {
        "type": "container",
        "id": "price-container",
        "containerType": "horizontal",
        "layout": {
          "margin": { "bottom": 12, "unit": "dp" }
        },
        "children": [
          {
            "type": "element",
            "id": "price-old",
            "elementType": "text",
            "bindings": {
              "text": "priceOld"
            },
            "styleClass": "price-old",
            "visible": "{{hasDiscount}}",
            "layout": {
              "margin": { "right": 12, "unit": "dp" }
            }
          },
          {
            "type": "element",
            "id": "price-new",
            "elementType": "text",
            "bindings": {
              "text": "priceNew"
            },
            "styleClass": "price-new"
          }
        ]
      },
      
      {
        "type": "element",
        "id": "stock-status",
        "elementType": "text",
        "bindings": {
          "text": "stockMessage"
        },
        "style": {
          "fontSize": 14,
          "fontWeight": "medium",
          "textColor": "{{stockLevel > 10 ? '#34C759' : '#FF9500'}}"
        },
        "visible": "{{stockLevel > 0}}",
        "layout": {
          "margin": { "bottom": 16, "unit": "dp" }
        }
      },
      
      {
        "type": "element",
        "id": "cta-button",
        "elementType": "button",
        "bindings": {
          "text": "ctaButtonText"
        },
        "styleClass": "cta-button",
        "layout": {
          "width": { "value": 100, "unit": "percent" }
        },
        "actions": {
          "onClick": {
            "type": "deeplink",
            "url": "{{productDeeplink}}"
          }
        }
      }
    ]
  }
}
```

**Size**: ~200 lines, ~8KB
**Frequency**: Sent once, cached on device for weeks/months

---

## 📊 Part 2: Data Sets (Values - Change Often)

### Data Set 1: Premium Product with Discount

**File**: `product-data-user123-item456.json`

```json
{
  "templateId": "product-card-v1",
  "timestamp": "2024-01-15T10:30:00Z",
  "userId": "user-123",
  
  "values": {
    "isPremium": true,
    "premiumBadgeText": "⭐ Premium Choice",
    
    "productImageUrl": "https://cdn.example.com/images/headphones-pro.jpg",
    "productName": "Wireless Headphones Pro",
    
    "ratingStars": "★★★★☆",
    "ratingText": "4.5 (234 reviews)",
    
    "hasDiscount": true,
    "discountMessage": "Save 25% Today!",
    "priceOld": "$299.99",
    "priceNew": "$224.99",
    
    "stockLevel": 5,
    "stockMessage": "Only 5 left in stock!",
    
    "ctaButtonText": "Buy Now",
    "productDeeplink": "app://product/456"
  }
}
```

**Size**: ~30 lines, ~0.5KB
**Frequency**: Sent every time user views product

---

### Data Set 2: Regular Product, No Discount

**File**: `product-data-user123-item789.json`

```json
{
  "templateId": "product-card-v1",
  "timestamp": "2024-01-15T10:35:00Z",
  "userId": "user-123",
  
  "values": {
    "isPremium": false,
    "premiumBadgeText": "",
    
    "productImageUrl": "https://cdn.example.com/images/keyboard-mech.jpg",
    "productName": "Mechanical Keyboard RGB",
    
    "ratingStars": "★★★★★",
    "ratingText": "5.0 (89 reviews)",
    
    "hasDiscount": false,
    "discountMessage": "",
    "priceOld": "",
    "priceNew": "$149.99",
    
    "stockLevel": 45,
    "stockMessage": "In stock",
    
    "ctaButtonText": "Add to Cart",
    "productDeeplink": "app://product/789"
  }
}
```

---

### Data Set 3: Out of Stock

**File**: `product-data-user123-item101.json`

```json
{
  "templateId": "product-card-v1",
  "timestamp": "2024-01-15T10:40:00Z",
  "userId": "user-123",
  
  "values": {
    "isPremium": true,
    "premiumBadgeText": "⭐ Bestseller",
    
    "productImageUrl": "https://cdn.example.com/images/mouse-gaming.jpg",
    "productName": "Gaming Mouse Ultra",
    
    "ratingStars": "★★★★☆",
    "ratingText": "4.8 (512 reviews)",
    
    "hasDiscount": true,
    "discountMessage": "Limited Time: 40% Off!",
    "priceOld": "$199.99",
    "priceNew": "$119.99",
    
    "stockLevel": 0,
    "stockMessage": "",
    
    "ctaButtonText": "Notify When Available",
    "productDeeplink": "app://notify/101"
  }
}
```

---

## 🎨 How It Renders

### Product 1: Wireless Headphones
```
┌─────────────────────────────────────┐
│  ⭐ Premium Choice                   │ ← visible (isPremium=true)
│                                     │
│  ┌─────────────────────────────┐   │
│  │   [Headphones Image]        │   │
│  └─────────────────────────────┘   │
│                                     │
│  Wireless Headphones Pro            │ ← productName
│  ★★★★☆ 4.5 (234 reviews)           │ ← ratingStars + ratingText
│                                     │
│  Save 25% Today!                    │ ← visible (hasDiscount=true)
│  $299.99  $224.99                   │ ← priceOld (visible) + priceNew
│                                     │
│  Only 5 left in stock!              │ ← orange (stockLevel=5 <= 10)
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Buy Now                │   │ ← ctaButtonText
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Product 2: Mechanical Keyboard
```
┌─────────────────────────────────────┐
│                                     │ ← NO badge (isPremium=false)
│  ┌─────────────────────────────┐   │
│  │   [Keyboard Image]          │   │
│  └─────────────────────────────┘   │
│                                     │
│  Mechanical Keyboard RGB            │
│  ★★★★★ 5.0 (89 reviews)            │
│                                     │
│                                     │ ← NO discount (hasDiscount=false)
│  $149.99                            │ ← Only priceNew (no old price)
│                                     │
│  In stock                           │ ← green (stockLevel=45 > 10)
│                                     │
│  ┌─────────────────────────────┐   │
│  │      Add to Cart            │   │
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

### Product 3: Gaming Mouse (Out of Stock)
```
┌─────────────────────────────────────┐
│  ⭐ Bestseller                       │
│                                     │
│  ┌─────────────────────────────┐   │
│  │   [Mouse Image]             │   │
│  └─────────────────────────────┘   │
│                                     │
│  Gaming Mouse Ultra                 │
│  ★★★★☆ 4.8 (512 reviews)           │
│                                     │
│  Limited Time: 40% Off!             │
│  $199.99  $119.99                   │
│                                     │
│                                     │ ← NO stock message (stockLevel=0)
│  ┌─────────────────────────────┐   │
│  │  Notify When Available      │   │ ← Different CTA
│  └─────────────────────────────┘   │
└─────────────────────────────────────┘
```

---

## 💻 Implementation Code

### Android (Kotlin + Compose)

```kotlin
// Data classes
@Serializable
data class UITemplate(
    val templateId: String,
    val version: String,
    val theme: Theme,
    val styleClasses: List<StyleClass>,
    val root: NativeDisplayNode
)

@Serializable
data class UIData(
    val templateId: String,
    val timestamp: String,
    val userId: String,
    val values: Map<String, JsonElement>
)

// Manager
class TemplateManager {
    private val templateCache = mutableMapOf<String, UITemplate>()
    
    fun loadTemplate(templateId: String): UITemplate {
        // Check cache first
        return templateCache[templateId] ?: run {
            // Download and cache
            val template = downloadTemplate(templateId)
            templateCache[templateId] = template
            template
        }
    }
}

// Rendering
@Composable
fun ProductCard(
    templateId: String,
    data: UIData
) {
    // Load template (cached)
    val template = remember { templateManager.loadTemplate(templateId) }
    
    // Create evaluator with data
    val evaluator = remember(data) { 
        VariableEvaluator(data.values) 
    }
    
    // Render
    NativeDisplayView(
        config = NativeDisplayConfig(
            version = template.version,
            variables = data.values,
            theme = template.theme,
            styleClasses = template.styleClasses,
            root = template.root
        ),
        evaluator = evaluator
    )
}

// Usage
@Composable
fun ProductListScreen() {
    val products = listOf(
        productData1,  // Data for product 1
        productData2,  // Data for product 2
        productData3   // Data for product 3
    )
    
    LazyColumn {
        items(products) { data ->
            ProductCard(
                templateId = "product-card-v1",  // Same template!
                data = data                       // Different data
            )
        }
    }
}
```

---

## 📊 Bandwidth Comparison

### Approach 1: Full JSON Every Time ❌

```
User views 100 products:
= 100 × 8KB (full JSON each time)
= 800KB total
```

### Approach 2: Template + Data ✅

```
Template (once):  8KB
Data per product: 0.5KB

User views 100 products:
= 8KB (template, cached) + (100 × 0.5KB) (data)
= 8KB + 50KB
= 58KB total

Savings: 742KB (93% less!) 🎉
```

---

## 🔄 Real-World Flow

### Backend API Endpoints

```
GET /api/templates/product-card-v1
Response: UITemplate (8KB)
Cache: 7 days

GET /api/products/456/display-data
Response: UIData (0.5KB)
Cache: None (fresh data)
```

### Mobile App Flow

```
1. App Launch:
   ├─ Download template: product-card-v1 (8KB)
   ├─ Cache template on disk
   └─ Store template version

2. User Views Product List:
   ├─ Check: Do we have template? YES (cached)
   ├─ Fetch data for 10 products (10 × 0.5KB = 5KB)
   └─ Render each product with template + data

3. User Views Another Product:
   ├─ Template: Use cached (0KB download!)
   └─ Data: Fetch fresh (0.5KB)
```

---

## 🎯 Key Benefits Visualized

### Same Template, Different Data

```
Template (product-card-v1)
    ↓ + Data Set 1
    = Headphones Card (with discount, 5 in stock)
    
    ↓ + Data Set 2
    = Keyboard Card (no discount, 45 in stock)
    
    ↓ + Data Set 3
    = Mouse Card (with discount, out of stock)
```

### A/B Testing

```
Data (user-123, product-456)
    ↓ + Template A (product-card-v1)
    = Layout with large image
    
    ↓ + Template B (product-card-v2)
    = Layout with video thumbnail
```

### Personalization

```
Template (product-card-v1)
    ↓ + Data for User A
    = Shows "Welcome back!"
    
    ↓ + Data for User B
    = Shows "First time? Get 10% off!"
```

---

## 📝 Summary

### What You Get

**Template** (8KB, cached):
- ✅ Complete UI structure
- ✅ All layouts and styles
- ✅ Binding placeholders
- ✅ Conditional logic
- ✅ Reusable across products

**Data** (0.5KB, fresh):
- ✅ Actual values
- ✅ Personalized per user
- ✅ Real-time updates
- ✅ Lightweight
- ✅ No UI structure

### Efficiency

| Metric | Full JSON | Template + Data | Savings |
|--------|-----------|-----------------|---------|
| First product | 8KB | 8.5KB | -6% |
| Second product | 8KB | 0.5KB | 94% ✅ |
| 100 products | 800KB | 58KB | 93% ✅ |

---

## 🎉 This Is What Template + Data Gives You!

1. **Bandwidth**: Save 90%+ after first load
2. **Reusability**: One template, infinite data sets
3. **Flexibility**: A/B test layouts without changing data
4. **Performance**: Cache templates, fetch only data
5. **Scale**: Millions of users, thousands of products

**Clear now?** 🚀
