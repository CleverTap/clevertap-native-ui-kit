import org.gradle.api.tasks.JavaExec
import java.io.File

plugins {
    kotlin("jvm") version "1.9.23"
    application
}

group = "com.clevertap.tools"
version = "1.0.0"

repositories {
    mavenCentral()
}

dependencies {
    // No external dependencies — JVM stdlib only
    implementation(kotlin("stdlib"))
}

kotlin {
    jvmToolchain(17)
}

application {
    mainClass.set("com.clevertap.tools.CompareScreenshotsKt")
}

// ---------------------------------------------------------------------------
// compareScreenshots task
// ---------------------------------------------------------------------------
tasks.register<JavaExec>("compareScreenshots") {
    group = "verification"
    description = "Compare Android (Roborazzi) and iOS (XCUITest) screenshots and produce an HTML + JSON report."

    dependsOn(tasks.named("classes"))

    // Resolve directories — all relative to THIS build file (tools/compare-screenshots/)
    val projectDir = projectDir.absolutePath

    val iosDir = providers.gradleProperty("iosScreenshotDir")
        .orNull
        ?.let { File(it.replace("~", System.getProperty("user.home"))).absolutePath }
        ?: throw GradleException(
            "Required property 'iosScreenshotDir' is missing.\n" +
            "Usage: ./gradlew compareScreenshots -PiosScreenshotDir=<path>"
        )

    val androidDir = providers.gradleProperty("androidScreenshotDir")
        .orNull
        ?.let { File(it.replace("~", System.getProperty("user.home"))).absolutePath }
        ?: File(projectDir, "../../android-sample/app/build/outputs/roborazzi/configs").canonicalPath

    val outputDir = providers.gradleProperty("outputDir")
        .orNull
        ?.let { File(it.replace("~", System.getProperty("user.home"))).absolutePath }
        ?: File(projectDir, "../../comparison_report").canonicalPath

    classpath = sourceSets["main"].runtimeClasspath
    mainClass.set("com.clevertap.tools.CompareScreenshotsKt")

    args = listOf(iosDir, androidDir, outputDir)

    doFirst {
        println("=== Compare Screenshots ===")
        println("  iOS dir     : $iosDir")
        println("  Android dir : $androidDir")
        println("  Output dir  : $outputDir")
        println("===========================")
    }
}
