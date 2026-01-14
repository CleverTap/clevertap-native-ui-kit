# Android XML Sample App

This sample app demonstrates the Native Display SDK integration with traditional XML-based Android development using RecyclerView.

## Features

- RecyclerView with mixed native and SDUI items
- Every 3rd item is SDUI-powered
- Product list from DummyJSON API
- Optimized view recycling
- Material Design 3

## Setup

1. Make sure you have Android Studio installed
2. Open this project in Android Studio
3. Sync Gradle
4. Run on device or emulator

## Structure

- `data/` - API models and service
- `sdui/` - SDUI config generator
- `ui/` - RecyclerView adapter and ViewHolders
- `MainActivity.kt` - Main entry point

## Requirements

- Android Studio Hedgehog or newer
- Minimum SDK: 24
- Target SDK: 34
- Kotlin 1.9.20+
