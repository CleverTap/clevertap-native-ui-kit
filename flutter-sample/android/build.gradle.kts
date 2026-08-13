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

// clevertap_plugin 4.1.0 declares CleverTap core SDK 8.3.0, but its bundled
// CleverTapListenerProxy implements listener interfaces that only exist in
// 8.4.x — so the plugin module fails to compile against 8.3.0 ("Unresolved
// reference: CleverTapListenerProxy"). Force a compatible core SDK across ALL
// modules (each plugin compiles against its own classpath, so an app-level
// force is not enough). Remove once the plugin corrects its declared floor.
subprojects {
    configurations.all {
        resolutionStrategy {
            force("com.clevertap.android:clevertap-android-sdk:8.4.1")
        }
    }
}

tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}
