// Top-level build file
plugins {
    alias(libs.plugins.android.library) apply false
    alias(libs.plugins.kotlin.android) apply false
    alias(libs.plugins.kotlin.serialization) apply false
    alias(libs.plugins.binary.compatibility.validator)
}

// Track only the public API of the :sdk module. This locks the SDK's public
// surface: any change to public symbols must be reflected in sdk/api/sdk.api
// (run `./gradlew :sdk:apiDump` to update the baseline). The root project
// itself is ignored because it has no production code to track.
apiValidation {
    ignoredProjects.add(rootProject.name)
}

tasks.register("clean", Delete::class) {
    delete(rootProject.buildDir)
}
