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

# --- Core SDK reflection surface ---------------------------------------------
# The bridge looks up several CleverTap Core SDK methods by name (string-based
# reflection) because Core SDK is declared `compileOnly` and may be present at
# different major versions in different consumer apps. Core SDK's own
# `consumer-rules.pro` does NOT keep CleverTapAPI itself — only sub-packages
# (FCM, push templates, ExoPlayer integration). So without these rules, R8 in
# the consumer's app may strip the methods below, causing our reflective
# `getMethod(...)` to return null and silently degrading attribution to the
# legacy unit-level path that doesn't carry the element-level extras map.
#
# Keep the exact methods we reflect against. Listed individually (not a
# blanket `-keep class CleverTapAPI`) so consumer R8 still shrinks the rest
# of the Core SDK normally.
-keepclassmembers class com.clevertap.android.sdk.CleverTapAPI {
    public void pushDisplayUnitClickedEventForID(java.lang.String);
    public void pushDisplayUnitElementClickedEventForID(java.lang.String, java.util.HashMap);
    public void pushDisplayUnitViewedEventForID(java.lang.String);
    public void pushDisplayUnitViewedEventForID(java.lang.String, java.util.HashMap);
    public void setDisplayUnitCache(...);
    public int getDebugLevel();
    public static *** getDefaultInstance(android.content.Context);
    public void setDisplayUnitListener(...);
}

# CleverTapDisplayUnit — `toDisplayUnit(JSONObject)` static factory + instance
# accessors `getUnitID()` / `getJsonObject()` are reflected against by
# ReflectionSeeder and NativeDisplayUnitCacheImpl.
-keepclassmembers class com.clevertap.android.sdk.displayunits.model.CleverTapDisplayUnit {
    public static *** toDisplayUnit(org.json.JSONObject);
    public java.lang.String getUnitID();
    public org.json.JSONObject getJsonObject();
}

# DisplayUnitCache interface — bridge wires a dynamic Proxy that implements
# this interface; R8 must not rename/strip the interface methods or the
# Proxy.newProxyInstance handshake fails.
-keep interface com.clevertap.android.sdk.displayunits.DisplayUnitCache { *; }

# CTWebInterface — HTML element WebView JS bridge construct.
-keep class com.clevertap.android.sdk.CTWebInterface { *; }
