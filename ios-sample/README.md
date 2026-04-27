# Native Display Sample App

Sample iOS application demonstrating the CleverTap Native Display SDK by rendering the same `home_screen.json` used by the Android sample app.

## Opening the Project

```bash
open NativeDisplaySample.xcodeproj
```

## Project Structure

```
ios-sample/
├── NativeDisplaySample.xcodeproj     # ← Open this in Xcode
├── README.md
└── NativeDisplaySample/
    ├── NativeDisplaySampleApp.swift  # App entry point
    ├── ContentView.swift             # Main view (loads home_screen.json)
    ├── Assets.xcassets/              # App assets
    └── Resources/
        └── home_screen.json          # Same JSON as Android sample
```

## SDK Dependency

This sample app references the SDK via a **local Swift Package** at `../ios`.

## Running the App

1. Open `NativeDisplaySample.xcodeproj` in Xcode
2. Select an iOS Simulator (iPhone 15 recommended)
3. Press ⌘+R to build and run

## Comparing with Android

The `home_screen.json` file is the same JSON used by the Android sample app located at:
```
android/sample-app/src/main/assets/home_screen.json
```

This allows you to compare the rendering output between iOS and Android using the exact same JSON configuration.

## Features Demonstrated

- Header with gradient background and variable substitution (`{{userName}}`)
- Auto-scrolling banner carousel (snapping gallery)
- Category chips (free-flow gallery)
- Full-width promotional banner with dark gradient
- Product grid (free-flow grid gallery with 2.15 items per view)
- Quick action buttons grid
- Spacers and dividers

## Requirements

- iOS 15.0+
- Xcode 15.0+
- The SDK at `../ios` must be present
