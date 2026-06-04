plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.roborazzi)
}

android {
    namespace = "com.clevertap.android.nativeui.sample"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.clevertap.android.nativeui.sample"
        minSdk = 23
        targetSdk = 36
        versionCode = 8
        versionName = "1.7"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
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
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = "11"
    }

    buildFeatures {
        compose = true
        viewBinding = true
    }
    
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }

    testOptions {
        unitTests {
            isIncludeAndroidResources = true
        }
    }
}

// ── Campaign Screenshot Integration Test ─────────────────────────────────────
// Single task that runs the test AND pulls results to ~/Desktop before cleanup.
//
// Usage: cd android-sample && ./gradlew :app:campaignScreenshots
// ─────────────────────────────────────────────────────────────────────────────
val desktopPath = "${System.getProperty("user.home")}/Desktop/campaign-screenshots"

// Restrict connectedDebugAndroidTest to only CampaignScreenshotTest when this task is in the graph
gradle.taskGraph.whenReady {
    if (hasTask(":app:campaignScreenshots")) {
        android.defaultConfig.testInstrumentationRunnerArguments["class"] =
            "com.clevertap.android.nativeui.sample.CampaignScreenshotTest"
    }
}

tasks.register("campaignScreenshots") {
    group = "verification"
    description = "Run CampaignScreenshotTest and pull results to ~/Desktop/campaign-screenshots/"
    dependsOn("connectedDebugAndroidTest")
    doLast {
        // AGP pulls additionalTestOutputDir to build/outputs/connected_android_test_additional_output/
        // automatically. We just copy campaign-screenshots/ from there to the Desktop.
        val buildOutput = File(projectDir,
            "build/outputs/connected_android_test_additional_output")
        val campaignDir = buildOutput.walkTopDown()
            .firstOrNull { it.isDirectory && it.name == "campaign-screenshots" }

        if (campaignDir != null) {
            val dest = File(desktopPath)
            dest.mkdirs()
            campaignDir.copyRecursively(dest, overwrite = true)
            println("Screenshots copied to: $desktopPath")
        } else {
            println("Warning: campaign-screenshots not found in $buildOutput")
        }
    }
}

dependencies {
    // Local SDK
    implementation("com.clevertap.android:native-display-sdk")
    implementation("com.clevertap.android:clevertap-android-sdk:8.0.0")

    // AndroidX
    implementation(libs.androidx.core.ktx)
    implementation(libs.androidx.lifecycle.runtime.ktx)
    implementation(libs.androidx.lifecycle.viewmodel.compose)
    implementation(libs.androidx.activity.compose)
    
    // Compose
    implementation(platform(libs.androidx.compose.bom))
    implementation(libs.androidx.compose.ui)
    implementation(libs.androidx.compose.ui.graphics)
    implementation(libs.androidx.compose.ui.tooling.preview)
    implementation(libs.androidx.compose.material3)
    implementation(libs.androidx.compose.runtime)
    debugImplementation(libs.androidx.compose.ui.tooling)
    debugImplementation(libs.androidx.compose.ui.test.manifest)

    // Navigation
    implementation(libs.androidx.navigation.compose)

    // Video Playback (required for VIDEO elements)
    implementation(libs.androidx.media3.exoplayer)
    implementation(libs.androidx.media3.ui)
    implementation(libs.androidx.media3.hls)

    // Kotlin Serialization
    implementation(libs.kotlinx.serialization.json)
    
    // Testing
    testImplementation(libs.junit)
    androidTestImplementation(libs.androidx.test.ext.junit)
    androidTestImplementation(libs.androidx.test.espresso.core)
    androidTestImplementation(platform(libs.androidx.compose.bom))
    androidTestImplementation(libs.androidx.compose.ui.test.junit4)

    // Coil – runtime dep for sample app image loading (SDK uses implementation, not api)
    implementation(libs.io.coil.compose)
    testImplementation(libs.io.coil.compose)

    // Fragment + RecyclerView + AppCompat (for XML Feed tab)
    implementation(libs.androidx.fragment.ktx)
    implementation(libs.androidx.appcompat)
    implementation(libs.androidx.recyclerview)

    // Material + ConstraintLayout (for XML Feed layouts)
    implementation(libs.material)
    implementation(libs.androidx.constraintlayout)

    // Retrofit (for DummyJSON API in XML Feed)
    implementation(libs.retrofit)
    implementation(libs.retrofit.converter.gson)

    // Screenshot Testing
    testImplementation(libs.robolectric)
    testImplementation(libs.roborazzi.core)
    testImplementation(libs.roborazzi.junit)
    testImplementation(libs.roborazzi.compose)
    testImplementation(libs.androidx.compose.ui.test.junit4)
}
