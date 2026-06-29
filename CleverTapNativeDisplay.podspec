Pod::Spec.new do |spec|
  spec.name         = "CleverTapNativeDisplay"
  spec.version      = "1.0.0"
  spec.summary      = "Server-driven UI framework for native mobile interfaces"
  spec.description  = <<-DESC
    CleverTapNativeDisplay is a server-driven UI framework that renders native
    SwiftUI interfaces from JSON configurations. It supports dynamic layouts,
    styling, galleries, background effects, and variable interpolation.
  DESC

  spec.homepage     = "https://github.com/CleverTap/clevertap-native-ui-kit"
  spec.license      = { :type => "MIT", :file => "LICENSE" }
  spec.author       = { "CleverTap" => "support@clevertap.com" }

  spec.platform     = :ios, "15.0"
  spec.swift_version = "5.5"

  spec.source = {
    :git => "https://github.com/CleverTap/clevertap-native-ui-kit.git",
    :tag => "#{spec.version}"
  }

  # Paths are relative to the repo root (where pod spec lint / trunk push clone the
  # git source), so the podspec must live at the root for lib lint and spec lint to agree.
  spec.source_files = "ios/Sources/CleverTapNativeDisplay/**/*.swift"

  # Apple privacy manifest. resource_bundles (not resources) ensures it is
  # bundled even when the pod is linked statically.
  spec.resource_bundles = {
    "CleverTapNativeDisplay" => ["ios/Sources/CleverTapNativeDisplay/PrivacyInfo.xcprivacy"]
  }

  spec.frameworks = "SwiftUI", "Foundation", "UIKit", "WebKit", "AVKit"

  # Build settings for framework distribution
  spec.pod_target_xcconfig = {
    'BUILD_LIBRARY_FOR_DISTRIBUTION' => 'YES',
    'DEFINES_MODULE' => 'YES'
  }
end
