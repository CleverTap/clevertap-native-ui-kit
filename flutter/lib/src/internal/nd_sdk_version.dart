/// ND SDK version stamp attached to every attribution payload so the server can
/// identify which ND SDK build produced the analytics.
///
/// Kept in sync with `version:` in `pubspec.yaml`. Mirrors Android's
/// `BuildConfig.ND_LIB_VERSION_NAME` / `ND_LIB_VERSION_CODE` and iOS's
/// `NativeDisplaySDKVersion`.
abstract final class NDSdkVersion {
  static const String name = '0.1.0';

  // Integer code derived from [name] (major*10000 + minor*100 + patch).
  static const int code = 100;
}
