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
        // Maps the published Maven coordinate to the local included `:sdk` project so
        // the sample builds against working-tree SDK changes without needing a publish.
        substitute(module("com.clevertap.android:clevertap-native-display-sdk")).using(project(":sdk"))
    }
}

