plugins {
    alias(libs.plugins.android.library)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.dokka)
    id("maven-publish")
}

android {
    namespace = "com.clevertap.android.nativeui"
    compileSdk = 36

    defaultConfig {
        minSdk = 23
        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        consumerProguardFiles("consumer-rules.pro")
        
        aarMetadata {
            minCompileSdk = 23
        }
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }
    
    kotlinOptions {
        jvmTarget = "17"
        freeCompilerArgs += listOf(
            "-opt-in=kotlinx.serialization.ExperimentalSerializationApi"
        )
    }
    
    buildFeatures {
        compose = true
    }
    
    testOptions {
        unitTests.isReturnDefaultValues = true
    }

    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
    
    publishing {
        singleVariant("release") {
            withSourcesJar()
            withJavadocJar()
        }
    }
}

dependencies {
    // AndroidX
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    
    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.animation)
    implementation(libs.androidx.activity.compose)
    debugImplementation(libs.androidx.compose.ui.tooling)
    
    // Kotlin Serialization
    implementation(libs.kotlinx.serialization.json)

    // Immutable Collections
    implementation(libs.kotlinx.collections.immutable)
    
    // Coroutines
    implementation(libs.kotlinx.coroutines.core)
    implementation(libs.kotlinx.coroutines.android)
    
    // Image Loading
    implementation(libs.io.coil.compose)
    implementation(libs.io.coil.gif)  // GIF animation support

    // Video playback (optional - host apps must provide)
    compileOnly(libs.androidx.media3.exoplayer)
    compileOnly(libs.androidx.media3.ui)
    compileOnly(libs.androidx.media3.hls)

    // CleverTap Core SDK (optional - for bridge adapter)
    compileOnly("com.clevertap.android:clevertap-android-sdk:7.5.0")

    // Testing
    testImplementation(libs.junit)
    testImplementation(libs.kotlinx.coroutines.test)
    // Bridge tests reflect over NativeDisplayBridge whose `cleverTapApi` field
    // type is `CleverTapAPI`. `getDeclaredFields0` resolves all field types
    // during reflection, so the Core SDK class must be on the unit-test
    // classpath even though it is `compileOnly` for production.
    testImplementation("com.clevertap.android:clevertap-android-sdk:7.5.0")
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    // RecyclerView (for NativeDisplayViewGroup)
    api("androidx.recyclerview:recyclerview:1.3.2")
}

// Read version from root VERSION file
val versionFile = rootProject.file("../VERSION")
val libraryVersion = if (versionFile.exists()) {
    versionFile.readText().trim()
} else {
    "0.1.0"
}

// Dokka — generates HTML API reference for the public Kotlin surface.
// Output: android/sdk/build/dokka/html/. Consumed by the docs-site CI job
// which copies it into website/static/api/android/<version>/.
tasks.withType<org.jetbrains.dokka.gradle.DokkaTask>().configureEach {
    moduleName.set("clevertap-native-ui-kit")
    outputDirectory.set(layout.buildDirectory.dir("dokka/html"))

    dokkaSourceSets.configureEach {
        includes.from("dokka/module.md")
        jdkVersion.set(17)
        skipDeprecated.set(false)
        // sourceLink config can be added once we have a stable github URL —
        // skipped in v1.0.0 to keep the script free of FQN URL imports.
    }
}

afterEvaluate {
    publishing {
        publications {
            create<MavenPublication>("release") {
                from(components["release"])
                
                groupId = "com.clevertap.android"
                artifactId = "clevertap-native-ui-kit"
                version = libraryVersion
                
                pom {
                    name.set("CleverTap Native UI Kit")
                    description.set("Native UI rendering for in-app messages using Jetpack Compose")
                    url.set("https://github.com/CleverTap/clevertap-native-ui-kit")
                    
                    licenses {
                        license {
                            name.set("MIT License")
                            url.set("https://opensource.org/licenses/MIT")
                        }
                    }
                    
                    developers {
                        developer {
                            id.set("clevertap")
                            name.set("CleverTap")
                            email.set("support@clevertap.com")
                        }
                    }
                    
                    scm {
                        connection.set("scm:git:git://github.com/CleverTap/clevertap-native-ui-kit.git")
                        developerConnection.set("scm:git:ssh://git@github.com/CleverTap/clevertap-native-ui-kit.git")
                        url.set("https://github.com/CleverTap/clevertap-native-ui-kit")
                    }
                }
            }
        }
    }
}
