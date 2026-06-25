# ============================================================================
# CleverTap Native Display SDK — release variant ProGuard / R8 rules.
# Applied only to the SDK's OWN release variant when `isMinifyEnabled = true`
# (currently false). Consumer-facing rules live in consumer-rules.pro.
#
# Kept minimal because we don't currently shrink the SDK's own release build —
# the consumer's R8 pass is what produces the shipped bytecode. This file
# exists primarily to (a) silence the `proguardFiles(...)` AGP reference and
# (b) provide a starting point if we ever flip `isMinifyEnabled` to true.
# ============================================================================
