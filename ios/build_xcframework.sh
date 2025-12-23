#!/bin/bash

# Build XCFramework for CleverTapNativeDisplay
# This script builds the framework for iOS devices and simulators, then packages them into an XCFramework

set -e

# Configuration
FRAMEWORK_NAME="CleverTapNativeDisplay"
PROJECT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BUILD_DIR="${PROJECT_DIR}/build"
OUTPUT_DIR="${PROJECT_DIR}/output"

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf "${BUILD_DIR}"
rm -rf "${OUTPUT_DIR}"
mkdir -p "${BUILD_DIR}"
mkdir -p "${OUTPUT_DIR}"

# Build for iOS Device (arm64)
echo "📱 Building for iOS Device (arm64)..."
xcodebuild archive \
    -project "${PROJECT_DIR}/${FRAMEWORK_NAME}.xcodeproj" \
    -scheme "${FRAMEWORK_NAME}" \
    -destination "generic/platform=iOS" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# Build for iOS Simulator (arm64 + x86_64)
echo "🖥️ Building for iOS Simulator..."
xcodebuild archive \
    -project "${PROJECT_DIR}/${FRAMEWORK_NAME}.xcodeproj" \
    -scheme "${FRAMEWORK_NAME}" \
    -destination "generic/platform=iOS Simulator" \
    -archivePath "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive" \
    SKIP_INSTALL=NO \
    BUILD_LIBRARY_FOR_DISTRIBUTION=YES \
    ONLY_ACTIVE_ARCH=NO

# Create XCFramework
echo "📦 Creating XCFramework..."
xcodebuild -create-xcframework \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -framework "${BUILD_DIR}/${FRAMEWORK_NAME}-iOS-Simulator.xcarchive/Products/Library/Frameworks/${FRAMEWORK_NAME}.framework" \
    -output "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"

# Verify
echo ""
echo "✅ XCFramework created successfully!"
echo "📍 Location: ${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework"
echo ""
echo "Directory structure:"
ls -la "${OUTPUT_DIR}/${FRAMEWORK_NAME}.xcframework/"

# Cleanup build directory (optional)
# rm -rf "${BUILD_DIR}"

echo ""
echo "🎉 Done! You can now distribute the XCFramework to clients."
echo ""
echo "Integration options:"
echo "  1. Drag ${FRAMEWORK_NAME}.xcframework into Xcode project"
echo "  2. Add to Frameworks, Libraries, and Embedded Content"
echo "  3. Set 'Embed & Sign' for dynamic framework"
