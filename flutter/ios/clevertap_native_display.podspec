#
# To learn more about a Podspec see http://guides.cocoapods.org/syntax/podspec.html.
# Run `pod lib lint clevertap_native_display.podspec` to validate before publishing.
#
Pod::Spec.new do |s|
  s.name             = 'clevertap_native_display'
  s.version          = '0.1.0'
  s.summary          = 'Native Display SDK Flutter plugin for CleverTap.'
  s.description      = <<-DESC
iOS platform bridge for the clevertap_native_display Flutter plugin, which
renders server-driven native UI from JSON. The renderer itself is pure Dart;
this pod provides the MethodChannel bridge that forwards display-unit fetch and
attribution calls to the host-wired CleverTap Core SDK.
                       DESC
  s.homepage         = 'https://github.com/CleverTap/clevertap-native-ui-kit'
  s.license          = { :type => 'MIT', :file => '../LICENSE' }
  s.author           = { 'CleverTap' => 'http://www.clevertap.com' }
  s.source           = { :path => '.' }
  s.source_files     = 'Classes/**/*'
  s.dependency 'Flutter'
  s.platform = :ios, '12.0'

  # Flutter.framework does not contain an i386 slice.
  s.pod_target_xcconfig = { 'DEFINES_MODULE' => 'YES', 'EXCLUDED_ARCHS[sdk=iphonesimulator*]' => 'i386' }
  s.swift_version = '5.0'
end
