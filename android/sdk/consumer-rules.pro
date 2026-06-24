# ============================================================================
# CleverTap Native Display SDK — consumer rules
# Bundled into the published AAR; auto-applied to every consumer's R8 / ProGuard
# / DexGuard pass via `consumerProguardFiles` in sdk/build.gradle.kts. Consumers
# do not need to copy anything into their own proguard-rules.pro.
#
# Strategy for 1.0.0: keep the entire SDK surface as-is. This trades a small
# amount of method-count overhead for zero risk of obfuscation breaking JSON
# deserialization (kotlinx-serialization), sealed-class polymorphism, public
# listener dispatch, or the reflective Core-SDK bridge.
#
# Future tightening: once we have a real-world consumer's release build under
# CI with a minified smoke test, we can replace this with surgical -keep rules
# scoped to just the serialization / reflection / public-API surface.
# ============================================================================

# Keep every class, field, and method in the SDK package tree (and any nested
# packages). `**` is recursive; the inner `{ *; }` keeps members too.
-keep class com.clevertap.android.nativedisplay.** { *; }
-keep interface com.clevertap.android.nativedisplay.** { *; }

# Keep generated BuildConfig (consumer apps occasionally reference
# ND_LIB_VERSION_NAME / ND_LIB_VERSION_CODE for analytics or feature gating).
-keep class com.clevertap.android.nativedisplay.BuildConfig { *; }

# kotlinx-serialization — even with keep-everything above, the generated
# synthetic $$serializer companions need explicit retention so R8 doesn't
# inline-and-drop them. Standard kotlinx-serialization consumer rules.
-keepclasseswithmembers class com.clevertap.android.nativedisplay.**$$serializer {
    *;
}
-keepclassmembers class com.clevertap.android.nativedisplay.** {
    *** Companion;
}
-keepclasseswithmembers class com.clevertap.android.nativedisplay.** {
    kotlinx.serialization.KSerializer serializer(...);
}

# Don't warn about classes referenced via `compileOnly` deps (media3, CleverTap
# Core SDK, AndroidX Fragment) that may legitimately be absent at consumer
# build time. R8 emits "missing class" warnings without these.
-dontwarn androidx.media3.**
-dontwarn com.clevertap.android.sdk.**
-dontwarn androidx.fragment.**
