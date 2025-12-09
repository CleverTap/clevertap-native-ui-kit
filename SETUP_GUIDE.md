# CleverTap Native UI Kit - Setup Guide

## ✅ Project Created Successfully

**Location:** `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit`

## 📁 Project Structure

```
clevertap-native-ui-kit/
├── VERSION (0.1.0)
├── README.md
├── .gitignore
├── SETUP_GUIDE.md (this file)
│
├── android/
│   ├── build.gradle.kts (root build file)
│   ├── settings.gradle.kts (project settings)
│   ├── gradle.properties (gradle configuration)
│   ├── gradle/
│   │   └── libs.versions.toml (dependency versions)
│   ├── sdk/
│   │   ├── build.gradle.kts (library module)
│   │   └── src/main/
│   │       └── AndroidManifest.xml
│   └── sample-app/
│       ├── build.gradle.kts (sample app module)
│       └── src/main/
│           └── AndroidManifest.xml
│
├── ios/
│   └── CleverTapNativeUIKit/
│       ├── Package.swift (Swift Package)
│       └── Sources/CleverTapNativeUIKit/
│           └── CleverTapNativeUIKit.swift
│
├── docs/
│   └── examples/
│
├── schema/
├── scripts/
```

## 🚀 Next Steps

### 1. Verify Project Location

Open Finder and navigate to:
```
/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit
```

You should see all the folders and files listed above.

### 2. Open Android Project

**Option A: From Terminal**
```bash
cd /Users/lalitkumar/StudioProjects/clevertap-native-ui-kit
open -a "Android Studio" android/
```

**Option B: From Android Studio**
1. Launch Android Studio
2. Click "Open"
3. Navigate to: `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit/android`
4. Click "Open"

### 3. Setup Gradle Wrapper

After opening in Android Studio, open Terminal in Android Studio and run:

```bash
# Navigate to android directory
cd android

# Generate Gradle wrapper (requires Gradle installed)
gradle wrapper --gradle-version 8.10

# Or let Android Studio generate it automatically on first sync
```

Android Studio will automatically:
- Download Gradle wrapper
- Sync project dependencies
- Setup the project

### 4. Wait for Gradle Sync

First time setup will take a few minutes:
- Gradle will download all dependencies
- Android Studio will index the project
- This is normal - just wait for it to complete

### 5. Create Package Structure

After Gradle sync, create the Kotlin package directories:

**In Android Studio:**
1. Right-click on `sdk/src/main/`
2. New → Directory
3. Choose "kotlin"
4. Right-click on `kotlin` folder
5. New → Package
6. Enter: `com.clevertap.android.nativeui.models`

Repeat for:
- `com.clevertap.android.nativeui.styling`
- `com.clevertap.android.nativeui.layout`
- `com.clevertap.android.nativeui.ui`
- `com.clevertap.android.nativeui.registry`

**Or via Terminal:**
```bash
cd /Users/lalitkumar/StudioProjects/clevertap-native-ui-kit/android/sdk/src/main
mkdir -p kotlin/com/clevertap/android/nativeui/{models,styling,layout,ui,registry}
```

## 🔧 Configuration Details

### Android
- **Package:** `com.clevertap.android:clevertap-native-ui-kit`
- **minSdk:** 23 (Android 6.0) - 97% device coverage
- **compileSdk:** 36 (Android 15)
- **Kotlin:** 2.1.0
- **Compose:** 1.7.5
- **AGP:** 8.7.3

### iOS
- **Package:** `CleverTapNativeUIKit`
- **Min iOS:** 15.0
- **Swift:** 5.9+

## 📝 Phase 1 Implementation

Now you're ready to start Phase 1 development!

### Week 1: Data Models (Start Here)

Create these files in `android/sdk/src/main/kotlin/com/clevertap/android/nativeui/models/`:

1. **InAppConfig.kt** - Root configuration
2. **Element.kt** - UI element types
3. **Layout.kt** - Layout system
4. **Theme.kt** - Theme tokens
5. **StyleClass.kt** - Reusable styles
6. **Animation.kt** - Animation definitions
7. **Action.kt** - User actions

### Example: InAppConfig.kt

```kotlin
package com.clevertap.android.nativeui.models

import kotlinx.serialization.Serializable

@Serializable
data class InAppConfig(
    val version: String,
    val themeRef: String? = null,
    val stylesRef: String? = null,
    val container: Container,
    val elements: List<Element>
)

@Serializable
data class Container(
    val type: ContainerType,
    val layout: Layout,
    val animation: Animation? = null,
    val accessibility: Accessibility
)

@Serializable
enum class ContainerType {
    vertical, horizontal, box
}
```

## 🧪 Testing Your Setup

After Gradle sync completes, verify everything works:

```bash
cd /Users/lalitkumar/StudioProjects/clevertap-native-ui-kit/android

# Build the project
./gradlew build

# Run tests (when you add them)
./gradlew test
```

## 🐛 Troubleshooting

### Issue: "Gradle sync failed"
**Solution:**
1. Make sure you have JDK 17 installed
2. Android Studio → Settings → Build → Build Tools → Gradle
3. Set Gradle JDK to version 17

### Issue: "Cannot find libs.versions.toml"
**Solution:**
- The file should be at `android/gradle/libs.versions.toml`
- If missing, check if it was created correctly

### Issue: "SDK location not found"
**Solution:**
1. Create/edit `android/local.properties`
2. Add: `sdk.dir=/Users/lalitkumar/Library/Android/sdk`
3. Adjust path to your Android SDK location

### Issue: "Cannot resolve dependencies"
**Solution:**
- Check internet connection
- Let Gradle finish syncing
- Try: File → Invalidate Caches / Restart

## 📚 Resources

- [Jetpack Compose](https://developer.android.com/jetpack/compose)
- [Kotlin Serialization](https://github.com/Kotlin/kotlinx.serialization)
- [Android Gradle Plugin](https://developer.android.com/build)

## 🎯 Quick Commands

```bash
# Navigate to project
cd /Users/lalitkumar/StudioProjects/clevertap-native-ui-kit

# Open in Android Studio
open -a "Android Studio" android/

# Build project
cd android && ./gradlew build

# Clean build
cd android && ./gradlew clean

# View project structure
cd .. && tree -L 3 -I 'build|.gradle'
```

## ✅ Verification Checklist

- [ ] Project folder exists at `/Users/lalitkumar/StudioProjects/clevertap-native-ui-kit`
- [ ] Can open `android/` folder in Android Studio
- [ ] Gradle sync completes successfully
- [ ] Can see `sdk` and `sample-app` modules
- [ ] JDK 17 is configured
- [ ] Android SDK is configured
- [ ] Ready to start coding!

## 📧 Support

If you encounter issues:
1. Check this guide
2. Check Android Studio error messages
3. Google the specific error
4. Check Gradle output for details

---

**Version:** 0.1.0  
**Status:** Ready for Phase 1 Development  
**Created:** December 2024
