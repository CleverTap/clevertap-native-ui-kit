# Product Card Demo

## Description
Complete e-commerce product card demonstrating:
- Vertical container with arrangement
- Image element
- Text elements with style cascading
- Button element
- Gallery for multiple images

## JSON Configuration
```json
{
  "theme": {
    "id": "ecommerce",
    "defaultStyle": {
      "textColor": "#212121",
      "fontSize": 14,
      "fontFamily": "Roboto"
    }
  },
  "variables": {
    "productName": "Wireless Headphones",
    "price": "$299.99",
    "rating": "4.5",
    "inStock": true,
    "images": ["image1.jpg", "image2.jpg", "image3.jpg"]
  },
  "root": {
    "id": "product-card",
    "containerType": "vertical",
    "layout": {
      "width": {"value": 100, "unit": "percent"},
      "padding": {"all": 16}
    },
    "style": {
      "backgroundColor": "#FFFFFF",
      "borderRadius": 12,
      "shadowColor": "#000000",
      "shadowRadius": 4,
      "shadowOffsetY": 2
    },
    "arrangement": {
      "spacing": 12,
      "strategy": "spaced"
    },
    "children": [
      {
        "id": "gallery",
        "containerType": "gallery",
        "galleryConfig": {
          "mode": "snapping",
          "snapBehavior": "center",
          "peekPercentage": 10
        },
        "children": [...]
      },
      {
        "id": "name",
        "elementType": "text",
        "bindings": {"text": "{{productName}}"},
        "style": {"fontSize": 18, "fontWeight": "bold"}
      },
      {
        "id": "price",
        "elementType": "text",
        "bindings": {"text": "{{price}}"},
        "style": {"fontSize": 24, "fontWeight": "bold", "textColor": "#FF5722"}
      },
      {
        "id": "buy-button",
        "elementType": "button",
        "bindings": {"text": "Add to Cart"},
        "style": {
          "backgroundColor": "#FF5722",
          "textColor": "#FFFFFF",
          "borderRadius": 8
        }
      }
    ]
  }
}
```

## Implementation
```kotlin
@Composable
fun ProductCardDemo() {
    val json = loadAssetAsString("product_card.json")
    val config = Json.decodeFromString<NativeDisplayConfig>(json)

    Box(modifier = Modifier.fillMaxSize().padding(16.dp)) {
        NativeDisplayView(config)
    }
}
```

## Key Learnings
- Vertical container with SPACED arrangement
- Style cascading from theme to elements
- Template variable binding
- Gallery with peeking effect
- Shadow and border radius
