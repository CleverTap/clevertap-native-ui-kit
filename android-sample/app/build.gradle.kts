plugins {
    alias(libs.plugins.android.application)
    alias(libs.plugins.kotlin.android)
    alias(libs.plugins.kotlin.serialization)
    alias(libs.plugins.compose.compiler)
    alias(libs.plugins.roborazzi)
    alias(libs.plugins.google.services)
}

android {
    namespace = "com.clevertap.android.nativeui.sample"
    compileSdk = 36

    defaultConfig {
        applicationId = "com.clevertap.android.nativeui.sample"
        minSdk = 23
        targetSdk = 36
        versionCode = 18
        versionName = "2.2"

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

// ── Automation Screenshots Integration Test ──────────────────────────────────
// Runs the events/slots screenshot automation suite and pulls all artifacts
// (PNGs + MP4 screen recordings) to ~/Desktop/nd-automation-output/android/.
//
// Tests included — exactly one test method per tab:
//   - EventsScreenshotsTest.composeEventsScreen_fireAllEvents — Compose Events
//     tab: drive the on-screen EditText + Send button through 22 events.
//   - EventsScreenshotsTest.xmlEventsScreen_fireAllEvents     — XML Events
//     tab (`XmlFeedFragment`): same loop via Espresso.
//   - SlotsScreenshotsTest.composeSlotsScreen_fetchAndScroll  — Compose Slots
//     tab: tap "Fetch Slot Data" then scroll top→bottom→top.
//   - SlotsScreenshotsTest.xmlSlotsScreen_fetchAndScroll      — XML Slots
//     tab (`XmlSlotsFragment`): same fetch-and-scroll on the RecyclerView.
//
// Usage: cd android-sample && ./gradlew :app:automationScreenshots
// ─────────────────────────────────────────────────────────────────────────────
val automationDesktopPath = "${System.getProperty("user.home")}/Desktop/nd-automation-output/android"

private val automationTestClasses = listOf(
    "com.clevertap.android.nativeui.sample.automation.EventsScreenshotsTest",
    "com.clevertap.android.nativeui.sample.automation.SlotsScreenshotsTest"
).joinToString(",")

// Restrict connectedDebugAndroidTest to just the automation suite when this task is in the graph.
gradle.taskGraph.whenReady {
    if (hasTask(":app:automationScreenshots")) {
        android.defaultConfig.testInstrumentationRunnerArguments["class"] = automationTestClasses
    }
}

tasks.register("automationScreenshots") {
    group = "verification"
    description = "Run the events/slots automation suite and pull PNGs + MP4s to ~/Desktop/nd-automation-output/android/"
    dependsOn("connectedDebugAndroidTest")
    doFirst {
        File(automationDesktopPath).mkdirs()
    }
    doLast {
        // AGP pulls additionalTestOutputDir to build/outputs/connected_android_test_additional_output/
        // automatically. Tests write PNGs and MP4s directly into that dir, so we copy
        // the contents (not the structure) to Desktop.
        val buildOutput = File(
            projectDir,
            "build/outputs/connected_android_test_additional_output"
        )
        if (!buildOutput.exists()) {
            println("Warning: $buildOutput does not exist — no artifacts produced")
            return@doLast
        }

        val dest = File(automationDesktopPath).apply { mkdirs() }
        val mediaFiles = buildOutput.walkTopDown()
            .filter { it.isFile && (it.extension == "png" || it.extension == "mp4") }
            .toList()

        // Preserve the relative path from AGP's output dir so identically-named
        // PNGs/MP4s from different test classes don't silently overwrite each
        // other on a flat copy.
        mediaFiles.forEach { src ->
            val target = File(dest, src.relativeTo(buildOutput).path)
            target.parentFile?.mkdirs()
            src.copyTo(target, overwrite = true)
        }
        println("Automation artifacts (${mediaFiles.size} files) copied to: $automationDesktopPath")
    }
}

dependencies {
    // Local SDK
    implementation("com.clevertap.android:native-display-sdk")
    implementation("com.clevertap.android:clevertap-android-sdk:8.3.0")

    // Firebase
    implementation(platform(libs.firebase.bom))
    implementation(libs.firebase.messaging)

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
