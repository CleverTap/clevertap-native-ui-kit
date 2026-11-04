allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// clevertap_plugin 4.3.0's Android code calls ND methods that only exist in
// CleverTap core SDK 8.5.0 (e.g. pushDisplayUnitElementViewedEventForID,
// fetchNativeDisplayMeta). The plugin declares 8.5.0, but we force it across ALL
// modules so a stale/older transitive resolution can't downgrade it (each plugin
// compiles against its own classpath, so an app-level force is not enough).
// Must stay >= the version clevertap_plugin requires: 4.3.0 -> 8.5.0.
subprojects {
    configurations.all {
        resolutionStrategy {
            force("com.clevertap.android:clevertap-android-sdk:8.5.0")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
