pluginManagement {
    repositories {
        google()
        mavenCentral()
        gradlePluginPortal()
    }
}

dependencyResolutionManagement {
    repositoriesMode.set(RepositoriesMode.FAIL_ON_PROJECT_REPOS)
    repositories {
        google()
        mavenCentral()
    }
}

rootProject.name = "NativeDisplayComposeSample"
include(":app")

// Include the SDK from parent android project
includeBuild("../android") {
    dependencySubstitution {
        substitute(module("com.clevertap.android:native-display-sdk")).using(project(":sdk"))
    }
}
