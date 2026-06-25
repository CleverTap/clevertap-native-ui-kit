//
//  NativeDisplaySDKVersion.swift
//  CleverTapNativeDisplay
//
//  Runtime version constants for the Native Display SDK. These are stamped onto
//  every clicked-event payload that the bridge sends to Core SDK so the server
//  can attribute analytics back to a specific SDK build.
//
//  iOS version is owned independently of Android. Keep `name` and `code` in
//  lockstep with `CleverTapNativeDisplay.podspec` `spec.version`. iOS cannot
//  reliably read its own version from `Bundle.infoDictionary` across SPM /
//  static-framework / CocoaPods distributions, so we mirror the value as a
//  Swift constant.
//

import Foundation

enum NativeDisplaySDKVersion {
    /// Semver name, kept in lockstep with `CleverTapNativeDisplay.podspec`
    /// `spec.version`. iOS version is owned independently of Android.
    static let name: String = "1.0.0"

    /// Monotonic integer derived as `major * 10000 + minor * 100 + patch`.
    /// For `1.0.0` this is `10000`. Bump whenever `name` changes.
    static let code: Int = 10_000
}
