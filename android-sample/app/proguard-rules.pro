# ============================================================================
# Sample app ProGuard / R8 rules
#
# This file ONLY contains app-level rules. The CleverTap Native Display SDK
# ships its own keep rules via its AAR (see android/sdk/consumer-rules.pro)
# and AGP merges those automatically — consumer apps don't need to repeat
# them here.
#
# The rules below cover the OTHER SDKs the sample integrates with:
#   - CleverTap Android Core SDK (com.clevertap.android.sdk.*)
#   - Firebase / FCM (push messaging)
# Per CleverTap's official integration docs.
# ============================================================================

# --- CleverTap Android Core SDK ---------------------------------------------
# Per https://developer.clevertap.com/docs/android — keep all Core SDK classes
# so reflective lookups (push-template renderers, in-app webview JS bridges,
# attribution payloads) resolve at runtime. The Core SDK itself ships these as
# consumer rules from 7.x+, but we declare them explicitly so this app's
# proguard pass is self-documenting.
-keep class com.clevertap.android.sdk.** { *; }
-keep interface com.clevertap.android.sdk.** { *; }
-dontwarn com.clevertap.android.sdk.**

# --- Firebase Cloud Messaging -----------------------------------------------
# FCM uses reflection for service discovery; FirebaseInstanceIdReceiver and
# FirebaseMessagingService must be kept along with their members.
-keep class com.google.firebase.messaging.** { *; }
-keep class com.google.firebase.iid.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.firebase.**
-dontwarn com.google.android.gms.**

# --- General safety ---------------------------------------------------------
# Keep generated Parcelable CREATOR fields (Android's Parcel reflection
# requires the static CREATOR; R8 usually handles this, but defensive rule).
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}

# Keep Serializable classes' uid + readObject/writeObject hooks (any consumer
# code passing data through Bundles or Intent extras).
-keepclassmembers class * implements java.io.Serializable {
    static final long serialVersionUID;
    private static final java.io.ObjectStreamField[] serialPersistentFields;
    private void writeObject(java.io.ObjectOutputStream);
    private void readObject(java.io.ObjectInputStream);
    java.lang.Object writeReplace();
    java.lang.Object readResolve();
}
