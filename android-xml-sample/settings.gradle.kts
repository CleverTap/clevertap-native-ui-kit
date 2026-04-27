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

rootProject.name = "NativeDisplayXMLSample"
include(":app")

includeBuild("../android") {
    dependencySubstitution {
        // This maps the library coordinate to the local included project
        // Replace "com.clevertap.android:native-display" with the actual group:artifact of your SDK
        substitute(module("com.clevertap.android:native-display-sdk")).using(project(":sdk"))
    }
}

