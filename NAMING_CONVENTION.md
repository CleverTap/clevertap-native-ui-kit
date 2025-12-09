# Naming Convention: NativeDisplay* (Not InApp*)

## ✅ Correct Naming

All components use the **`NativeDisplay`** prefix:

### Models
```kotlin
// ✅ CORRECT
data class NativeDisplayConfig
data class NativeDisplayElement
data class NativeDisplayContainer
data class NativeDisplayStyle
data class NativeDisplayTheme
data class NativeDisplayStyleClass

// ❌ WRONG (deprecated)
data class InAppConfig
data class InAppElement
```

### Classes
```kotlin
// ✅ CORRECT
class NativeDisplayParser
class NativeDisplayRenderer
class NativeDisplayStyleResolver
class NativeDisplayLayoutCalculator

// ❌ WRONG (deprecated)
class InAppParser
class InAppRenderer
```

### Composables (Android)
```kotlin
// ✅ CORRECT
@Composable
fun NativeDisplayView(config: NativeDisplayConfig)

@Composable
fun NativeDisplayTextElement(element: NativeDisplayElement)

// ❌ WRONG (deprecated)
@Composable
fun InAppView(config: InAppConfig)
```

### Views (iOS)
```swift
// ✅ CORRECT
struct NativeDisplayView: View { }
struct NativeDisplayTextElement: View { }

// ❌ WRONG (deprecated)
struct InAppView: View { }
```

---

## 📦 Package Structure

### Android
```kotlin
com.clevertap.android.nativedisplay.models
com.clevertap.android.nativedisplay.parser
com.clevertap.android.nativedisplay.styling
com.clevertap.android.nativedisplay.layout
com.clevertap.android.nativedisplay.ui
```

### iOS
```swift
CleverTapNativeDisplay/Models
CleverTapNativeDisplay/Parser
CleverTapNativeDisplay/Styling
CleverTapNativeDisplay/Layout
CleverTapNativeDisplay/UI
```

---

## 🎯 Why "NativeDisplay"?

### Better Semantics
- ✅ **NativeDisplay**: Describes what it does (native UI display)
- ❌ **InApp**: Too generic (many things are "in-app")

### Clearer Purpose
- ✅ **NativeDisplay**: Server-driven native UI rendering
- ❌ **InApp**: Could be anything in the app

### Future-Proof
- ✅ **NativeDisplay**: Can expand beyond messages
- ❌ **InApp**: Locked to messaging context

---

## 📝 Usage Examples

### Android
```kotlin
import com.clevertap.android.nativedisplay.models.*
import com.clevertap.android.nativedisplay.parser.NativeDisplayParser
import com.clevertap.android.nativedisplay.ui.NativeDisplayView

// Parse JSON
val parser = NativeDisplayParser()
val config: NativeDisplayConfig = parser.parse(jsonString)

// Render
@Composable
fun ShowMessage() {
    NativeDisplayView(config = config)
}
```

### iOS
```swift
import CleverTapNativeDisplay

// Parse JSON
let parser = NativeDisplayParser()
let config: NativeDisplayConfig = try parser.parse(jsonString: json)

// Render
struct MessageView: View {
    var body: some View {
        NativeDisplayView(config: config)
    }
}
```

---

## 🔄 Migration Guide

If you have any old `InApp*` code:

### Step 1: Find & Replace
```bash
# Android
find android -name "*.kt" -exec sed -i '' 's/InApp/NativeDisplay/g' {} +

# iOS
find ios -name "*.swift" -exec sed -i '' 's/InApp/NativeDisplay/g' {} +
```

### Step 2: Update Imports
```kotlin
// Before
import com.clevertap.android.inapp.models.*

// After
import com.clevertap.android.nativedisplay.models.*
```

### Step 3: Update Package Names
```kotlin
// Before
package com.clevertap.android.inapp.models

// After
package com.clevertap.android.nativedisplay.models
```

---

## ✅ Checklist

When creating new code, ensure:

- [ ] All classes use `NativeDisplay` prefix
- [ ] All files use `NativeDisplay` prefix
- [ ] Package names use `nativedisplay` (lowercase)
- [ ] No `InApp*` references remain
- [ ] Documentation uses `NativeDisplay`
- [ ] Comments use `NativeDisplay`

---

## 📚 Complete List

### Core Models
- `NativeDisplayConfig`
- `NativeDisplayElement`
- `NativeDisplayContainer`
- `NativeDisplayLayout`
- `NativeDisplayStyle`
- `NativeDisplayTheme`
- `NativeDisplayStyleClass`
- `NativeDisplayAction`

### Core Classes
- `NativeDisplayParser`
- `NativeDisplayRenderer`
- `NativeDisplayStyleResolver`
- `NativeDisplayLayoutCalculator`
- `NativeDisplayValidator`

### UI Components (Android)
- `NativeDisplayView`
- `NativeDisplayTextElement`
- `NativeDisplayImageElement`
- `NativeDisplayButtonElement`
- `NativeDisplayVideoElement`
- `NativeDisplaySpacerElement`

### UI Components (iOS)
- `NativeDisplayView`
- `NativeDisplayTextElement`
- `NativeDisplayImageElement`
- `NativeDisplayButtonElement`
- `NativeDisplayVideoElement`
- `NativeDisplaySpacerElement`

---

## 🎯 Summary

**Use**: `NativeDisplay*` prefix everywhere  
**Don't use**: `InApp*` (deprecated)  
**Reason**: Better semantics, clearer purpose, future-proof

---

**Status**: ✅ Standard naming convention  
**Applies to**: All new code  
**Effective**: Immediately
